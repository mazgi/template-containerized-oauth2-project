import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomBytes, randomUUID } from 'crypto';
import * as bcrypt from 'bcryptjs';
import * as OTPAuth from 'otpauth';
import { I18nContext } from 'nestjs-i18n';
import { PrismaService } from '../prisma/prisma.service';
import { MailService } from '../mail/mail.service';
import { SignUpDto } from './dto/signup.dto';
import { SignInDto } from './dto/signin.dto';
import { AppleProfile } from './strategies/apple.strategy';
import { GoogleProfile } from './strategies/google.strategy';
import { TwitterProfile } from './strategies/twitter.strategy';
import { GithubProfile } from './strategies/github.strategy';
import { DiscordProfile } from './strategies/discord.strategy';

type UserRecord = {
  id: string;
  email: string;
  name: string | null;
  passwordHash: string | null;
  emailVerified: boolean;
  createdAt: Date;
  updatedAt: Date;
};

type SocialAccountRow = { providerId: string; email: string | null } | null;

type UserWithSocial = UserRecord & {
  socialApple: SocialAccountRow;
  socialGithub: SocialAccountRow;
  socialGoogle: SocialAccountRow;
  socialTwitter: SocialAccountRow;
  socialDiscord: SocialAccountRow;
};

const SOCIAL_INCLUDES = {
  socialApple: true,
  socialGithub: true,
  socialGoogle: true,
  socialTwitter: true,
  socialDiscord: true,
} as const;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly mailService: MailService,
  ) {}

  private t(key: string, args?: Record<string, unknown>): string {
    const i18n = I18nContext.current();
    return i18n ? i18n.t(key, { args }) : key;
  }

  async signUp(dto: SignUpDto) {
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (existing) {
      throw new ConflictException(this.t('auth.EMAIL_ALREADY_IN_USE'));
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const token = randomUUID();
    const expires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    await this.prisma.user.create({
      data: {
        email: dto.email,
        name: dto.name,
        passwordHash,
        emailVerified: false,
        emailVerificationToken: token,
        emailVerificationExpires: expires,
      },
    });

    await this.mailService.sendVerificationEmail(dto.email, token);

    return { message: this.t('auth.VERIFICATION_EMAIL_SENT') };
  }

  async verifyEmail(token: string) {
    const user = await this.prisma.user.findUnique({
      where: { emailVerificationToken: token },
    });

    if (!user) {
      throw new BadRequestException(this.t('auth.INVALID_VERIFICATION_TOKEN'));
    }

    if (user.emailVerificationExpires && user.emailVerificationExpires < new Date()) {
      throw new BadRequestException(this.t('auth.VERIFICATION_TOKEN_EXPIRED'));
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        emailVerified: true,
        emailVerificationToken: null,
        emailVerificationExpires: null,
      },
    });

    return { message: this.t('auth.EMAIL_VERIFIED') };
  }

  async resendVerification(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user || user.emailVerified) {
      // Return success even if user not found to prevent email enumeration
      return { message: this.t('auth.RESEND_VERIFICATION_SUCCESS') };
    }

    const token = randomUUID();
    const expires = new Date(Date.now() + 24 * 60 * 60 * 1000);

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        emailVerificationToken: token,
        emailVerificationExpires: expires,
      },
    });

    await this.mailService.sendVerificationEmail(email, token);

    return { message: 'If the email is registered and unverified, a verification email has been sent' };
  }

  async signIn(dto: SignInDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException(this.t('auth.INVALID_CREDENTIALS'));
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException(this.t('auth.INVALID_CREDENTIALS'));
    }

    if (!user.emailVerified) {
      throw new UnauthorizedException(this.t('auth.EMAIL_NOT_VERIFIED'));
    }

    if (user.totpEnabled) {
      const mfaToken = this.jwtService.sign(
        { sub: user.id, purpose: 'mfa' },
        {
          secret: process.env.AUTH_JWT_SECRET ?? 'change-me',
          expiresIn: '5m',
        },
      );
      return { requiresMfa: true as const, mfaToken };
    }

    return this.buildTokenResponse(user);
  }

  async refresh(refreshToken: string) {
    let payload: { sub: string; email: string };
    try {
      payload = this.jwtService.verify(refreshToken, {
        secret: process.env.AUTH_JWT_REFRESH_SECRET ?? 'change-me-refresh',
      });
    } catch {
      throw new UnauthorizedException(this.t('auth.INVALID_REFRESH_TOKEN'));
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });
    if (!user) {
      throw new UnauthorizedException(this.t('auth.INVALID_REFRESH_TOKEN'));
    }

    return this.buildTokenResponse(user);
  }

  async findOrCreateAppleUser(profile: AppleProfile) {
    // 1. Look up by providerId (most stable identifier)
    const social = await this.prisma.socialAccountApple.findUnique({
      where: { providerId: profile.appleId },
      include: { user: true },
    });
    if (social) {
      return this.buildTokenResponse(social.user);
    }

    // 2. Fall back to email lookup, and link to existing account
    if (profile.email) {
      const existingUser = await this.prisma.user.findUnique({
        where: { email: profile.email },
      });
      if (existingUser) {
        await this.prisma.socialAccountApple.create({
          data: { providerId: profile.appleId, email: profile.email, userId: existingUser.id },
        });
        return this.buildTokenResponse(existingUser);
      }
    }

    // 3. Create new user with linked social account
    const email = profile.email ?? `apple_${profile.appleId}@apple.invalid`;
    const user = await this.prisma.user.create({
      data: {
        email,
        name: profile.name,
        passwordHash: null,
        emailVerified: !email.endsWith('.invalid'),
        socialApple: { create: { providerId: profile.appleId, email: profile.email } },
      },
    });

    return this.buildTokenResponse(user);
  }

  async findOrCreateGoogleUser(profile: GoogleProfile) {
    // 1. Look up by providerId (most stable identifier)
    const social = await this.prisma.socialAccountGoogle.findUnique({
      where: { providerId: profile.googleId },
      include: { user: true },
    });
    if (social) {
      return this.buildTokenResponse(social.user);
    }

    // 2. Fall back to email lookup, and link to existing account
    if (profile.email) {
      const existingUser = await this.prisma.user.findUnique({
        where: { email: profile.email },
      });
      if (existingUser) {
        await this.prisma.socialAccountGoogle.create({
          data: { providerId: profile.googleId, email: profile.email, userId: existingUser.id },
        });
        return this.buildTokenResponse(existingUser);
      }
    }

    // 3. Create new user with linked social account
    const user = await this.prisma.user.create({
      data: {
        email: profile.email,
        name: profile.name,
        passwordHash: null,
        emailVerified: true,
        socialGoogle: { create: { providerId: profile.googleId, email: profile.email } },
      },
    });

    return this.buildTokenResponse(user);
  }

  async findOrCreateTwitterUser(profile: TwitterProfile) {
    // 1. Look up by providerId (most stable identifier)
    const social = await this.prisma.socialAccountTwitter.findUnique({
      where: { providerId: profile.twitterId },
      include: { user: true },
    });
    if (social) {
      return this.buildTokenResponse(social.user);
    }

    // 2. Fall back to email lookup, and link to existing account
    if (profile.email) {
      const existingUser = await this.prisma.user.findUnique({
        where: { email: profile.email },
      });
      if (existingUser) {
        await this.prisma.socialAccountTwitter.create({
          data: { providerId: profile.twitterId, email: profile.email, userId: existingUser.id },
        });
        return this.buildTokenResponse(existingUser);
      }
    }

    // 3. Create new user with linked social account
    const email = profile.email ?? `twitter_${profile.twitterId}@x.invalid`;
    const user = await this.prisma.user.create({
      data: {
        email,
        name: profile.name,
        passwordHash: null,
        emailVerified: !email.endsWith('.invalid'),
        socialTwitter: { create: { providerId: profile.twitterId, email: profile.email } },
      },
    });

    return this.buildTokenResponse(user);
  }

  async findOrCreateDiscordUser(profile: DiscordProfile) {
    // 1. Look up by providerId (most stable identifier)
    const social = await this.prisma.socialAccountDiscord.findUnique({
      where: { providerId: profile.discordId },
      include: { user: true },
    });
    if (social) {
      return this.buildTokenResponse(social.user);
    }

    // 2. Fall back to email lookup, and link to existing account
    if (profile.email) {
      const existingUser = await this.prisma.user.findUnique({
        where: { email: profile.email },
      });
      if (existingUser) {
        await this.prisma.socialAccountDiscord.create({
          data: { providerId: profile.discordId, email: profile.email, userId: existingUser.id },
        });
        return this.buildTokenResponse(existingUser);
      }
    }

    // 3. Create new user with linked social account
    const email = profile.email ?? `discord_${profile.discordId}@discord.invalid`;
    const user = await this.prisma.user.create({
      data: {
        email,
        name: profile.name,
        passwordHash: null,
        emailVerified: !email.endsWith('.invalid'),
        socialDiscord: { create: { providerId: profile.discordId, email: profile.email } },
      },
    });

    return this.buildTokenResponse(user);
  }

  async findOrCreateGithubUser(profile: GithubProfile) {
    // 1. Look up by providerId (most stable identifier)
    const social = await this.prisma.socialAccountGithub.findUnique({
      where: { providerId: profile.githubId },
      include: { user: true },
    });
    if (social) {
      return this.buildTokenResponse(social.user);
    }

    // 2. Fall back to email lookup, and link to existing account
    if (profile.email) {
      const existingUser = await this.prisma.user.findUnique({
        where: { email: profile.email },
      });
      if (existingUser) {
        await this.prisma.socialAccountGithub.create({
          data: { providerId: profile.githubId, email: profile.email, userId: existingUser.id },
        });
        return this.buildTokenResponse(existingUser);
      }
    }

    // 3. Create new user with linked social account
    const email = profile.email ?? `github_${profile.githubId}@github.invalid`;
    const user = await this.prisma.user.create({
      data: {
        email,
        name: profile.name,
        passwordHash: null,
        emailVerified: !email.endsWith('.invalid'),
        socialGithub: { create: { providerId: profile.githubId, email: profile.email } },
      },
    });

    return this.buildTokenResponse(user);
  }

  async verifyAppleToken(
    identityToken: string,
    fullName?: { givenName?: string; familyName?: string },
  ) {
    // Decode the Apple identity token JWT (without signature verification for stub)
    const decoded = this.jwtService.decode(identityToken) as {
      sub?: string;
      email?: string;
    } | null;

    if (!decoded?.sub) {
      throw new UnauthorizedException(this.t('auth.INVALID_APPLE_TOKEN'));
    }

    const name = [fullName?.givenName, fullName?.familyName]
      .filter(Boolean)
      .join(' ')
      .trim() || null;

    const profile: AppleProfile = {
      appleId: decoded.sub,
      email: decoded.email ?? null,
      name,
    };

    return this.findOrCreateAppleUser(profile);
  }

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: SOCIAL_INCLUDES,
    });
    if (!user) {
      throw new UnauthorizedException();
    }
    const { passwordHash, emailVerificationToken, emailVerificationExpires, totpSecret, recoveryCodes, socialApple, socialGithub, socialGoogle, socialTwitter, socialDiscord, ...result } = user;
    return {
      ...result,
      ...this.socialToFlat(user),
      hasPassword: passwordHash != null,
    };
  }

  async updateEmail(userId: string, newEmail: string) {
    const existing = await this.prisma.user.findUnique({
      where: { email: newEmail },
    });
    if (existing && existing.id !== userId) {
      throw new ConflictException(this.t('auth.EMAIL_ALREADY_IN_USE'));
    }

    const token = randomUUID();
    const expires = new Date(Date.now() + 24 * 60 * 60 * 1000);

    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        email: newEmail,
        emailVerified: false,
        emailVerificationToken: token,
        emailVerificationExpires: expires,
      },
      include: SOCIAL_INCLUDES,
    });

    await this.mailService.sendVerificationEmail(newEmail, token);

    const { passwordHash, emailVerificationToken, emailVerificationExpires, totpSecret: _ts, recoveryCodes: _rc, socialApple, socialGithub, socialGoogle, socialTwitter, socialDiscord, ...result } = user;
    return {
      ...result,
      ...this.socialToFlat(user),
      hasPassword: passwordHash != null,
    };
  }

  async forgotPassword(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user || !user.emailVerified) {
      // Return success even if user not found to prevent email enumeration
      return { message: this.t('auth.FORGOT_PASSWORD_SUCCESS') };
    }

    const token = randomUUID();
    const expires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordResetToken: token,
        passwordResetExpires: expires,
      },
    });

    await this.mailService.sendPasswordResetEmail(email, token);

    return { message: 'If the email is registered and verified, a password reset email has been sent' };
  }

  async resetPassword(token: string, newPassword: string) {
    const user = await this.prisma.user.findUnique({
      where: { passwordResetToken: token },
    });

    if (!user) {
      throw new BadRequestException(this.t('auth.INVALID_PASSWORD_RESET_TOKEN'));
    }

    if (user.passwordResetExpires && user.passwordResetExpires < new Date()) {
      throw new BadRequestException(this.t('auth.PASSWORD_RESET_TOKEN_EXPIRED'));
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash,
        passwordResetToken: null,
        passwordResetExpires: null,
      },
    });

    return { message: this.t('auth.PASSWORD_RESET_SUCCESS') };
  }

  // --- Account linking ---

  async linkApple(userId: string, profile: AppleProfile) {
    const existing = await this.prisma.socialAccountApple.findUnique({
      where: { providerId: profile.appleId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException(this.t('auth.APPLE_ALREADY_LINKED'));
    }
    await this.prisma.socialAccountApple.upsert({
      where: { userId },
      create: { providerId: profile.appleId, email: profile.email, userId },
      update: { providerId: profile.appleId, email: profile.email },
    });
  }

  async linkGithub(userId: string, profile: GithubProfile) {
    const existing = await this.prisma.socialAccountGithub.findUnique({
      where: { providerId: profile.githubId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException(this.t('auth.GITHUB_ALREADY_LINKED'));
    }
    await this.prisma.socialAccountGithub.upsert({
      where: { userId },
      create: { providerId: profile.githubId, email: profile.email, userId },
      update: { providerId: profile.githubId, email: profile.email },
    });
  }

  async linkGoogle(userId: string, profile: GoogleProfile) {
    const existing = await this.prisma.socialAccountGoogle.findUnique({
      where: { providerId: profile.googleId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException(this.t('auth.GOOGLE_ALREADY_LINKED'));
    }
    await this.prisma.socialAccountGoogle.upsert({
      where: { userId },
      create: { providerId: profile.googleId, email: profile.email, userId },
      update: { providerId: profile.googleId, email: profile.email },
    });
  }

  async linkDiscord(userId: string, profile: DiscordProfile) {
    const existing = await this.prisma.socialAccountDiscord.findUnique({
      where: { providerId: profile.discordId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException(this.t('auth.DISCORD_ALREADY_LINKED'));
    }
    await this.prisma.socialAccountDiscord.upsert({
      where: { userId },
      create: { providerId: profile.discordId, email: profile.email, userId },
      update: { providerId: profile.discordId, email: profile.email },
    });
  }

  async linkTwitter(userId: string, profile: TwitterProfile) {
    const existing = await this.prisma.socialAccountTwitter.findUnique({
      where: { providerId: profile.twitterId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException(this.t('auth.X_ALREADY_LINKED'));
    }
    await this.prisma.socialAccountTwitter.upsert({
      where: { userId },
      create: { providerId: profile.twitterId, email: profile.email, userId },
      update: { providerId: profile.twitterId, email: profile.email },
    });
  }

  // --- Account deletion ---

  async deleteAccount(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new UnauthorizedException();
    }
    await this.prisma.user.delete({ where: { id: userId } });
  }

  // --- Account unlinking ---

  async unlinkApple(userId: string) {
    await this.ensureAlternativeAuthExists(userId, 'apple');
    await this.prisma.socialAccountApple.deleteMany({ where: { userId } });
  }

  async unlinkGithub(userId: string) {
    await this.ensureAlternativeAuthExists(userId, 'github');
    await this.prisma.socialAccountGithub.deleteMany({ where: { userId } });
  }

  async unlinkGoogle(userId: string) {
    await this.ensureAlternativeAuthExists(userId, 'google');
    await this.prisma.socialAccountGoogle.deleteMany({ where: { userId } });
  }

  async unlinkTwitter(userId: string) {
    await this.ensureAlternativeAuthExists(userId, 'twitter');
    await this.prisma.socialAccountTwitter.deleteMany({ where: { userId } });
  }

  async unlinkDiscord(userId: string) {
    await this.ensureAlternativeAuthExists(userId, 'discord');
    await this.prisma.socialAccountDiscord.deleteMany({ where: { userId } });
  }

  private async ensureAlternativeAuthExists(userId: string, excludeProvider: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: SOCIAL_INCLUDES,
    });
    if (!user) throw new UnauthorizedException();
    const authMethods = [
      user.passwordHash != null,
      excludeProvider !== 'apple' && user.socialApple != null,
      excludeProvider !== 'github' && user.socialGithub != null,
      excludeProvider !== 'google' && user.socialGoogle != null,
      excludeProvider !== 'twitter' && user.socialTwitter != null,
      excludeProvider !== 'discord' && user.socialDiscord != null,
    ];
    if (!authMethods.some(Boolean)) {
      throw new ConflictException(this.t('auth.CANNOT_UNLINK_ONLY_AUTH'));
    }
  }

  private socialToFlat(user: UserWithSocial) {
    const socialEmails: string[] = [];
    const seen = new Set<string>();
    for (const acct of [user.socialApple, user.socialGithub, user.socialGoogle, user.socialTwitter, user.socialDiscord]) {
      if (acct?.email && !acct.email.endsWith('.invalid') && !seen.has(acct.email)) {
        seen.add(acct.email);
        socialEmails.push(acct.email);
      }
    }
    return {
      appleId: user.socialApple?.providerId ?? null,
      githubId: user.socialGithub?.providerId ?? null,
      googleId: user.socialGoogle?.providerId ?? null,
      twitterId: user.socialTwitter?.providerId ?? null,
      discordId: user.socialDiscord?.providerId ?? null,
      socialEmails,
    };
  }

  private async buildTokenResponse(user: UserRecord) {
    const payload = { sub: user.id, email: user.email };

    // expiresIn is typed as StringValue | number in @types/jsonwebtoken,
    // but env vars are plain string. Cast via unknown to satisfy the type.
    const accessToken = this.jwtService.sign(payload, {
      secret: process.env.AUTH_JWT_SECRET ?? 'change-me',
      expiresIn: (process.env.AUTH_JWT_ACCESS_EXPIRATION ?? '15m') as unknown as number,
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: process.env.AUTH_JWT_REFRESH_SECRET ?? 'change-me-refresh',
      expiresIn: (process.env.AUTH_JWT_REFRESH_EXPIRATION ?? '7d') as unknown as number,
    });

    // Query social accounts for flat response
    const userWithSocial = await this.prisma.user.findUnique({
      where: { id: user.id },
      include: SOCIAL_INCLUDES,
    });

    const { passwordHash: _pw, emailVerificationToken: _evt, emailVerificationExpires: _eve, passwordResetToken: _prt, passwordResetExpires: _pre, totpSecret: _ts, recoveryCodes: _rc, socialApple, socialGithub, socialGoogle, socialTwitter, socialDiscord, ...userWithoutPassword } = userWithSocial!;

    return {
      accessToken,
      refreshToken,
      user: {
        ...userWithoutPassword,
        ...this.socialToFlat(userWithSocial as UserWithSocial),
      },
    };
  }

  // --- TOTP MFA ---

  async totpSetup(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException();
    if (user.totpEnabled) throw new ConflictException(this.t('auth.TOTP_ALREADY_ENABLED'));

    const secret = new OTPAuth.Secret({ size: 20 });
    const totp = new OTPAuth.TOTP({
      issuer: process.env.APP_NAME ?? 'OAuth2App',
      label: user.email,
      algorithm: 'SHA1',
      digits: 6,
      period: 30,
      secret,
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: { totpSecret: secret.base32 },
    });

    return {
      secret: secret.base32,
      uri: totp.toString(),
    };
  }

  async totpEnable(userId: string, code: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.totpSecret) throw new BadRequestException(this.t('auth.TOTP_NOT_SET_UP'));
    if (user.totpEnabled) throw new ConflictException(this.t('auth.TOTP_ALREADY_ENABLED'));

    const totp = new OTPAuth.TOTP({
      secret: OTPAuth.Secret.fromBase32(user.totpSecret),
      algorithm: 'SHA1',
      digits: 6,
      period: 30,
    });

    const delta = totp.validate({ token: code, window: 1 });
    if (delta === null) throw new BadRequestException(this.t('auth.INVALID_TOTP_CODE'));

    const recoveryCodes = Array.from({ length: 8 }, () =>
      randomBytes(4).toString('hex'),
    );
    const hashedCodes = await Promise.all(
      recoveryCodes.map((c) => bcrypt.hash(c, 10)),
    );

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        totpEnabled: true,
        recoveryCodes: hashedCodes,
      },
    });

    return { recoveryCodes };
  }

  async totpDisable(userId: string, code: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.totpEnabled || !user.totpSecret)
      throw new BadRequestException(this.t('auth.TOTP_NOT_ENABLED'));

    const totp = new OTPAuth.TOTP({
      secret: OTPAuth.Secret.fromBase32(user.totpSecret),
      algorithm: 'SHA1',
      digits: 6,
      period: 30,
    });
    const delta = totp.validate({ token: code, window: 1 });
    if (delta === null) throw new BadRequestException(this.t('auth.INVALID_TOTP_CODE'));

    await this.prisma.user.update({
      where: { id: userId },
      data: { totpEnabled: false, totpSecret: null, recoveryCodes: null },
    });

    return { message: this.t('auth.TOTP_DISABLED') };
  }

  async totpVerify(mfaToken: string, code: string) {
    let payload: { sub: string; purpose: string };
    try {
      payload = this.jwtService.verify(mfaToken, {
        secret: process.env.AUTH_JWT_SECRET ?? 'change-me',
      });
    } catch {
      throw new UnauthorizedException(this.t('auth.INVALID_EXPIRED_MFA_TOKEN'));
    }
    if (payload.purpose !== 'mfa') {
      throw new UnauthorizedException(this.t('auth.INVALID_MFA_TOKEN'));
    }

    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user || !user.totpEnabled || !user.totpSecret) {
      throw new UnauthorizedException(this.t('auth.INVALID_MFA_TOKEN'));
    }

    // Try TOTP code first
    const totp = new OTPAuth.TOTP({
      secret: OTPAuth.Secret.fromBase32(user.totpSecret),
      algorithm: 'SHA1',
      digits: 6,
      period: 30,
    });
    const delta = totp.validate({ token: code, window: 1 });

    if (delta !== null) {
      return this.buildTokenResponse(user);
    }

    // Try recovery code
    if (user.recoveryCodes && Array.isArray(user.recoveryCodes)) {
      const hashes = user.recoveryCodes as string[];
      for (let i = 0; i < hashes.length; i++) {
        if (await bcrypt.compare(code, hashes[i])) {
          const remaining = [...hashes];
          remaining.splice(i, 1);
          await this.prisma.user.update({
            where: { id: user.id },
            data: { recoveryCodes: remaining },
          });
          return this.buildTokenResponse(user);
        }
      }
    }

    throw new UnauthorizedException(this.t('auth.INVALID_TOTP_OR_RECOVERY'));
  }

  async totpRegenerateRecoveryCodes(userId: string, code: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.totpEnabled || !user.totpSecret)
      throw new BadRequestException(this.t('auth.TOTP_NOT_ENABLED'));

    const totp = new OTPAuth.TOTP({
      secret: OTPAuth.Secret.fromBase32(user.totpSecret),
      algorithm: 'SHA1',
      digits: 6,
      period: 30,
    });
    const delta = totp.validate({ token: code, window: 1 });
    if (delta === null) throw new BadRequestException(this.t('auth.INVALID_TOTP_CODE'));

    const recoveryCodes = Array.from({ length: 8 }, () =>
      randomBytes(4).toString('hex'),
    );
    const hashedCodes = await Promise.all(
      recoveryCodes.map((c) => bcrypt.hash(c, 10)),
    );

    await this.prisma.user.update({
      where: { id: userId },
      data: { recoveryCodes: hashedCodes },
    });

    return { recoveryCodes };
  }
}

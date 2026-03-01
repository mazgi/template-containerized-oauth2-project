import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
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
  createdAt: Date;
  updatedAt: Date;
};

type SocialAccountRow = { providerId: string } | null;

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
  ) {}

  async signUp(dto: SignUpDto) {
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (existing) {
      throw new ConflictException('Email already in use');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: { email: dto.email, name: dto.name, passwordHash },
    });

    return this.buildTokenResponse(user);
  }

  async signIn(dto: SignInDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid credentials');
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
      throw new UnauthorizedException('Invalid refresh token');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });
    if (!user) {
      throw new UnauthorizedException('Invalid refresh token');
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
          data: { providerId: profile.appleId, userId: existingUser.id },
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
        socialApple: { create: { providerId: profile.appleId } },
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
          data: { providerId: profile.googleId, userId: existingUser.id },
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
        socialGoogle: { create: { providerId: profile.googleId } },
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
          data: { providerId: profile.twitterId, userId: existingUser.id },
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
        socialTwitter: { create: { providerId: profile.twitterId } },
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
          data: { providerId: profile.discordId, userId: existingUser.id },
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
        socialDiscord: { create: { providerId: profile.discordId } },
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
          data: { providerId: profile.githubId, userId: existingUser.id },
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
        socialGithub: { create: { providerId: profile.githubId } },
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
      throw new UnauthorizedException('Invalid Apple identity token');
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
    const { passwordHash, socialApple, socialGithub, socialGoogle, socialTwitter, socialDiscord, ...result } = user;
    return {
      ...result,
      ...this.socialToFlat(user),
      hasPassword: passwordHash != null,
    };
  }

  // --- Account linking ---

  async linkApple(userId: string, profile: AppleProfile) {
    const existing = await this.prisma.socialAccountApple.findUnique({
      where: { providerId: profile.appleId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException('This Apple account is already linked to another user');
    }
    await this.prisma.socialAccountApple.upsert({
      where: { userId },
      create: { providerId: profile.appleId, userId },
      update: { providerId: profile.appleId },
    });
  }

  async linkGithub(userId: string, profile: GithubProfile) {
    const existing = await this.prisma.socialAccountGithub.findUnique({
      where: { providerId: profile.githubId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException('This GitHub account is already linked to another user');
    }
    await this.prisma.socialAccountGithub.upsert({
      where: { userId },
      create: { providerId: profile.githubId, userId },
      update: { providerId: profile.githubId },
    });
  }

  async linkGoogle(userId: string, profile: GoogleProfile) {
    const existing = await this.prisma.socialAccountGoogle.findUnique({
      where: { providerId: profile.googleId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException('This Google account is already linked to another user');
    }
    await this.prisma.socialAccountGoogle.upsert({
      where: { userId },
      create: { providerId: profile.googleId, userId },
      update: { providerId: profile.googleId },
    });
  }

  async linkDiscord(userId: string, profile: DiscordProfile) {
    const existing = await this.prisma.socialAccountDiscord.findUnique({
      where: { providerId: profile.discordId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException('This Discord account is already linked to another user');
    }
    await this.prisma.socialAccountDiscord.upsert({
      where: { userId },
      create: { providerId: profile.discordId, userId },
      update: { providerId: profile.discordId },
    });
  }

  async linkTwitter(userId: string, profile: TwitterProfile) {
    const existing = await this.prisma.socialAccountTwitter.findUnique({
      where: { providerId: profile.twitterId },
    });
    if (existing && existing.userId !== userId) {
      throw new ConflictException('This X account is already linked to another user');
    }
    await this.prisma.socialAccountTwitter.upsert({
      where: { userId },
      create: { providerId: profile.twitterId, userId },
      update: { providerId: profile.twitterId },
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
      throw new ConflictException('Cannot unlink: this is your only authentication method');
    }
  }

  private socialToFlat(user: UserWithSocial) {
    return {
      appleId: user.socialApple?.providerId ?? null,
      githubId: user.socialGithub?.providerId ?? null,
      googleId: user.socialGoogle?.providerId ?? null,
      twitterId: user.socialTwitter?.providerId ?? null,
      discordId: user.socialDiscord?.providerId ?? null,
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

    const { passwordHash: _pw, socialApple, socialGithub, socialGoogle, socialTwitter, socialDiscord, ...userWithoutPassword } = userWithSocial!;

    return {
      accessToken,
      refreshToken,
      user: {
        ...userWithoutPassword,
        ...this.socialToFlat(userWithSocial as UserWithSocial),
      },
    };
  }
}

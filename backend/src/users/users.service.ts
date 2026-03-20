import { Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { I18nContext } from 'nestjs-i18n';
import { Prisma } from '../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

export type UserRecord = {
  id: string;
  email: string;
  name: string | null;
  passwordHash: string | null;
  emailVerified: boolean;
  createdAt: Date;
  updatedAt: Date;
};

type SocialAccountRow = { providerId: string; email: string | null } | null;

export type UserWithSocial = UserRecord & {
  socialApple: SocialAccountRow;
  socialGithub: SocialAccountRow;
  socialGoogle: SocialAccountRow;
  socialTwitter: SocialAccountRow;
  socialDiscord: SocialAccountRow;
};

export const SOCIAL_INCLUDES = {
  socialApple: true,
  socialGithub: true,
  socialGoogle: true,
  socialTwitter: true,
  socialDiscord: true,
} as const;

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  private t(key: string, args?: Record<string, unknown>): string {
    const i18n = I18nContext.current();
    return i18n ? i18n.t(key, { args }) : key;
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

  socialToFlat(user: UserWithSocial) {
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

  async create(createUserDto: CreateUserDto) {
    return this.prisma.user.create({ data: createUserDto });
  }

  async findAll() {
    return this.prisma.user.findMany();
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundException(this.t('users.USER_NOT_FOUND', { id }));
    }
    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    await this.findOne(id);
    return this.prisma.user.update({ where: { id }, data: updateUserDto });
  }

  async updatePreferences(id: string, preferences: Record<string, unknown>) {
    const user = await this.findOne(id);
    const current = (user.preferences ?? {}) as Record<string, unknown>;
    const merged = { ...current, ...preferences } as Prisma.InputJsonValue;
    return this.prisma.user.update({ where: { id }, data: { preferences: merged } });
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.prisma.user.delete({ where: { id } });
  }
}

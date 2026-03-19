import { Injectable, NotFoundException } from '@nestjs/common';
import { I18nContext } from 'nestjs-i18n';
import { Prisma } from '../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  private t(key: string, args?: Record<string, unknown>): string {
    const i18n = I18nContext.current();
    return i18n ? i18n.t(key, { args }) : key;
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

import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '../generated/prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

@Injectable()
export class PrismaService implements OnModuleInit, OnModuleDestroy {
  private readonly client: PrismaClient;

  get user() {
    return this.client.user;
  }

  get item() {
    return this.client.item;
  }

  get socialAccountApple() {
    return this.client.socialAccountApple;
  }

  get socialAccountGithub() {
    return this.client.socialAccountGithub;
  }

  get socialAccountGoogle() {
    return this.client.socialAccountGoogle;
  }

  get socialAccountTwitter() {
    return this.client.socialAccountTwitter;
  }

  get socialAccountDiscord() {
    return this.client.socialAccountDiscord;
  }

  constructor() {
    this.client = new PrismaClient({
      adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }),
    });
  }

  async onModuleInit() {
    await this.client.$connect();
  }

  async onModuleDestroy() {
    await this.client.$disconnect();
  }
}

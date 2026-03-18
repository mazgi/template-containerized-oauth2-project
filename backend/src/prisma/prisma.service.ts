import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '../generated/prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

@Injectable()
export class PrismaService implements OnModuleInit, OnModuleDestroy {
  private readonly pool: Pool;
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
    this.pool = new Pool({ connectionString: process.env.DATABASE_URL });
    this.client = new PrismaClient({
      // Cast needed: @prisma/adapter-pg pins @types/pg@8.11.11 while
      // the project uses a newer version; the runtime Pool is identical.
      adapter: new PrismaPg(this.pool as any),
    });
  }

  getPool(): Pool {
    return this.pool;
  }

  async onModuleInit() {
    await this.client.$connect();
  }

  async onModuleDestroy() {
    await this.client.$disconnect();
    await this.pool.end();
  }
}

import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';

let emailCounter = 0;

export function uniqueEmail(prefix = 'e2e'): string {
  return `${prefix}_${Date.now()}_${++emailCounter}@test.example`;
}

export async function signUpUser(
  app: INestApplication,
  overrides: { email?: string; password?: string; name?: string } = {},
) {
  const email = overrides.email ?? uniqueEmail();
  const password = overrides.password ?? 'TestPass123';
  const name = overrides.name;

  const res = await request(app.getHttpServer())
    .post('/auth/signup')
    .send({ email, password, name })
    .expect(201);

  return {
    ...res.body,
    email,
    password,
  };
}

export async function signInUser(
  app: INestApplication,
  email: string,
  password: string,
) {
  const res = await request(app.getHttpServer())
    .post('/auth/signin')
    .send({ email, password })
    .expect(201);

  return res.body;
}

export async function cleanDatabase(prisma: PrismaService) {
  // Delete in dependency order (children before parents)
  await prisma.item.deleteMany();
  await prisma.socialAccountApple.deleteMany();
  await prisma.socialAccountGithub.deleteMany();
  await prisma.socialAccountGoogle.deleteMany();
  await prisma.socialAccountTwitter.deleteMany();
  await prisma.user.deleteMany();
}

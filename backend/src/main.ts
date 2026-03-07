import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import * as session from 'express-session';
import * as connectPgSimple from 'connect-pg-simple';
import { Pool } from 'pg';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Trust the reverse proxy (Cloud Run, ALB, etc.) so req.protocol
  // reflects the client's HTTPS connection and secure cookies work.
  const expressApp = app.getHttpAdapter().getInstance();
  expressApp.set('trust proxy', 1);

  const rawOrigin = process.env.CORS_ORIGIN ?? 'http://localhost:3000';
  const corsOrigin = rawOrigin.includes(',') ? rawOrigin.split(',') : rawOrigin;

  const sessionConfig: session.SessionOptions = {
    secret: process.env.AUTH_SESSION_SECRET ?? 'change-me-session',
    resave: false,
    saveUninitialized: false,
  };

  if (process.env.DATABASE_URL) {
    const PgStore = connectPgSimple(session);
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    sessionConfig.store = new PgStore({
      pool,
      createTableIfMissing: true,
    });
  }

  app.use(session(sessionConfig));

  app.enableCors({
    origin: corsOrigin,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
    }),
  );

  const config = new DocumentBuilder()
    .setTitle('Stub Backend API')
    .setDescription('OAuth2 stub backend REST API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  const port = process.env.PORT ?? 4000;
  await app.listen(port);
  console.log(`Application is running on: http://localhost:${port}`);
  console.log(`Swagger UI: http://localhost:${port}/api`);
}
bootstrap();

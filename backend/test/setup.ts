// Set environment variables BEFORE any NestJS module imports.
// These must be set before the PrismaService constructor runs and
// before Passport strategies read their config from process.env.
process.env.DATABASE_URL =
  process.env.DATABASE_URL ??
  'postgresql://postgres:password@localhost:5432/localauth';
process.env.JWT_SECRET = 'test-jwt-secret';
process.env.JWT_REFRESH_SECRET = 'test-jwt-refresh-secret';
process.env.JWT_ACCESS_EXPIRATION = '15m';
process.env.JWT_REFRESH_EXPIRATION = '7d';
process.env.SESSION_SECRET = 'test-session-secret';
process.env.FRONTEND_URL = 'http://localhost:3000';
process.env.NATIVE_APP_URL_SCHEME = 'oauth2app';

// Dummy values for OAuth strategies so their constructors don't throw
// during NestJS module initialization.
process.env.APPLE_CLIENT_ID = process.env.APPLE_CLIENT_ID ?? 'test-apple-client-id';
process.env.APPLE_TEAM_ID = process.env.APPLE_TEAM_ID ?? 'test-apple-team-id';
process.env.APPLE_KEY_ID = process.env.APPLE_KEY_ID ?? 'test-apple-key-id';
process.env.APPLE_PRIVATE_KEY = process.env.APPLE_PRIVATE_KEY ?? 'test-apple-private-key';
process.env.APPLE_CALLBACK_URL =
  process.env.APPLE_CALLBACK_URL ?? 'http://localhost:4000/auth/apple/callback';
process.env.APPLE_NATIVE_CALLBACK_URL =
  process.env.APPLE_NATIVE_CALLBACK_URL ?? 'http://localhost:4000/auth/apple/native/callback';
process.env.GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID ?? 'test-google-client-id';
process.env.GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET ?? 'test-google-client-secret';
process.env.GOOGLE_CALLBACK_URL =
  process.env.GOOGLE_CALLBACK_URL ?? 'http://localhost:4000/auth/google/callback';
process.env.GOOGLE_NATIVE_CALLBACK_URL =
  process.env.GOOGLE_NATIVE_CALLBACK_URL ?? 'http://localhost:4000/auth/google/native/callback';
process.env.GH_CLIENT_ID = process.env.GH_CLIENT_ID ?? 'test-github-client-id';
process.env.GH_CLIENT_SECRET = process.env.GH_CLIENT_SECRET ?? 'test-github-client-secret';
process.env.GH_CALLBACK_URL =
  process.env.GH_CALLBACK_URL ?? 'http://localhost:4000/auth/github/callback';
process.env.GH_NATIVE_CALLBACK_URL =
  process.env.GH_NATIVE_CALLBACK_URL ?? 'http://localhost:4000/auth/github/native/callback';
process.env.TWITTER_CLIENT_ID = process.env.TWITTER_CLIENT_ID ?? 'test-twitter-client-id';
process.env.TWITTER_CLIENT_SECRET =
  process.env.TWITTER_CLIENT_SECRET ?? 'test-twitter-client-secret';
process.env.TWITTER_CALLBACK_URL =
  process.env.TWITTER_CALLBACK_URL ?? 'http://localhost:4000/auth/twitter/callback';
process.env.TWITTER_NATIVE_CALLBACK_URL =
  process.env.TWITTER_NATIVE_CALLBACK_URL ?? 'http://localhost:4000/auth/twitter/native/callback';

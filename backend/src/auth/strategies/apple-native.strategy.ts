import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const AppleStrategyBase = require('passport-apple');
import { AppleProfile } from './apple.strategy';

@Injectable()
export class AppleNativeStrategy extends PassportStrategy(AppleStrategyBase, 'apple-native') {
  constructor() {
    super({
      clientID: process.env.APPLE_CLIENT_ID ?? '',
      teamID: process.env.APPLE_TEAM_ID ?? '',
      keyID: process.env.APPLE_KEY_ID ?? '',
      privateKeyString: (process.env.APPLE_PRIVATE_KEY ?? '').replace(
        /\\n/g,
        '\n',
      ),
      callbackURL:
        process.env.APPLE_NATIVE_CALLBACK_URL ??
        'http://localhost:4000/auth/apple/native/callback',
      passReqToCallback: true,
      scope: ['name', 'email'],
    });
  }

  async validate(
    req: any,
    _accessToken: string,
    _refreshToken: string,
    idToken: any,
    profile: any,
    done: Function,
  ) {
    const sub: string = idToken?.sub ?? profile?.id ?? '';

    let firstName: string | undefined;
    let lastName: string | undefined;
    if (req.body?.user) {
      try {
        const userData =
          typeof req.body.user === 'string'
            ? JSON.parse(req.body.user)
            : req.body.user;
        firstName = userData?.name?.firstName;
        lastName = userData?.name?.lastName;
      } catch {
        // ignore parse errors
      }
    }

    const name = [firstName, lastName].filter(Boolean).join(' ').trim() || null;

    const result: AppleProfile = {
      appleId: sub,
      email: idToken?.email ?? null,
      name,
    };

    done(null, result);
  }
}

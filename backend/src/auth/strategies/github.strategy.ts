import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, Profile } from 'passport-github2';

export type GithubProfile = {
  githubId: string;
  email: string | null;
  name: string | null;
};

@Injectable()
export class GithubStrategy extends PassportStrategy(Strategy, 'github') {
  constructor() {
    super({
      clientID: process.env.GH_CLIENT_ID ?? '',
      clientSecret: process.env.GH_CLIENT_SECRET ?? '',
      callbackURL:
        process.env.GH_CALLBACK_URL ??
        'http://localhost:4000/auth/github/callback',
      scope: ['read:user'],
    });
  }

  async validate(
    _accessToken: string,
    _refreshToken: string,
    profile: Profile,
  ): Promise<GithubProfile> {
    return {
      githubId: profile.id,
      email: profile.emails?.[0]?.value ?? null,
      name: profile.displayName ?? null,
    };
  }
}

import { auth } from "@/auth";
import createMiddleware from "next-intl/middleware";
import { routing } from "@/i18n/routing";
import { NextResponse, type NextRequest } from "next/server";

const intlMiddleware = createMiddleware(routing);

export default auth((req) => {
  const { pathname } = req.nextUrl;

  // Bypass i18n middleware for API routes
  if (pathname.startsWith("/api/")) {
    return NextResponse.next();
  }

  // Redirect authenticated users away from sign-in/sign-up
  const isAuthPage = /^\/(en|ja)\/(sign-in|sign-up)(\/|$)/.test(pathname);
  if (isAuthPage && req.auth) {
    const locale = pathname.split("/")[1] ?? "en";
    return NextResponse.redirect(new URL(`/${locale}/dashboard`, req.url));
  }

  // Protect /[locale]/dashboard and /[locale]/items routes
  const isDashboard = /^\/(en|ja)\/(dashboard|items)(\/|$)/.test(pathname);
  if (isDashboard && !req.auth) {
    const locale = pathname.split("/")[1] ?? "en";
    return NextResponse.redirect(
      new URL(`/${locale}/sign-in`, req.url)
    );
  }

  return intlMiddleware(req as unknown as NextRequest);
});

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};

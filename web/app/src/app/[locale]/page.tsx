import { setRequestLocale } from "next-intl/server";
import { getTranslations } from "next-intl/server";
import { auth } from "@/auth";
import { Link } from "@/i18n/routing";
import { LanguageSwitcher } from "@/components/LanguageSwitcher";

interface Props {
  params: Promise<{ locale: string }>;
}

export default async function HomePage({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);

  const t = await getTranslations("home");
  const nt = await getTranslations("nav");
  const session = await auth();

  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-gray-200 bg-white">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <span className="font-semibold text-gray-800">An App</span>
          <nav className="flex items-center gap-4">
            <LanguageSwitcher locale={locale} />
            {session ? (
              <Link
                href="/dashboard"
                className="text-sm font-medium text-blue-600 hover:text-blue-700"
              >
                {nt("dashboard")}
              </Link>
            ) : (
              <>
                <Link
                  href="/sign-in"
                  className="text-sm font-medium text-gray-600 hover:text-gray-800"
                >
                  {nt("signIn")}
                </Link>
                <Link
                  href="/sign-up"
                  className="text-sm font-medium bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700"
                >
                  {nt("signUp")}
                </Link>
              </>
            )}
          </nav>
        </div>
      </header>

      <main className="flex-1 flex flex-col items-center justify-center px-4">
        <div className="max-w-md w-full text-center space-y-6">
          <h1 className="text-4xl font-bold text-gray-900">{t("title")}</h1>
          <p className="text-lg text-gray-600">{t("description")}</p>
          <p className="text-gray-500">{t("signInPrompt")}</p>
          {session ? (
            <Link
              href="/dashboard"
              className="inline-block bg-blue-600 text-white px-6 py-3 rounded-md font-medium hover:bg-blue-700"
            >
              {t("goToDashboard")}
            </Link>
          ) : (
            <div className="flex gap-3 justify-center">
              <Link
                href="/sign-in"
                className="inline-block border border-gray-300 text-gray-700 px-6 py-3 rounded-md font-medium hover:bg-gray-50"
              >
                {nt("signIn")}
              </Link>
              <Link
                href="/sign-up"
                className="inline-block bg-blue-600 text-white px-6 py-3 rounded-md font-medium hover:bg-blue-700"
              >
                {nt("signUp")}
              </Link>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

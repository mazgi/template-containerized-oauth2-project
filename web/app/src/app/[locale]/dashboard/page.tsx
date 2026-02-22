import { setRequestLocale } from "next-intl/server";
import { getTranslations } from "next-intl/server";
import { auth, signOut } from "@/auth";
import { redirect } from "next/navigation";
import { LanguageSwitcher } from "@/components/LanguageSwitcher";
import { Link } from "@/i18n/routing";

interface Props {
  params: Promise<{ locale: string }>;
}

export default async function DashboardPage({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);

  const session = await auth();
  if (!session) {
    redirect(`/${locale}/sign-in`);
  }

  const t = await getTranslations("dashboard");
  const nt = await getTranslations("nav");

  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-gray-200 bg-white">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between gap-4">
          <nav className="flex items-center gap-4">
            <Link href="/" className="font-semibold text-gray-800 hover:text-gray-600">
              An App
            </Link>
            <span className="text-sm font-medium text-blue-600">{nt("dashboard")}</span>
            <Link href="/items" className="text-sm text-gray-500 hover:text-gray-700">
              {nt("items")}
            </Link>
          </nav>
          <nav className="flex items-center gap-4">
            <LanguageSwitcher locale={locale} />
            <form
              action={async () => {
                "use server";
                await signOut({ redirectTo: `/${locale}/` });
              }}
            >
              <button
                type="submit"
                className="text-sm font-medium text-gray-600 hover:text-gray-800"
              >
                {nt("signOut")}
              </button>
            </form>
          </nav>
        </div>
      </header>

      <main className="flex-1 max-w-4xl mx-auto w-full px-4 py-10">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{t("title")}</h1>
        <p className="text-gray-600 mb-8">
          {t("welcome", { name: session.user?.name ?? session.user?.email ?? "User" })}
        </p>

        <div className="bg-white border border-gray-200 rounded-lg p-6 max-w-md">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">{t("profile")}</h2>
          <dl className="space-y-3">
            <div className="flex flex-col">
              <dt className="text-xs font-medium text-gray-500 uppercase tracking-wide">
                {t("name")}
              </dt>
              <dd className="mt-1 text-sm text-gray-900">
                {session.user?.name ?? "—"}
              </dd>
            </div>
            <div className="flex flex-col">
              <dt className="text-xs font-medium text-gray-500 uppercase tracking-wide">
                {t("email")}
              </dt>
              <dd className="mt-1 text-sm text-gray-900">{session.user?.email}</dd>
            </div>
            <div className="flex flex-col">
              <dt className="text-xs font-medium text-gray-500 uppercase tracking-wide">
                {t("memberId")}
              </dt>
              <dd className="mt-1 text-sm font-mono text-gray-500">
                {session.user?.id}
              </dd>
            </div>
          </dl>
        </div>
      </main>
    </div>
  );
}

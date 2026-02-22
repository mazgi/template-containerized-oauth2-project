import { setRequestLocale } from "next-intl/server";
import { getTranslations } from "next-intl/server";
import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { Link } from "@/i18n/routing";
import { SignInForm } from "@/components/SignInForm";

interface Props {
  params: Promise<{ locale: string }>;
}

export default async function SignInPage({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);

  const session = await auth();
  if (session) {
    redirect(`/${locale}/dashboard`);
  }

  const t = await getTranslations("auth");

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="max-w-sm w-full space-y-6">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900">{t("signInTitle")}</h1>
        </div>

        <SignInForm locale={locale} />

        <p className="text-center text-sm text-gray-600">
          {t("noAccount")}{" "}
          <Link
            href="/sign-up"
            className="font-medium text-blue-600 hover:text-blue-700"
          >
            {t("signUp")}
          </Link>
        </p>
      </div>
    </div>
  );
}

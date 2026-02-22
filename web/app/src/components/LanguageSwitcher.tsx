"use client";

import { usePathname, useRouter } from "@/i18n/routing";
import { useTranslations } from "next-intl";

interface Props {
  locale: string;
}

export function LanguageSwitcher({ locale }: Props) {
  const t = useTranslations("language");
  const router = useRouter();
  const pathname = usePathname();

  const switchLocale = (nextLocale: string) => {
    router.replace(pathname, { locale: nextLocale });
  };

  return (
    <div className="flex items-center gap-1 text-sm">
      <span className="text-gray-400 text-xs">{t("switch")}:</span>
      <button
        onClick={() => switchLocale("en")}
        disabled={locale === "en"}
        className="px-2 py-0.5 rounded font-medium disabled:text-blue-600 disabled:font-semibold text-gray-500 hover:text-gray-800 disabled:cursor-default"
      >
        EN
      </button>
      <span className="text-gray-300">/</span>
      <button
        onClick={() => switchLocale("ja")}
        disabled={locale === "ja"}
        className="px-2 py-0.5 rounded font-medium disabled:text-blue-600 disabled:font-semibold text-gray-500 hover:text-gray-800 disabled:cursor-default"
      >
        JA
      </button>
    </div>
  );
}

"use client";

import { useRef, useState, useTransition } from "react";
import { useTranslations } from "next-intl";
import { useRouter } from "@/i18n/routing";
import { shareItemAction, unshareItemAction } from "@/lib/item-actions";

interface SharedUser {
  id: string;
  name: string | null;
  email: string;
}

interface Props {
  itemId: string;
  locale: string;
  sharedUsers: SharedUser[];
}

export function ItemShareForm({ itemId, locale, sharedUsers }: Props) {
  const t = useTranslations("items");
  const router = useRouter();
  const emailRef = useRef<HTMLInputElement>(null);
  const [shareError, setShareError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const handleShare = (e: React.FormEvent) => {
    e.preventDefault();
    const email = emailRef.current?.value.trim() ?? "";
    if (!email) return;

    setShareError(null);
    startTransition(async () => {
      const result = await shareItemAction({ itemId, email, locale });
      if (result?.error) {
        setShareError(t(`errors.${result.error}` as Parameters<typeof t>[0]));
      } else {
        if (emailRef.current) emailRef.current.value = "";
        router.refresh();
      }
    });
  };

  const handleUnshare = (userId: string) => {
    startTransition(async () => {
      await unshareItemAction({ itemId, userId, locale });
      router.refresh();
    });
  };

  return (
    <div className="space-y-4">
      {sharedUsers.length === 0 ? (
        <p className="text-sm text-gray-500">{t("noShares")}</p>
      ) : (
        <ul className="divide-y divide-gray-100">
          {sharedUsers.map((u) => (
            <li key={u.id} className="flex items-center justify-between py-2">
              <div className="flex flex-col">
                {u.name && <span className="text-sm font-medium text-gray-800">{u.name}</span>}
                <span className="text-xs text-gray-500">{u.email}</span>
              </div>
              <button
                onClick={() => handleUnshare(u.id)}
                disabled={isPending}
                className="text-xs text-red-500 border border-red-200 rounded px-2 py-1 hover:bg-red-50 disabled:opacity-50"
              >
                {t("unshare")}
              </button>
            </li>
          ))}
        </ul>
      )}

      <form onSubmit={handleShare} className="space-y-2">
        <p className="text-sm font-medium text-gray-700">{t("shareWith")}</p>
        <div className="flex gap-2">
          <input
            ref={emailRef}
            type="email"
            placeholder={t("shareEmailPlaceholder")}
            className="flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
          <button
            type="submit"
            disabled={isPending}
            className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {isPending ? "..." : t("share")}
          </button>
        </div>
        {shareError && <p className="text-xs text-red-600">{shareError}</p>}
      </form>
    </div>
  );
}

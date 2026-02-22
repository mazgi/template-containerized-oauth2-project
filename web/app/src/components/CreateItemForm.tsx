"use client";

import { useRef, useState, useTransition } from "react";
import { useTranslations } from "next-intl";
import { createItemAction } from "@/lib/item-actions";

interface Props {
  locale: string;
}

export function CreateItemForm({ locale }: Props) {
  const t = useTranslations("items");
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const inputRef = useRef<HTMLInputElement>(null);

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const name = inputRef.current?.value.trim() ?? "";
    if (!name) return;

    setError(null);
    startTransition(async () => {
      const result = await createItemAction({ name, locale });
      if (result?.error) {
        setError(t(`errors.${result.error}` as Parameters<typeof t>[0]));
      } else {
        if (inputRef.current) inputRef.current.value = "";
      }
    });
  };

  return (
    <form onSubmit={handleSubmit} className="flex gap-2 max-w-sm">
      <input
        ref={inputRef}
        type="text"
        placeholder={t("namePlaceholder")}
        required
        className="flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
      />
      <button
        type="submit"
        disabled={isPending}
        className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-60 disabled:cursor-not-allowed"
      >
        {isPending ? "..." : t("create")}
      </button>
      {error && <p className="text-xs text-red-600 self-center">{error}</p>}
    </form>
  );
}

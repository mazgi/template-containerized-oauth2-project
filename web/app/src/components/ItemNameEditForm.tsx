"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "next-intl";
import { useRouter } from "@/i18n/routing";
import { updateItemNameAction } from "@/lib/item-actions";

interface Props {
  itemId: string;
  initialName: string;
  locale: string;
}

export function ItemNameEditForm({ itemId, initialName, locale }: Props) {
  const t = useTranslations("items");
  const router = useRouter();
  const [editing, setEditing] = useState(false);
  const [name, setName] = useState(initialName);
  const [draft, setDraft] = useState(initialName);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  const handleSave = () => {
    const trimmed = draft.trim();
    if (!trimmed) return;
    setError(null);
    startTransition(async () => {
      const result = await updateItemNameAction({ id: itemId, name: trimmed, locale });
      if (result?.error) {
        setError(t(`errors.${result.error}` as Parameters<typeof t>[0]));
      } else {
        setName(trimmed);
        setEditing(false);
        router.refresh();
      }
    });
  };

  const handleCancel = () => {
    setDraft(name);
    setEditing(false);
    setError(null);
  };

  if (!editing) {
    return (
      <div className="flex items-center gap-3">
        <h1 className="text-2xl font-bold text-gray-900">{name}</h1>
        <button
          onClick={() => setEditing(true)}
          className="text-xs text-gray-500 border border-gray-300 rounded px-2 py-1 hover:bg-gray-50"
        >
          {t("edit")}
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2">
        <input
          type="text"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") handleSave();
            if (e.key === "Escape") handleCancel();
          }}
          autoFocus
          className="text-2xl font-bold text-gray-900 border-b-2 border-blue-500 focus:outline-none bg-transparent w-full max-w-sm"
        />
        <button
          onClick={handleSave}
          disabled={isPending}
          className="text-xs bg-blue-600 text-white rounded px-3 py-1.5 hover:bg-blue-700 disabled:opacity-60"
        >
          {isPending ? "..." : t("save")}
        </button>
        <button
          onClick={handleCancel}
          disabled={isPending}
          className="text-xs border border-gray-300 rounded px-3 py-1.5 hover:bg-gray-50 disabled:opacity-60"
        >
          {t("cancel")}
        </button>
      </div>
      {error && <p className="text-xs text-red-600">{error}</p>}
    </div>
  );
}

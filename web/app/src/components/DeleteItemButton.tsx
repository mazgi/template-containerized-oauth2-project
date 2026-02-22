"use client";

import { useTransition } from "react";
import { useTranslations } from "next-intl";
import { deleteItemAction } from "@/lib/item-actions";

interface Props {
  itemId: string;
  locale: string;
}

export function DeleteItemButton({ itemId, locale }: Props) {
  const t = useTranslations("items");
  const [isPending, startTransition] = useTransition();

  const handleDelete = () => {
    if (!window.confirm(t("deleteConfirm"))) return;
    startTransition(async () => {
      await deleteItemAction({ id: itemId, locale });
    });
  };

  return (
    <button
      onClick={handleDelete}
      disabled={isPending}
      className="rounded-md border border-red-300 px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-50 disabled:opacity-60 disabled:cursor-not-allowed"
    >
      {isPending ? "..." : t("deleteItem")}
    </button>
  );
}

import { setRequestLocale } from "next-intl/server";
import { getTranslations } from "next-intl/server";
import { auth, signOut } from "@/auth";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/db";
import { Link } from "@/i18n/routing";
import { LanguageSwitcher } from "@/components/LanguageSwitcher";
import { ItemNameEditForm } from "@/components/ItemNameEditForm";
import { ItemShareForm } from "@/components/ItemShareForm";
import { DeleteItemButton } from "@/components/DeleteItemButton";

interface Props {
  params: Promise<{ locale: string; id: string }>;
}

export default async function ItemDetailPage({ params }: Props) {
  const { locale, id } = await params;
  setRequestLocale(locale);

  const session = await auth();
  if (!session?.user?.id) {
    redirect(`/${locale}/sign-in`);
  }

  const item = await prisma.item.findUnique({
    where: { id },
    include: {
      owner: { select: { id: true, name: true, email: true } },
      shares: {
        include: { user: { select: { id: true, name: true, email: true } } },
        orderBy: { createdAt: "asc" },
      },
    },
  });

  if (!item) redirect(`/${locale}/items`);

  const isOwner = item.ownerId === session.user.id;
  const hasAccess =
    isOwner || item.shares.some((s) => s.userId === session.user.id);

  if (!hasAccess) redirect(`/${locale}/items`);

  const t = await getTranslations("items");
  const nt = await getTranslations("nav");

  const sharedUsers = item.shares.map((s) => ({
    id: s.user.id,
    name: s.user.name,
    email: s.user.email,
  }));

  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-gray-200 bg-white">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <nav className="flex items-center gap-4">
            <Link href="/" className="font-semibold text-gray-800 hover:text-gray-600">
              An App
            </Link>
            <Link href="/dashboard" className="text-sm text-gray-500 hover:text-gray-700">
              {nt("dashboard")}
            </Link>
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
              <button type="submit" className="text-sm text-gray-600 hover:text-gray-800">
                {nt("signOut")}
              </button>
            </form>
          </nav>
        </div>
      </header>

      <main className="flex-1 max-w-4xl mx-auto w-full px-4 py-10 space-y-8">
        <Link
          href="/items"
          className="inline-flex items-center text-sm text-gray-500 hover:text-gray-700"
        >
          ← {t("back")}
        </Link>

        <div className="space-y-1">
          {isOwner ? (
            <ItemNameEditForm
              itemId={item.id}
              initialName={item.name}
              locale={locale}
            />
          ) : (
            <h1 className="text-2xl font-bold text-gray-900">{item.name}</h1>
          )}
          <p className="text-sm text-gray-500">
            {t("owner")}:{" "}
            <span className="font-medium">
              {item.owner.name ?? item.owner.email}
            </span>
            {isOwner && (
              <span className="ml-1 text-xs text-blue-600">(you)</span>
            )}
          </p>
          <p className="text-sm text-gray-400">
            {t("createdAt")}: {item.createdAt.toLocaleDateString(locale)}
          </p>
        </div>

        {!isOwner && (
          <p className="text-sm text-gray-500 italic">
            {t("sharedBy", { name: item.owner.name ?? item.owner.email })}
          </p>
        )}

        {isOwner && (
          <>
            <section className="border border-gray-200 rounded-lg bg-white p-6 space-y-4">
              <h2 className="text-base font-semibold text-gray-800">{t("sharedWith")}</h2>
              <ItemShareForm
                itemId={item.id}
                locale={locale}
                sharedUsers={sharedUsers}
              />
            </section>

            <DeleteItemButton
              itemId={item.id}
              locale={locale}
            />
          </>
        )}
      </main>
    </div>
  );
}

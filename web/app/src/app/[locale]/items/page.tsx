import { setRequestLocale } from "next-intl/server";
import { getTranslations } from "next-intl/server";
import { auth, signOut } from "@/auth";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/db";
import { Link } from "@/i18n/routing";
import { LanguageSwitcher } from "@/components/LanguageSwitcher";
import { CreateItemForm } from "@/components/CreateItemForm";

interface Props {
  params: Promise<{ locale: string }>;
}

export default async function ItemsPage({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);

  const session = await auth();
  if (!session?.user?.id) {
    redirect(`/${locale}/sign-in`);
  }

  const t = await getTranslations("items");
  const nt = await getTranslations("nav");

  const [ownedItems, sharedItems] = await Promise.all([
    prisma.item.findMany({
      where: { ownerId: session.user.id },
      orderBy: { createdAt: "desc" },
    }),
    prisma.item.findMany({
      where: { shares: { some: { userId: session.user.id } } },
      include: { owner: { select: { name: true, email: true } } },
      orderBy: { createdAt: "desc" },
    }),
  ]);

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
            <span className="text-sm font-medium text-blue-600">{nt("items")}</span>
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

      <main className="flex-1 max-w-4xl mx-auto w-full px-4 py-10 space-y-10">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 mb-4">{t("newItem")}</h1>
          <CreateItemForm locale={locale} />
        </div>

        <section>
          <h2 className="text-lg font-semibold text-gray-800 mb-3">{t("myItems")}</h2>
          {ownedItems.length === 0 ? (
            <p className="text-sm text-gray-500">{t("noItems")}</p>
          ) : (
            <ul className="divide-y divide-gray-200 border border-gray-200 rounded-lg bg-white">
              {ownedItems.map((item) => (
                <li key={item.id} className="flex items-center justify-between px-4 py-3">
                  <Link
                    href={`/items/${item.id}`}
                    className="text-sm font-medium text-blue-600 hover:text-blue-700"
                  >
                    {item.name}
                  </Link>
                  <span className="text-xs text-gray-400">
                    {item.createdAt.toLocaleDateString(locale)}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </section>

        <section>
          <h2 className="text-lg font-semibold text-gray-800 mb-3">{t("sharedWithMe")}</h2>
          {sharedItems.length === 0 ? (
            <p className="text-sm text-gray-500">{t("noSharedItems")}</p>
          ) : (
            <ul className="divide-y divide-gray-200 border border-gray-200 rounded-lg bg-white">
              {sharedItems.map((item) => (
                <li key={item.id} className="flex items-center justify-between px-4 py-3">
                  <div className="flex flex-col gap-0.5">
                    <Link
                      href={`/items/${item.id}`}
                      className="text-sm font-medium text-blue-600 hover:text-blue-700"
                    >
                      {item.name}
                    </Link>
                    <span className="text-xs text-gray-400">
                      {t("sharedBy", { name: item.owner.name ?? item.owner.email })}
                    </span>
                  </div>
                  <span className="text-xs text-gray-400">
                    {item.createdAt.toLocaleDateString(locale)}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </section>
      </main>
    </div>
  );
}

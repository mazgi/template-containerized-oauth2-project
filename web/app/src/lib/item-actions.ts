"use server";

import { auth } from "@/auth";
import { prisma } from "@/lib/db";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

async function requireOwner(itemId: string, userId: string) {
  const item = await prisma.item.findUnique({ where: { id: itemId } });
  if (!item) return { error: "notFound" as const, item: null };
  if (item.ownerId !== userId) return { error: "forbidden" as const, item: null };
  return { error: null, item };
}

export async function createItemAction(data: {
  name: string;
  locale: string;
}): Promise<{ error: string } | undefined> {
  const session = await auth();
  if (!session?.user?.id) return { error: "unauthorized" };

  const parsed = z.object({ name: z.string().min(1) }).safeParse(data);
  if (!parsed.success) return { error: "generic" };

  await prisma.item.create({
    data: { name: data.name, ownerId: session.user.id },
  });

  revalidatePath(`/${data.locale}/items`);
}

export async function updateItemNameAction(data: {
  id: string;
  name: string;
  locale: string;
}): Promise<{ error: string } | undefined> {
  const session = await auth();
  if (!session?.user?.id) return { error: "unauthorized" };

  const parsed = z.object({ name: z.string().min(1) }).safeParse(data);
  if (!parsed.success) return { error: "generic" };

  const { error } = await requireOwner(data.id, session.user.id);
  if (error) return { error };

  await prisma.item.update({ where: { id: data.id }, data: { name: data.name } });
  revalidatePath(`/${data.locale}/items/${data.id}`);
}

export async function deleteItemAction(data: {
  id: string;
  locale: string;
}): Promise<{ error: string } | undefined> {
  const session = await auth();
  if (!session?.user?.id) return { error: "unauthorized" };

  const { error } = await requireOwner(data.id, session.user.id);
  if (error) return { error };

  await prisma.item.delete({ where: { id: data.id } });
  redirect(`/${data.locale}/items`);
}

export async function shareItemAction(data: {
  itemId: string;
  email: string;
  locale: string;
}): Promise<{ error: string } | undefined> {
  const session = await auth();
  if (!session?.user?.id) return { error: "unauthorized" };

  const { error } = await requireOwner(data.itemId, session.user.id);
  if (error) return { error };

  const target = await prisma.user.findUnique({ where: { email: data.email } });
  if (!target) return { error: "userNotFound" };
  if (target.id === session.user.id) return { error: "cannotShareWithSelf" };

  const existing = await prisma.itemShare.findUnique({
    where: { itemId_userId: { itemId: data.itemId, userId: target.id } },
  });
  if (existing) return { error: "alreadyShared" };

  await prisma.itemShare.create({ data: { itemId: data.itemId, userId: target.id } });
  revalidatePath(`/${data.locale}/items/${data.itemId}`);
}

export async function unshareItemAction(data: {
  itemId: string;
  userId: string;
  locale: string;
}): Promise<{ error: string } | undefined> {
  const session = await auth();
  if (!session?.user?.id) return { error: "unauthorized" };

  const { error } = await requireOwner(data.itemId, session.user.id);
  if (error) return { error };

  await prisma.itemShare.delete({
    where: { itemId_userId: { itemId: data.itemId, userId: data.userId } },
  });
  revalidatePath(`/${data.locale}/items/${data.itemId}`);
}

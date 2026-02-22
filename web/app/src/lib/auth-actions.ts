"use server";

import { signIn } from "@/auth";
import { prisma } from "@/lib/db";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { AuthError } from "next-auth";

const signInSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
  locale: z.string().default("en"),
});

const signUpSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  password: z.string().min(8),
  locale: z.string().default("en"),
});

export async function signInAction(data: {
  email: string;
  password: string;
  locale: string;
}): Promise<{ error: string } | undefined> {
  const parsed = signInSchema.safeParse(data);
  if (!parsed.success) {
    return { error: "invalidCredentials" };
  }

  try {
    await signIn("credentials", {
      email: parsed.data.email,
      password: parsed.data.password,
      redirectTo: `/${parsed.data.locale}/dashboard`,
    });
  } catch (error) {
    if (error instanceof AuthError) {
      return { error: "invalidCredentials" };
    }
    throw error;
  }
}

export async function signUpAction(data: {
  name: string;
  email: string;
  password: string;
  locale: string;
}): Promise<{ error: string } | undefined> {
  const parsed = signUpSchema.safeParse(data);
  if (!parsed.success) {
    return { error: "generic" };
  }

  const { name, email, password, locale } = parsed.data;

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return { error: "emailExists" };
  }

  const hashedPassword = await bcrypt.hash(password, 12);
  await prisma.user.create({
    data: { name, email, password: hashedPassword },
  });

  try {
    await signIn("credentials", {
      email,
      password,
      redirectTo: `/${locale}/dashboard`,
    });
  } catch (error) {
    if (error instanceof AuthError) {
      return { error: "invalidCredentials" };
    }
    throw error;
  }
}

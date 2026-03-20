"use server";

import { prisma } from "@/lib/db";
import { revalidatePath } from "next/cache";

export async function getTodos() {
  return prisma.todo.findMany({
    orderBy: [
      { isCompleted: "asc" },
      { createdAt: "desc" },
    ],
  });
}

export async function addTodo(formData: FormData) {
  const title = formData.get("title");

  if (!title || typeof title !== "string" || title.trim().length === 0) {
    return;
  }

  await prisma.todo.create({
    data: {
      title: title.trim(),
    },
  });

  revalidatePath("/");
}

export async function toggleTodo(id: string, isCompleted: boolean) {
  await prisma.todo.update({
    where: { id },
    data: { isCompleted },
  });

  revalidatePath("/");
}

export async function deleteTodo(id: string) {
  await prisma.todo.delete({
    where: { id },
  });

  revalidatePath("/");
}

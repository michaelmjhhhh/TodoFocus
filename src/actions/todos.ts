"use server";

import { prisma } from "@/lib/db";
import { revalidatePath } from "next/cache";

// ── Todos ──

export async function getTodos(filter?: {
  listId?: string;
  isMyDay?: boolean;
  isImportant?: boolean;
  planned?: boolean;
}) {
  const where: Record<string, unknown> = {};

  if (filter?.listId) where.listId = filter.listId;
  if (filter?.isMyDay) where.isMyDay = true;
  if (filter?.isImportant) where.isImportant = true;
  if (filter?.planned) where.dueDate = { not: null };

  return prisma.todo.findMany({
    where,
    include: {
      steps: { orderBy: { sortOrder: "asc" } },
      list: true,
    },
    orderBy: [
      { isCompleted: "asc" },
      { sortOrder: "asc" },
      { createdAt: "desc" },
    ],
  });
}

export async function getTodo(id: string) {
  return prisma.todo.findUnique({
    where: { id },
    include: {
      steps: { orderBy: { sortOrder: "asc" } },
      list: true,
    },
  });
}

export async function addTodo(formData: FormData) {
  const title = formData.get("title");
  const listId = formData.get("listId") as string | null;
  const isMyDay = formData.get("isMyDay") === "true";
  const isImportant = formData.get("isImportant") === "true";
  const planned = formData.get("planned") === "true";

  if (!title || typeof title !== "string" || title.trim().length === 0) {
    return;
  }

  await prisma.todo.create({
    data: {
      title: title.trim(),
      listId: listId || null,
      isMyDay,
      isImportant,
      dueDate: planned ? new Date() : null,
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

export async function toggleImportant(id: string, isImportant: boolean) {
  await prisma.todo.update({
    where: { id },
    data: { isImportant },
  });
  revalidatePath("/");
}

export async function toggleMyDay(id: string, isMyDay: boolean) {
  await prisma.todo.update({
    where: { id },
    data: { isMyDay },
  });
  revalidatePath("/");
}

export async function updateTodo(
  id: string,
  data: {
    title?: string;
    notes?: string;
    dueDate?: string | null;
    isImportant?: boolean;
    isMyDay?: boolean;
    listId?: string | null;
  }
) {
  const updateData: Record<string, unknown> = {};
  if (data.title !== undefined) updateData.title = data.title;
  if (data.notes !== undefined) updateData.notes = data.notes;
  if (data.dueDate !== undefined) {
    updateData.dueDate = data.dueDate ? new Date(data.dueDate) : null;
  }
  if (data.isImportant !== undefined) updateData.isImportant = data.isImportant;
  if (data.isMyDay !== undefined) updateData.isMyDay = data.isMyDay;
  if (data.listId !== undefined) updateData.listId = data.listId || null;

  await prisma.todo.update({ where: { id }, data: updateData });
  revalidatePath("/");
}

export async function deleteTodo(id: string) {
  await prisma.todo.delete({ where: { id } });
  revalidatePath("/");
}

// ── Steps ──

export async function addStep(todoId: string, title: string) {
  const count = await prisma.step.count({ where: { todoId } });
  await prisma.step.create({
    data: { title, todoId, sortOrder: count },
  });
  revalidatePath("/");
}

export async function toggleStep(id: string, isCompleted: boolean) {
  await prisma.step.update({
    where: { id },
    data: { isCompleted },
  });
  revalidatePath("/");
}

export async function deleteStep(id: string) {
  await prisma.step.delete({ where: { id } });
  revalidatePath("/");
}

// ── Lists ──

export async function getLists() {
  return prisma.list.findMany({
    orderBy: { sortOrder: "asc" },
    include: {
      _count: { select: { todos: { where: { isCompleted: false } } } },
    },
  });
}

export async function createList(name: string) {
  const count = await prisma.list.count();
  const colors = ["#6366F1", "#8B5CF6", "#EC4899", "#F59E0B", "#10B981", "#3B82F6", "#EF4444"];
  await prisma.list.create({
    data: {
      name,
      color: colors[count % colors.length],
      sortOrder: count,
    },
  });
  revalidatePath("/");
}

export async function deleteList(id: string) {
  await prisma.list.delete({ where: { id } });
  revalidatePath("/");
}

export async function renameList(id: string, name: string) {
  await prisma.list.update({
    where: { id },
    data: { name },
  });
  revalidatePath("/");
}

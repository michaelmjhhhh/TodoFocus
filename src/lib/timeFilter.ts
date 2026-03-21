export type TimeFilter =
  | "all-dates"
  | "overdue"
  | "today"
  | "tomorrow"
  | "next-7-days"
  | "no-date";

function startOfLocalDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function diffInLocalDays(from: Date, to: Date): number {
  const fromDay = startOfLocalDay(from).getTime();
  const toDay = startOfLocalDay(to).getTime();
  return Math.round((toDay - fromDay) / 86_400_000);
}

export function matchesTimeFilter(
  filter: TimeFilter,
  dueDate: Date | null,
  now: Date = new Date()
): boolean {
  if (filter === "all-dates") {
    return true;
  }

  if (filter === "no-date") {
    return dueDate === null;
  }

  if (dueDate === null) {
    return false;
  }

  const dayDiff = diffInLocalDays(now, dueDate);

  if (filter === "overdue") {
    return dayDiff < 0;
  }

  if (filter === "today") {
    return dayDiff === 0;
  }

  if (filter === "tomorrow") {
    return dayDiff === 1;
  }

  return dayDiff >= 0 && dayDiff <= 6;
}

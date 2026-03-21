"use client";

import type { TimeFilter } from "@/lib/timeFilter";
import { cn } from "@/lib/cn";

interface TimeFilterBarProps {
  value: TimeFilter;
  onChange: (next: TimeFilter) => void;
}

const filterOptions: Array<{ value: TimeFilter; label: string }> = [
  { value: "all-dates", label: "All dates" },
  { value: "overdue", label: "Overdue" },
  { value: "today", label: "Today" },
  { value: "tomorrow", label: "Tomorrow" },
  { value: "next-7-days", label: "Next 7 days" },
  { value: "no-date", label: "No date" },
];

export function TimeFilterBar({ value, onChange }: TimeFilterBarProps) {
  return (
    <div className="mt-3 overflow-x-auto">
      <div className="inline-flex items-center gap-1 rounded-lg border border-[var(--zen-border)] bg-[var(--zen-surface)] p-1">
        {filterOptions.map((option) => {
          const isActive = option.value === value;
          return (
            <button
              key={option.value}
              type="button"
              onClick={() => onChange(option.value)}
              className={cn(
                "whitespace-nowrap rounded-md px-3 py-1.5 text-xs font-medium transition-colors cursor-pointer",
                isActive
                  ? "bg-[var(--zen-accent-soft)] text-[var(--zen-accent)]"
                  : "text-[var(--zen-text-secondary)] hover:bg-[var(--zen-surface-hover)]"
              )}
            >
              {option.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}

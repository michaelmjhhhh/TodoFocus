interface CalloutProps {
  children: React.ReactNode;
  type?: "note" | "tip" | "warning" | "danger" | "info";
  title?: string;
}

const calloutStyles: Record<string, string> = {
  note: "bg-terracotta/10 border-terracotta text-terracotta",
  tip: "bg-green-50 border-green-600 text-green-800",
  warning: "bg-amber-50 border-amber-600 text-amber-800",
  danger: "bg-red-50 border-red-600 text-red-800",
  info: "bg-blue-50 border-blue-600 text-blue-800",
};

const calloutIcons: Record<string, string> = {
  note: "📌",
  tip: "✨",
  warning: "⚠️",
  danger: "🚨",
  info: "ℹ️",
};

export function Callout({ children, type = "note", title }: CalloutProps) {
  const style = calloutStyles[type] ?? calloutStyles.note;
  const icon = calloutIcons[type] ?? calloutIcons.note;

  return (
    <div
      className={`my-6 rounded-xl border-l-4 px-5 py-4 ${style} text-sm leading-relaxed`}
    >
      <div className="flex items-center gap-2 font-sans font-semibold mb-2">
        <span>{icon}</span>
        <span>{title ?? type.charAt(0).toUpperCase() + type.slice(1)}</span>
      </div>
      <div className="font-sans [&&>p]:m-0">{children}</div>
    </div>
  );
}

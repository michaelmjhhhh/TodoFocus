interface KbdProps {
  children: React.ReactNode;
}

export function Kbd({ children }: KbdProps) {
  return (
    <kbd
      className="inline-flex items-center justify-center rounded-md border border-ink-lighter/30 bg-paper-dark px-1.5 py-0.5
        font-mono text-xs text-ink shadow-sm"
    >
      {children}
    </kbd>
  );
}

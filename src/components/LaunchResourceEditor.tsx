"use client";

import { Plus, X } from "lucide-react";
import { useState } from "react";
import {
  type LaunchResource,
  type LaunchResourceType,
  validateLaunchResource,
} from "@/lib/launchResources";

interface LaunchResourceEditorProps {
  resources: LaunchResource[];
  onChange: (resources: LaunchResource[]) => void;
  disabled?: boolean;
}

function buildNewResource(): LaunchResource {
  const now = new Date().toISOString();
  return {
    id: `lr_local_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`,
    type: "url",
    label: "",
    value: "",
    createdAt: now,
  };
}

function getValidationMessage(resource: LaunchResource): string | null {
  const result = validateLaunchResource(resource);
  if (result.ok) {
    return null;
  }

  switch (result.error) {
    case "invalid_label":
      return "Add a label.";
    case "invalid_value":
      return "Add a value.";
    case "invalid_url":
      return "Use an http(s) URL.";
    case "invalid_file_path":
      return "Use an absolute file path.";
    case "invalid_app_target":
      return "Use an app path or supported deep link.";
    default:
      return "Invalid resource.";
  }
}

export function LaunchResourceEditor({
  resources,
  onChange,
  disabled = false,
}: LaunchResourceEditorProps) {
  const [pickerMessage, setPickerMessage] = useState<string | null>(null);
  const [pickerBusyId, setPickerBusyId] = useState<string | null>(null);

  const isDesktop = typeof window !== "undefined" && Boolean(window.electronAPI?.isElectron);

  function updateResource(index: number, patch: Partial<LaunchResource>) {
    const next = [...resources];
    const current = next[index];
    if (!current) {
      return;
    }

    next[index] = { ...current, ...patch };
    onChange(next);
  }

  function removeResource(index: number) {
    onChange(resources.filter((_, itemIndex) => itemIndex !== index));
  }

  function addResource() {
    if (resources.length >= 12) {
      return;
    }

    onChange([...resources, buildNewResource()]);
  }

  async function browseForResource(index: number, type: LaunchResourceType) {
    if (disabled || !isDesktop) {
      return;
    }

    const api = window.electronAPI;
    if (!api) {
      setPickerMessage("Desktop picker integration is unavailable.");
      return;
    }

    const resource = resources[index];
    if (!resource) {
      return;
    }

    setPickerMessage(null);
    setPickerBusyId(resource.id);

    try {
      const result =
        type === "file" ? await api.pickLaunchFile() : await api.pickLaunchApp();
      if (!result.ok) {
        if (!result.canceled) {
          setPickerMessage("Could not use picker. You can still paste a value manually.");
        }
        return;
      }

      updateResource(index, { value: result.value });
    } catch {
      setPickerMessage("Could not use picker. You can still paste a value manually.");
    } finally {
      setPickerBusyId(null);
    }
  }

  return (
    <div className="space-y-2">
      {resources.map((resource, index) => {
        const error = getValidationMessage(resource);

        return (
          <div
            key={resource.id}
            className="rounded-lg border border-[var(--zen-border)] bg-[var(--zen-surface)] p-2"
          >
            <div className="grid grid-cols-1 gap-2 md:grid-cols-[92px_minmax(0,1fr)_auto]">
              <select
                value={resource.type}
                onChange={(e) =>
                  updateResource(index, { type: e.target.value as LaunchResourceType })
                }
                disabled={disabled}
                className="rounded-md border border-[var(--zen-border)] bg-[var(--zen-bg-secondary)] px-2 py-1.5 text-[12px] text-[var(--zen-text)] focus:outline-none focus:border-[var(--zen-accent)] min-w-0"
              >
                <option value="url">URL</option>
                <option value="file">File</option>
                <option value="app">App</option>
              </select>
              <div className="grid grid-cols-1 gap-2 min-w-0 sm:grid-cols-2">
                <input
                  value={resource.label}
                  onChange={(e) => updateResource(index, { label: e.target.value })}
                  disabled={disabled}
                  placeholder="Label"
                  className="rounded-md border border-[var(--zen-border)] bg-[var(--zen-bg-secondary)] px-2 py-1.5 text-[12px] text-[var(--zen-text)] placeholder:text-[var(--zen-text-muted)] focus:outline-none focus:border-[var(--zen-accent)] min-w-0"
                />
                <div className="flex min-w-0 flex-wrap items-center gap-1.5 sm:flex-nowrap">
                  <input
                    value={resource.value}
                    onChange={(e) => updateResource(index, { value: e.target.value })}
                    disabled={disabled}
                    placeholder={
                      resource.type === "url"
                        ? "https://example.com"
                        : resource.type === "file"
                          ? "/Users/name/file"
                          : "obsidian://... or /Applications/App.app"
                    }
                    title={resource.value}
                    className="min-w-0 flex-1 rounded-md border border-[var(--zen-border)] bg-[var(--zen-bg-secondary)] px-2 py-1.5 text-[12px] text-[var(--zen-text)] placeholder:text-[var(--zen-text-muted)] focus:outline-none focus:border-[var(--zen-accent)]"
                  />
                  {resource.type === "file" || resource.type === "app" ? (
                    <button
                      type="button"
                      onClick={() => browseForResource(index, resource.type)}
                      disabled={disabled || !isDesktop || pickerBusyId === resource.id}
                      className="px-2 py-1.5 rounded-md border border-[var(--zen-border)] text-[11px] text-[var(--zen-text-secondary)] hover:bg-[var(--zen-surface-hover)] transition-colors cursor-pointer disabled:opacity-60"
                    >
                      {pickerBusyId === resource.id ? "Browsing..." : "Browse..."}
                    </button>
                  ) : null}
                </div>
              </div>
              <button
                type="button"
                onClick={() => removeResource(index)}
                disabled={disabled}
                className="justify-self-end p-1.5 text-[var(--zen-text-muted)] hover:text-[var(--zen-danger)] transition-colors cursor-pointer"
                aria-label="Remove launch resource"
              >
                <X size={14} strokeWidth={1.5} />
              </button>
            </div>
            {error ? (
              <p className="mt-1 text-[11px] text-[var(--zen-danger)]">{error}</p>
            ) : null}
          </div>
        );
      })}

      <button
        type="button"
        onClick={addResource}
        disabled={disabled || resources.length >= 12}
        className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-md border border-dashed border-[var(--zen-border)] text-[12px] text-[var(--zen-text-secondary)] hover:bg-[var(--zen-surface-hover)] transition-colors cursor-pointer disabled:opacity-60"
      >
        <Plus size={13} strokeWidth={1.5} />
        Add resource
      </button>
      {!isDesktop ? (
        <p className="text-[11px] text-[var(--zen-text-muted)]">
          File and app pickers are available in the desktop app.
        </p>
      ) : null}
      {pickerMessage ? (
        <p className="text-[11px] text-[var(--zen-text-muted)]">{pickerMessage}</p>
      ) : null}
    </div>
  );
}

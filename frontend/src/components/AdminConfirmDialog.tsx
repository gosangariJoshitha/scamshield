import { useEffect, useRef } from 'react';

interface AdminConfirmDialogProps {
  title: string;
  description: string;
  confirmLabel: string;
  destructive?: boolean;
  loading?: boolean;
  error?: string | null;
  onCancel: () => void;
  onConfirm: () => void;
}

export default function AdminConfirmDialog({
  title,
  description,
  confirmLabel,
  destructive = false,
  loading = false,
  error = null,
  onCancel,
  onConfirm,
}: AdminConfirmDialogProps) {
  const cancelButtonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    cancelButtonRef.current?.focus();
  }, []);

  return (
    <div className="fixed inset-0 z-[70] grid place-items-center bg-black/50 p-4">
      <section
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="admin-confirm-title"
        aria-describedby="admin-confirm-description"
        className="w-full max-w-md rounded-2xl border border-border-light bg-card p-6 shadow-xl"
      >
        <h2 id="admin-confirm-title" className="text-lg font-bold text-text-main">{title}</h2>
        <p id="admin-confirm-description" className="mt-2 text-sm leading-relaxed text-text-secondary">{description}</p>
        {error && <p role="alert" className="mt-3 rounded-lg border border-danger/20 bg-danger/5 p-3 text-sm text-danger">{error}</p>}
        <div className="mt-6 flex justify-end gap-3">
          <button
            ref={cancelButtonRef}
            type="button"
            disabled={loading}
            onClick={onCancel}
            className="rounded-lg border border-border-light px-4 py-2 text-sm font-semibold text-text-secondary hover:bg-background disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="button"
            disabled={loading}
            onClick={onConfirm}
            className={`rounded-lg px-4 py-2 text-sm font-semibold text-white disabled:cursor-not-allowed disabled:opacity-50 ${
              destructive ? 'bg-danger hover:bg-danger/90' : 'bg-primary hover:bg-primary-hover'
            }`}
          >
            {loading ? 'Please wait…' : confirmLabel}
          </button>
        </div>
      </section>
    </div>
  );
}

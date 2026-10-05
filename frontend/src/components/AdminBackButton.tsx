import { ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

interface AdminBackButtonProps {
  to: string;
  label: string;
}

export default function AdminBackButton({ to, label }: AdminBackButtonProps) {
  const navigate = useNavigate();

  return (
    <button
      type="button"
      onClick={() => navigate(to)}
      className="inline-flex h-9 items-center gap-2 rounded-lg border border-border-light bg-card px-3 text-sm font-semibold text-text-secondary transition-colors hover:border-primary/40 hover:bg-background hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
    >
      <ArrowLeft size={16} aria-hidden="true" />
      {label}
    </button>
  );
}

import { ReactNode } from 'react';
import { FileQuestion } from 'lucide-react';

interface EmptyStateProps {
  title: string;
  description: string;
  icon?: ReactNode;
  action?: ReactNode;
}

export function EmptyState({ title, description, icon, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center p-12 text-center bg-card border border-border-light rounded-2xl shadow-sm">
      <div className="w-16 h-16 bg-background text-text-muted rounded-full flex items-center justify-center mb-4 shrink-0">
        {icon || <FileQuestion className="w-8 h-8" />}
      </div>
      <h3 className="text-lg font-bold text-text-main mb-2">{title}</h3>
      <p className="text-text-muted text-sm max-w-sm mb-6">{description}</p>
      {action && <div>{action}</div>}
    </div>
  );
}

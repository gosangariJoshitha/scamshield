import { AlertTriangle } from 'lucide-react';

interface ErrorStateProps {
  title?: string;
  message: string;
  onRetry?: () => void;
}

export function ErrorState({ title = "Something went wrong", message, onRetry }: ErrorStateProps) {
  return (
    <div className="flex flex-col items-center justify-center p-8 bg-danger/10 border border-red-100 rounded-2xl text-center">
      <div className="w-12 h-12 bg-danger/20 text-danger rounded-full flex items-center justify-center mb-4">
        <AlertTriangle className="w-6 h-6" />
      </div>
      <h3 className="text-lg font-bold text-danger mb-2">{title}</h3>
      <p className="text-danger text-sm mb-6 max-w-md">{message}</p>
      
      {onRetry && (
        <button 
          onClick={onRetry}
          className="bg-red-600 hover:bg-red-700 text-white font-medium py-2 px-6 rounded-lg transition-colors text-sm"
        >
          Try Again
        </button>
      )}
    </div>
  );
}

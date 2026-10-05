import React from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { auth } from '../services/auth';
import { clearToken, hasToken } from '../services/token';

export default function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const navigate = useNavigate();
  const [state, setState] = useState<'checking' | 'allowed' | 'retry'>('checking');

  useEffect(() => {
    let active = true;
    if (!hasToken()) {
      navigate('/login', { replace: true });
      return () => { active = false; };
    }

    auth.me().then((user) => {
      if (!active) return;
      if (user?.role === 'user' && user.is_active !== false) {
        setState('allowed');
      } else if (user?.role === 'admin' && user.is_active !== false) {
        navigate('/admin', { replace: true });
      } else {
        clearToken();
        navigate('/login', { replace: true });
      }
    }).catch((error: { response?: { status?: number } }) => {
      if (!active) return;
      if (error.response?.status === 401 || error.response?.status === 403) {
        clearToken();
        navigate('/login', { replace: true });
      } else {
        console.error('Unable to verify user portal access', error);
        setState('retry');
      }
    });

    return () => { active = false; };
  }, [navigate]);

  if (state === 'checking') {
    return <div className="flex min-h-screen items-center justify-center bg-background text-text-muted" role="status">Verifying account access…</div>;
  }
  if (state === 'retry') {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-background p-6 text-center">
        <p className="text-text-main">Could not verify your account. Check your connection and retry.</p>
        <button type="button" onClick={() => window.location.reload()} className="rounded-lg bg-primary px-4 py-2 font-semibold text-white">
          Retry
        </button>
      </div>
    );
  }
  if (state !== 'allowed') {
    return <Navigate to="/login" />;
  }
  return children;
}

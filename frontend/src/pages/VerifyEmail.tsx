import { useEffect, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { CheckCircle, Loader2, Moon, ShieldCheck, Sun } from 'lucide-react';
import { auth } from '../services/auth';
import { hasToken } from '../services/token';
import { useTheme } from '../hooks/useTheme';

export default function VerifyEmail() {
  const location = useLocation();
  const navigate = useNavigate();
  const { theme, toggleTheme } = useTheme();
  const [challengeId, setChallengeId] = useState<string | null>(
    (location.state as { challengeId?: string | null } | null)?.challengeId ?? null,
  );
  const [code, setCode] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!hasToken()) {
      navigate('/login', { replace: true });
      return;
    }

    auth.me().then((userData) => {
      if (!userData || userData.is_active === false) {
        navigate('/login', { replace: true });
        return;
      }
      if (userData.role === 'admin') {
        navigate('/admin', { replace: true });
        return;
      }
      if (userData.email_verified) {
        navigate('/dashboard', { replace: true });
        return;
      }

      // If user is unverified and no challengeId in state, request one
      if (!challengeId) {
        auth.resendVerification().then((res) => {
          if (res.email_verified) {
            navigate('/dashboard', { replace: true });
          } else if (res.challenge_id) {
            setChallengeId(res.challenge_id);
            setMessage(res.message || 'Verification code sent to your email.');
          }
        }).catch(() => {
          // Keep screen visible so user can click send button manually
        });
      }
    }).catch(() => {
      navigate('/login', { replace: true });
    });
  }, [navigate, challengeId]);

  const handleVerify = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError('');
    setMessage('');
    if (!challengeId) {
      setError('Request a new verification code before continuing.');
      return;
    }

    setLoading(true);
    try {
      await auth.verifyEmail(challengeId, code);
      navigate('/dashboard', { replace: true });
    } catch (requestError: unknown) {
      if (axios.isAxiosError(requestError)) {
        setError(
          typeof requestError.response?.data?.detail === 'string'
            ? requestError.response.data.detail
            : 'The verification code is invalid or expired.',
        );
      } else {
        console.error('Email verification failed', requestError);
        setError('Email verification failed. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    setError('');
    setMessage('');
    setLoading(true);
    try {
      const response = await auth.resendVerification();
      if (response.email_verified) {
        navigate('/dashboard', { replace: true });
        return;
      }
      setChallengeId(response.challenge_id);
      setCode('');
      setMessage(response.message || 'A new verification code was sent to your email.');
    } catch (requestError: unknown) {
      if (axios.isAxiosError(requestError)) {
        setError(
          typeof requestError.response?.data?.detail === 'string'
            ? requestError.response.data.detail
            : 'Unable to send a new verification code.',
        );
      } else {
        console.error('Verification email resend failed', requestError);
        setError('Unable to send a new verification code. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="relative flex min-h-screen flex-col items-center justify-center bg-background px-4 py-10">
      {/* Header with Logo and Theme Toggle */}
      <header className="absolute top-0 left-0 w-full p-6 z-50 flex items-center justify-center">
        <Link 
          to="/" 
          onClick={() => window.scrollTo(0, 0)}
          className="flex flex-col items-center group w-max"
        >
          <div className="flex items-center space-x-2">
            <ShieldCheck className="w-8 h-8 text-primary transition-transform group-hover:scale-110" />
            <span className="text-xl font-bold tracking-wide flex">
              <span className="text-text-main">SCAM</span>
              <span className="text-primary">SHIELD</span>
            </span>
          </div>
          <span className="text-xs text-text-muted font-bold tracking-widest mt-1 uppercase hidden sm:block text-center">
            Detect · Verify · Stay Safe
          </span>
        </Link>
        <button
          type="button"
          onClick={toggleTheme}
          aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
          title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
          className="absolute right-5 top-5 rounded-full border border-border-light bg-card p-2.5 text-text-secondary transition-colors hover:border-primary hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary sm:right-6 sm:top-6"
        >
          {theme === 'dark' ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
        </button>
      </header>

      <section className="w-full max-w-md rounded-3xl border border-border-light bg-card p-8 sm:p-10 shadow-2xl relative z-10 mt-12">
        <div className="mb-6 flex items-center gap-3">
          <div className="rounded-2xl bg-primary/10 p-3 text-primary">
            <ShieldCheck className="h-7 w-7" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-text-main">Verify your email</h1>
            <p className="mt-1 text-sm text-text-muted">One last step to protect your account.</p>
          </div>
        </div>

        <p className="mb-5 text-sm leading-6 text-text-secondary">
          Enter the six-digit verification code sent to your email address. You must verify your email before accessing the dashboard and analysis tools.
        </p>

        {error && (
          <p className="mb-4 rounded-xl border border-danger/30 bg-danger/10 px-3.5 py-2.5 text-sm text-danger" role="alert">
            {error}
          </p>
        )}
        {message && (
          <p className="mb-4 flex items-center gap-2 rounded-xl border border-success/30 bg-success/10 px-3.5 py-2.5 text-sm text-success" role="status">
            <CheckCircle className="h-4 w-4 shrink-0" />
            {message}
          </p>
        )}

        <form onSubmit={handleVerify} className="space-y-4">
          <label htmlFor="email-verification-code" className="block text-sm font-semibold text-text-main">
            Verification code
          </label>
          <input
            id="email-verification-code"
            type="text"
            inputMode="numeric"
            autoComplete="one-time-code"
            pattern="[0-9]{6}"
            maxLength={6}
            required
            placeholder="000000"
            value={code}
            onChange={(event) => setCode(event.target.value.replace(/\D/g, '').slice(0, 6))}
            className="w-full rounded-xl border border-border-main bg-background px-4 py-3 text-center text-2xl tracking-[0.5em] text-text-main focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
          <button
            type="submit"
            disabled={loading || code.length !== 6 || !challengeId}
            className="flex w-full items-center justify-center rounded-xl bg-primary px-4 py-3 font-semibold text-white transition hover:bg-primary-hover disabled:cursor-not-allowed disabled:opacity-50"
          >
            {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : 'Verify email'}
          </button>
        </form>

        {hasToken() ? (
          <button
            type="button"
            onClick={handleResend}
            disabled={loading}
            className="mt-4 w-full text-center text-sm font-semibold text-primary hover:text-primary-hover disabled:opacity-50"
          >
            Send a new code
          </button>
        ) : (
          <p className="mt-4 text-center text-sm text-text-muted">
            <Link to="/login" className="font-semibold text-primary hover:text-primary-hover">
              Sign in
            </Link>
            {' '}to request another code.
          </p>
        )}

        <div className="mt-6 pt-5 border-t border-border-light text-center">
          <button
            type="button"
            onClick={() => {
              auth.logout();
              navigate('/login');
            }}
            className="text-xs font-semibold text-text-muted hover:text-danger transition-colors"
          >
            Sign in with a different account
          </button>
        </div>
      </section>
    </main>
  );
}

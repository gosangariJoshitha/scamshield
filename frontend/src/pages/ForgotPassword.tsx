import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { ShieldCheck, Loader2, ArrowLeft } from 'lucide-react';
import { auth } from '../services/auth';

export default function ForgotPassword() {
  const navigate = useNavigate();
  const [step, setStep] = useState<1 | 2>(1);
  const [email, setEmail] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [verificationCode, setVerificationCode] = useState('');
  const [challengeId, setChallengeId] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleRequestReset = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    
    try {
      const res = await auth.forgotPassword(email);
      setChallengeId(res.challenge_id);
      setStep(2);
      setSuccess(res.message);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'An error occurred.');
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);
    
    try {
      await auth.resetPassword({
        challenge_id: challengeId,
        code: verificationCode,
        new_password: newPassword,
      });
      setSuccess('Password successfully reset. Redirecting to login...');
      setTimeout(() => {
        navigate('/login');
      }, 2000);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to reset password.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div 
      className="min-h-screen flex flex-col font-sans relative overflow-hidden"
      style={{ 
        background: 'radial-gradient(circle at 50% 45%, rgba(37, 99, 235, 0.08), transparent 35%), #080d1c' 
      }}
    >
      <header className="absolute top-0 left-0 w-full p-6 z-50">
        <Link 
          to="/" 
          className="flex items-center space-x-2 group w-max"
        >
          <ShieldCheck className="w-8 h-8 text-primary group-hover:text-primary transition" />
          <span className="text-xl font-bold text-white tracking-wider">ScamShield</span>
        </Link>
      </header>

      <main className="flex-1 flex items-center justify-center p-4 relative z-10">
        <div 
          className="w-full max-w-[440px] bg-background rounded-2xl overflow-hidden flex flex-col transition-all duration-300"
          style={{ 
            boxShadow: '0 20px 60px rgba(0, 0, 0, 0.25)',
            border: '1px solid rgba(255,255,255,0.08)'
          }}
        >
          <div className="p-8">
            <Link to="/login" className="inline-flex items-center space-x-2 text-sm text-text-muted hover:text-white transition mb-6">
              <ArrowLeft className="w-4 h-4" />
              <span>Back to login</span>
            </Link>

            <div className="mb-8">
              <h2 className="text-2xl font-bold text-white mb-2">
                {step === 1 ? 'Reset Password' : 'Enter New Password'}
              </h2>
              <p className="text-sm text-text-muted">
                {step === 1 
                  ? 'We will email you a one-time verification code if an active account matches that address.'
                  : 'Enter the verification code from your email and choose a new password.'}
              </p>
            </div>

            {error && (
              <div className="bg-danger/10 text-danger p-3 rounded-xl mb-6 text-sm border border-danger/20 flex items-start space-x-2">
                <span className="mt-0.5">⚠</span>
                <span>{error}</span>
              </div>
            )}

            {success && (
              <div className="bg-success/100/10 text-success p-3 rounded-xl mb-6 text-sm border border-green-500/20 flex items-start space-x-2">
                <span className="mt-0.5">✓</span>
                <span>{success}</span>
              </div>
            )}

            {step === 1 ? (
              <form onSubmit={handleRequestReset} className="flex flex-col">
                <div className="mb-6">
                  <label className="block text-text-secondary mb-1.5 text-sm font-medium">Email Address</label>
                  <input 
                    type="email" 
                    placeholder="you@example.com"
                    required 
                    className="w-full px-4 h-12 bg-background border border-border-light/50 rounded-xl focus:outline-none focus:border-primary focus:ring-[3px] focus:ring-primary/20 transition-all placeholder:text-text-secondary text-white shadow-inner" 
                    value={email} 
                    onChange={e => setEmail(e.target.value)} 
                  />
                </div>
                <button 
                  type="submit" 
                  disabled={loading || !email} 
                  className="w-full h-12 bg-primary hover:bg-primary text-white font-bold rounded-xl shadow-[0_0_20px_rgba(37,99,235,0.2)] transition-all disabled:opacity-50 flex items-center justify-center"
                >
                  {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Send reset code'}
                </button>
              </form>
            ) : (
              <form onSubmit={handleResetPassword} className="flex flex-col">
                <div className="mb-5">
                  <label className="mb-1.5 block text-sm font-medium text-text-secondary">Email verification code</label>
                  <input
                    type="text"
                    inputMode="numeric"
                    autoComplete="one-time-code"
                    pattern="[0-9]{6}"
                    maxLength={6}
                    required
                    className="h-12 w-full rounded-xl border border-border-light/50 bg-background px-4 text-center text-lg tracking-[0.4em] text-white shadow-inner focus:border-primary focus:outline-none focus:ring-[3px] focus:ring-primary/20"
                    value={verificationCode}
                    onChange={(event) => setVerificationCode(event.target.value.replace(/\D/g, '').slice(0, 6))}
                  />
                </div>
                <div className="mb-6">
                  <label className="block text-text-secondary mb-1.5 text-sm font-medium">New Password</label>
                  <input 
                    type="password" 
                    placeholder="8+ characters, uppercase letter and number"
                    required 
                    className="w-full px-4 h-12 bg-background border border-border-light/50 rounded-xl focus:outline-none focus:border-primary focus:ring-[3px] focus:ring-primary/20 transition-all placeholder:text-text-secondary text-white shadow-inner" 
                    value={newPassword} 
                    onChange={e => setNewPassword(e.target.value)} 
                  />
                </div>
                <button 
                  type="submit" 
                  disabled={loading || verificationCode.length !== 6 || newPassword.length < 8}
                  className="w-full h-12 bg-primary hover:bg-primary text-white font-bold rounded-xl shadow-[0_0_20px_rgba(37,99,235,0.2)] transition-all disabled:opacity-50 flex items-center justify-center"
                >
                  {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Update Password'}
                </button>
              </form>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

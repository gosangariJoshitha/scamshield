import React, { useEffect, useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import axios from 'axios';
import { auth } from '../services/auth';
import { hasToken, storeToken } from '../services/token';
import { ShieldCheck, Eye, EyeOff, Loader2, Check, Lock, Moon, Sun } from 'lucide-react';
import { useTheme } from '../hooks/useTheme';

interface AuthPageProps {
  initialMode: 'login' | 'signup';
  adminOnly?: boolean;
}

export default function AuthPage({ initialMode, adminOnly = false }: AuthPageProps) {
  const navigate = useNavigate();
  const { theme, toggleTheme } = useTheme();
  const [mode, setMode] = useState<'login' | 'signup'>(initialMode);
  // Form states
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [rememberMe, setRememberMe] = useState(false);
  const [agreedToTerms, setAgreedToTerms] = useState(false);
  const [challengeId, setChallengeId] = useState('');
  const [verificationCode, setVerificationCode] = useState('');
  
  // UI states
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (hasToken()) {
      auth.me().then((userData) => {
        if (!userData || userData.is_active === false) return;
        if (userData.role === 'admin') {
          navigate('/admin', { replace: true });
        } else if (userData.role === 'user') {
          if (userData.email_verified === false) {
            navigate('/verify-email', { replace: true });
          } else {
            navigate('/dashboard', { replace: true });
          }
        }
      }).catch(() => {
        // Token invalid, stay on auth page
      });
    }
  }, [navigate]);

  const toggleMode = (newMode: 'login' | 'signup') => {
    if (newMode === mode) return;
    setMode(newMode);
    setError('');
    navigate(`/${newMode}`, { replace: true });
  };

  // Password validation
  const hasMinLength = password.length >= 8;
  const hasUppercase = /[A-Z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const passwordFitsBcrypt = new TextEncoder().encode(password).length <= 72;
  const isPasswordValid = hasMinLength && hasUppercase && hasNumber && passwordFitsBcrypt;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (mode === 'signup') {
      if (!fullName.trim()) {
        setError('Please enter your full name.');
        return;
      }
      if (!isPasswordValid) {
        setError('Please meet all password requirements.');
        return;
      }
      if (password !== confirmPassword) {
        setError('Passwords do not match.');
        return;
      }
      if (!agreedToTerms) {
        setError('You must agree to the Terms of Service and Privacy Policy.');
        return;
      }
    }

    setLoading(true);
    let tokenStored = false;
    
    try {
      let signupData: Awaited<ReturnType<typeof auth.signup>> | undefined;
      if (mode === 'signup') {
        signupData = await auth.signup({
          email: email.trim(),
          password,
          full_name: fullName.trim(),
        });
      }

      if (mode === 'signup' || mode === 'login') {
        const loginData = await auth.login(
          { email: email.trim(), password },
          adminOnly ? 'admin' : 'user',
          rememberMe,
        );
        if (loginData.requires_two_factor) {
          if (!loginData.challenge_id) {
            throw new Error('The verification challenge was not returned.');
          }
          setChallengeId(loginData.challenge_id);
          return;
        }
        if (!loginData.access_token) {
          throw new Error('The authentication service returned no access token.');
        }
        storeToken(loginData.access_token, rememberMe);
        tokenStored = true;
        const userData = await auth.me();
        if (!userData || userData.is_active === false) {
          auth.logout();
          tokenStored = false;
          setError('Unable to access account. Please check your credentials.');
          return;
        }
        if (adminOnly && userData.role !== 'admin') {
          auth.logout();
          tokenStored = false;
          setError('This account does not have administrator privileges.');
          return;
        }
        if (!adminOnly && userData.role !== 'user' && userData.role !== 'admin') {
          auth.logout();
          tokenStored = false;
          setError('This account cannot sign in to the user portal.');
          return;
        }

        if (userData.role === 'admin') {
          navigate('/admin');
        } else if (userData.email_verified === false) {
          navigate('/verify-email', {
            state: { challengeId: signupData?.verification_challenge_id || null },
          });
        } else {
          navigate('/dashboard');
        }
      }
    } catch (err: unknown) {
      if (tokenStored) auth.logout();
      if (axios.isAxiosError(err)) {
        const status = err.response?.status;
        if (status === 401) {
          setError('Invalid email or password, or this account is not allowed in this portal.');
        } else if (status === 409) {
          setError('An account with this email already exists. Try signing in instead.');
        } else if (status && status >= 500) {
          setError(`The authentication service failed (HTTP ${status}). Please try again shortly.`);
        } else if (!err.response) {
          setError('Could not reach the authentication service. Check your connection and try again.');
        } else {
          const detail = err.response.data?.detail;
          if (typeof detail === 'string') {
            setError(detail);
          } else if (Array.isArray(detail)) {
            setError(
              detail
                .map((item: { msg?: unknown }) => item.msg)
                .filter((message): message is string => typeof message === 'string')
                .join(' '),
            );
          } else {
            setError('Please check the form and try again.');
          }
        }
      } else {
        console.error('Authentication failed', err);
        setError('An unexpected authentication error occurred. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyTwoFactor = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError('');
    setLoading(true);
    let tokenStored = false;
    try {
      const loginData = await auth.verifyLogin(challengeId, verificationCode, rememberMe);
      storeToken(loginData.access_token, rememberMe);
      tokenStored = true;
      const userData = await auth.me();
      if (!userData || userData.is_active === false) {
        auth.logout();
        setError('Unable to access account.');
        return;
      }
      if (adminOnly && userData.role !== 'admin') {
        auth.logout();
        setError('This account does not have administrator privileges.');
        return;
      }
      if (userData.role === 'admin') {
        navigate('/admin');
      } else if (userData.email_verified === false) {
        navigate('/verify-email');
      } else {
        navigate('/dashboard');
      }
    } catch (err: unknown) {
      if (tokenStored) auth.logout();
      if (axios.isAxiosError(err)) {
        const detail = err.response?.data?.detail;
        setError(typeof detail === 'string' ? detail : 'The verification code is invalid or expired.');
      } else {
        console.error('Two-step verification failed', err);
        setError('Could not verify this sign-in. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page min-h-screen flex flex-col font-sans relative overflow-hidden bg-background">
      {/* Header with Logo */}
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

      {/* Main Authentication Area */}
      <main className="flex-1 flex items-center justify-center p-4 relative z-10 pt-28 pb-12">
        <div className="w-full max-w-[440px] bg-card rounded-3xl flex flex-col transition-all duration-300 shadow-2xl border border-border-light relative overflow-hidden">
          
          {/* Subtle cyan ambient glow behind the card (pseudo-element effect achieved by a div behind it if needed, but keeping it clean here) */}
          
          {/* Sliding Toggle */}
          {!adminOnly && (
            <div className="p-3 border-b border-border-light bg-background">
              <div className="relative flex bg-slate-200/50 rounded-lg p-1 border border-border-light/50">
                <div
                  className="absolute top-1 bottom-1 w-[calc(50%-4px)] bg-card shadow-sm border border-border-main/60 rounded-md transition-transform duration-300 ease-out"
                  style={{
                    transform: mode === 'login' ? 'translateX(0)' : 'translateX(100%)',
                  }}
                />
                <button
                  type="button"
                  onClick={() => toggleMode('login')}
                  className={`flex-1 py-2 text-sm font-semibold rounded-md relative z-10 transition-colors duration-300 ${
                    mode === 'login' ? 'text-primary' : 'text-text-muted hover:text-text-main'
                  }`}
                >
                  Login
                </button>
                <button
                  type="button"
                  onClick={() => toggleMode('signup')}
                  className={`flex-1 py-2 text-sm font-semibold rounded-md relative z-10 transition-colors duration-300 ${
                    mode === 'signup' ? 'text-primary' : 'text-text-muted hover:text-text-main'
                  }`}
                >
                  Sign Up
                </button>
              </div>
            </div>
          )}

          <div className="p-8 sm:p-10">
            <div className="text-center mb-8">
              <h2 className="text-2xl font-bold text-text-main mb-2">
                {adminOnly ? 'Admin sign in' : mode === 'login' ? 'Welcome back' : 'Create your account'}
              </h2>
              <p className="text-sm text-text-muted">
                {adminOnly
                  ? 'Sign in with an administrator account to continue.'
                  : mode === 'login'
                  ? 'Sign in to your ScamShield account.' 
                  : 'Start analyzing suspicious content.'}
              </p>
            </div>

            {error && (
              <div role="alert" className="bg-danger/10 text-danger p-3 rounded-xl mb-6 text-sm border border-danger/20 flex items-start space-x-2">
                <span className="mt-0.5 font-bold">!</span>
                <span className="font-medium">{error}</span>
              </div>
            )}

            {challengeId ? (
              <form onSubmit={handleVerifyTwoFactor} className="flex flex-col">
                <div className="mb-5">
                  <h3 className="font-semibold text-text-main">Check your email</h3>
                  <p className="mt-1 text-sm text-text-muted">
                    Enter the 6-digit verification code sent to {email}.
                  </p>
                </div>
                <label htmlFor="login-verification-code" className="mb-1.5 text-sm font-medium text-text-main">
                  Verification code
                </label>
                <input
                  id="login-verification-code"
                  type="text"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  pattern="[0-9]{6}"
                  maxLength={6}
                  required
                  value={verificationCode}
                  onChange={(event) => setVerificationCode(event.target.value.replace(/\D/g, '').slice(0, 6))}
                  className="mb-5 h-11 rounded-xl border border-border-main bg-card px-4 text-center text-lg tracking-[0.4em] text-text-main focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
                <button
                  type="submit"
                  disabled={loading || verificationCode.length !== 6}
                  className="h-11 rounded-xl bg-primary font-semibold text-white transition-colors hover:bg-primary-hover disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {loading ? <Loader2 className="mx-auto h-5 w-5 animate-spin" /> : 'Verify and sign in'}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setChallengeId('');
                    setVerificationCode('');
                    setError('');
                  }}
                  className="mt-3 text-sm font-semibold text-primary hover:text-primary-hover"
                >
                  Use a different account
                </button>
              </form>
            ) : (
            <form onSubmit={handleSubmit} className="flex flex-col">
              {/* Full Name - Only for Signup */}
              {!adminOnly && <div hidden={mode !== 'signup'} className={`overflow-hidden transition-all duration-300 ${mode === 'signup' ? 'max-h-24 opacity-100 mb-5' : 'max-h-0 opacity-0 mb-0'}`}>
                <label className="block text-text-main mb-1.5 text-sm font-medium">Full Name</label>
                <input 
                  type="text" 
                  placeholder="John Doe"
                  required={mode === 'signup'} 
                  className="w-full px-4 h-11 bg-card border border-border-main rounded-xl focus:outline-none focus:border-primary focus:ring-[3px] focus:ring-primary/20 transition-all placeholder:text-text-muted text-text-main" 
                  value={fullName} 
                  onChange={e => setFullName(e.target.value)} 
                  autoComplete="name"
                />
              </div>}

              {/* Email */}
              <div className="mb-5">
                <label className="block text-text-main mb-1.5 text-sm font-medium">Email</label>
                <input 
                  type="email" 
                  placeholder="you@example.com"
                  required 
                  className="w-full px-4 h-11 bg-card border border-border-main rounded-xl focus:outline-none focus:border-primary focus:ring-[3px] focus:ring-primary/20 transition-all placeholder:text-text-muted text-text-main" 
                  value={email} 
                  onChange={e => setEmail(e.target.value)} 
                  autoComplete="email"
                />
              </div>

              {/* Password */}
              <div className="mb-1">
                <label className="block text-text-main mb-1.5 text-sm font-medium">Password</label>
                <div className="relative">
                  <input 
                    type={showPassword ? "text" : "password"} 
                    placeholder={mode === 'signup' ? "At least 8 characters" : "Enter your password"}
                    required 
                    className="w-full pl-4 pr-12 h-11 bg-card border border-border-main rounded-xl focus:outline-none focus:border-primary focus:ring-[3px] focus:ring-primary/20 transition-all placeholder:text-text-muted text-text-main" 
                    value={password} 
                    onChange={e => setPassword(e.target.value)} 
                    autoComplete={mode === 'signup' ? 'new-password' : 'current-password'}
                  />
                  <button 
                    type="button" 
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-main focus:outline-none"
                    title={showPassword ? "Hide password" : "Show password"}
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              {/* Password Validation Feedback - Only for Signup */}
              {!adminOnly && <div hidden={mode !== 'signup'} className={`overflow-hidden transition-all duration-300 ${mode === 'signup' ? 'max-h-32 opacity-100 mb-5 mt-2' : 'max-h-0 opacity-0 mb-0'}`}>
                {isPasswordValid && password.length > 0 ? (
                  <div className="text-xs text-success flex items-center space-x-1 font-medium">
                    <Check className="w-3.5 h-3.5" />
                    <span>Strong password</span>
                  </div>
                ) : password.length > 0 ? (
                  <div className="text-xs text-text-secondary space-y-1.5">
                    <p className="font-medium text-text-main mb-1">Password must contain:</p>
                    <div className={`flex items-center space-x-1 ${hasMinLength ? 'text-success font-medium' : ''}`}>
                      {hasMinLength ? <Check className="w-3.5 h-3.5" /> : <span className="w-3.5 h-3.5 inline-block" />} 
                      <span>8+ characters</span>
                    </div>
                    <div className={`flex items-center space-x-1 ${hasUppercase ? 'text-success font-medium' : ''}`}>
                      {hasUppercase ? <Check className="w-3.5 h-3.5" /> : <span className="w-3.5 h-3.5 inline-block" />} 
                      <span>One uppercase letter</span>
                    </div>
                    <div className={`flex items-center space-x-1 ${hasNumber ? 'text-success font-medium' : ''}`}>
                      {hasNumber ? <Check className="w-3.5 h-3.5" /> : <span className="w-3.5 h-3.5 inline-block" />} 
                      <span>One number</span>
                    </div>
                    <div className={`flex items-center space-x-1 ${passwordFitsBcrypt ? 'text-success font-medium' : 'text-danger'}`}>
                      {passwordFitsBcrypt ? <Check className="w-3.5 h-3.5" /> : <span className="w-3.5 h-3.5 inline-block" />}
                      <span>At most 72 UTF-8 bytes</span>
                    </div>
                  </div>
                ) : (
                  <div className="h-0" />
                )}
              </div>}

              {/* Remember Me / Forgot Password - Only for Login */}
              {mode === 'login' && (
                <div className="mb-6 mt-4 flex items-center justify-between">
                  <label className="flex items-center space-x-2 cursor-pointer group">
                    <div className="relative flex items-center justify-center">
                      <input 
                        type="checkbox" 
                        checked={rememberMe}
                        onChange={(e) => setRememberMe(e.target.checked)}
                        className="peer appearance-none w-4 h-4 border border-border-main rounded bg-card checked:bg-primary checked:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 transition-colors"
                      />
                      <Check className="w-3 h-3 text-white absolute pointer-events-none opacity-0 peer-checked:opacity-100" />
                    </div>
                    <span className="text-sm font-medium text-text-secondary group-hover:text-text-main transition-colors">Remember me</span>
                  </label>
                  
                  {!adminOnly && (
                    <Link to="/forgot-password" className="text-sm font-medium text-primary hover:text-primary-hover">
                      Forgot password?
                    </Link>
                  )}
                </div>
              )}

              {/* Confirm Password - Only for Signup */}
              {!adminOnly && <div hidden={mode !== 'signup'} className={`overflow-hidden transition-all duration-300 ${mode === 'signup' ? 'max-h-24 opacity-100 mb-5' : 'max-h-0 opacity-0 mb-0'}`}>
                <label className="block text-text-main mb-1.5 text-sm font-medium">Confirm Password</label>
                <input 
                  type={showPassword ? "text" : "password"} 
                  placeholder=""
                  required={mode === 'signup'} 
                  className="w-full px-4 h-11 bg-card border border-border-main rounded-xl focus:outline-none focus:border-primary focus:ring-[3px] focus:ring-primary/20 transition-all text-text-main" 
                  value={confirmPassword} 
                  onChange={e => setConfirmPassword(e.target.value)} 
                  autoComplete="new-password"
                />
              </div>}

              {/* Terms - Only for Signup */}
              {!adminOnly && <div hidden={mode !== 'signup'} className={`overflow-hidden transition-all duration-300 ${mode === 'signup' ? 'max-h-12 opacity-100 mb-6 mt-1' : 'max-h-0 opacity-0 mb-0'}`}>
                <label className="flex items-start space-x-2 cursor-pointer group">
                  <div className="relative flex items-center justify-center mt-0.5 shrink-0">
                    <input 
                      type="checkbox" 
                      required={mode === 'signup'}
                      checked={agreedToTerms}
                      onChange={(e) => setAgreedToTerms(e.target.checked)}
                      className="peer appearance-none w-4 h-4 border border-border-main rounded bg-card checked:bg-primary checked:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 transition-colors"
                    />
                    <Check className="w-3 h-3 text-white absolute pointer-events-none opacity-0 peer-checked:opacity-100" />
                  </div>
                  <span className="text-xs text-text-secondary group-hover:text-text-main transition-colors leading-relaxed font-medium">
                    I agree to the <Link to="/terms" className="text-primary hover:underline">Terms of Service</Link> and <Link to="/privacy" className="text-primary hover:underline">Privacy Policy</Link>.
                  </span>
                </label>
              </div>}

              {/* Action Button */}
              <button 
                type="submit" 
                disabled={loading || (mode === 'signup' && (!isPasswordValid || !agreedToTerms))} 
                className="w-full h-11 bg-primary hover:bg-primary-hover text-white font-semibold rounded-xl transition-all disabled:opacity-50 disabled:hover:bg-primary disabled:cursor-not-allowed flex items-center justify-center"
              >
                {loading ? (
                  <div className="flex items-center space-x-2">
                    <Loader2 className="w-5 h-5 animate-spin" />
                    <span>{mode === 'login' ? 'Signing in...' : 'Creating account...'}</span>
                  </div>
                ) : (
                  mode === 'login' ? 'Login' : 'Create Account'
                )}
              </button>
            </form>
            )}

            {!challengeId && !adminOnly && <div className="mt-8 text-center text-sm font-medium">
              <span className="text-text-secondary">
                {mode === 'login' ? "Don't have an account? " : "Already have an account? "}
              </span>
              <button 
                type="button"
                onClick={() => toggleMode(mode === 'login' ? 'signup' : 'login')} 
                className="text-primary hover:text-primary-hover font-semibold focus:outline-none transition-colors"
              >
                {mode === 'login' ? "Sign up" : "Log in"}
              </button>
            </div>}

            {!challengeId && !adminOnly && (
              <div className="mt-4 text-center text-sm font-medium text-text-secondary">
                Not a user? <Link to="/admin/login" className="font-semibold text-primary hover:text-primary-hover">Admin sign in</Link>
              </div>
            )}

            {challengeId && !adminOnly && (
              <div className="mt-5 text-center text-sm">
                <Link to="/admin/login" className="font-semibold text-primary hover:text-primary-hover">Admin sign in</Link>
              </div>
            )}

            {!challengeId && adminOnly && (
              <div className="mt-8 text-center text-sm font-medium text-text-secondary">
                Not an administrator? <Link to="/login" className="font-semibold text-primary hover:text-primary-hover">Go to user login</Link>
              </div>
            )}
            
            {/* Security Reassurance */}
            <div className="mt-6 pt-6 border-t border-border-light flex items-center justify-center space-x-1.5 text-xs font-medium text-text-muted">
              <Lock className="w-3.5 h-3.5" />
              <span>Secure authentication</span>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

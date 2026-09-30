import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { auth } from '../services/auth';
import { ShieldCheck, Eye, EyeOff, Loader2, Check } from 'lucide-react';

interface AuthPageProps {
  initialMode: 'login' | 'signup';
}

export default function AuthPage({ initialMode }: AuthPageProps) {
  const navigate = useNavigate();
  const [mode, setMode] = useState<'login' | 'signup'>(initialMode);
  
  // Sync mode with prop changes (when URL changes)
  useEffect(() => {
    setMode(initialMode);
    setError('');
  }, [initialMode]);

  // Form states
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [rememberMe, setRememberMe] = useState(false);
  const [agreedToTerms, setAgreedToTerms] = useState(false);
  
  // UI states
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

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
  const isPasswordValid = hasMinLength && hasUppercase && hasNumber;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (mode === 'signup') {
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
    
    try {
      if (mode === 'signup') {
        await auth.signup({ email, password, full_name: fullName, confirm_password: confirmPassword });
        const loginData = await auth.login({ email, password });
        localStorage.setItem('token', loginData.access_token);
        navigate('/dashboard');
      } else {
        const data = await auth.login({ email, password });
        localStorage.setItem('token', data.access_token);
        navigate('/dashboard');
      }
    } catch (err: any) {
      if (err.response?.status === 401 || err.response?.status === 400) {
        // Generic error for login failure
        setError(mode === 'login' ? 'Incorrect email or password.' : 'Failed to create account. Email may already be in use.');
      } else if (err.message) {
        setError(err.message);
      } else {
        setError('An unexpected error occurred.');
      }
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
      {/* Minimal Header */}
      <header className="absolute top-0 left-0 w-full p-6 z-50">
        <Link 
          to="/" 
          onClick={() => window.scrollTo(0, 0)}
          className="flex items-center space-x-2 group w-max"
        >
          <ShieldCheck className="w-8 h-8 text-blue-500 group-hover:text-blue-400 transition" />
          <span className="text-xl font-bold text-white tracking-wider">ScamShield</span>
        </Link>
      </header>

      {/* Main Authentication Area */}
      <main className="flex-1 flex items-center justify-center p-4 relative z-10 pt-20 pb-12">
        <div 
          className="w-full max-w-[440px] bg-[#0d1326] rounded-2xl overflow-hidden flex flex-col transition-all duration-300"
          style={{ 
            boxShadow: '0 20px 60px rgba(0, 0, 0, 0.25)',
            border: '1px solid rgba(255,255,255,0.08)'
          }}
        >
          {/* Sliding Toggle */}
          <div className="p-2 border-b border-white/5 bg-[#0a0f1c]">
            <div className="relative flex bg-[#111827] rounded-lg p-1 border border-white/5">
              {/* Sliding Background Pill */}
              <div 
                className="absolute top-1 bottom-1 w-[calc(50%-4px)] bg-[#1e293b] border border-white/10 rounded-md transition-transform duration-300 ease-out shadow-sm"
                style={{
                  transform: mode === 'login' ? 'translateX(0)' : 'translateX(100%)',
                }}
              />
              <button
                type="button"
                onClick={() => toggleMode('login')}
                className={`flex-1 py-2 text-sm font-bold rounded-md relative z-10 transition-colors duration-300 ${
                  mode === 'login' ? 'text-white' : 'text-slate-500 hover:text-slate-300'
                }`}
              >
                Login
              </button>
              <button
                type="button"
                onClick={() => toggleMode('signup')}
                className={`flex-1 py-2 text-sm font-bold rounded-md relative z-10 transition-colors duration-300 ${
                  mode === 'signup' ? 'text-white' : 'text-slate-500 hover:text-slate-300'
                }`}
              >
                Sign Up
              </button>
            </div>
          </div>

          <div className="p-8">
            <div className="text-center mb-8">
              <h2 className="text-2xl font-bold text-white mb-2">
                {mode === 'login' ? 'Welcome back' : 'Create your account'}
              </h2>
              <p className="text-sm text-slate-400">
                {mode === 'login' 
                  ? 'Sign in to your ScamShield account.' 
                  : 'Start analyzing suspicious content.'}
              </p>
            </div>

            {error && (
              <div className="bg-red-500/10 text-red-400 p-3 rounded-xl mb-6 text-sm border border-red-500/20 flex items-start space-x-2">
                <span className="mt-0.5">⚠</span>
                <span>{error}</span>
              </div>
            )}

            <form onSubmit={handleSubmit} className="flex flex-col">
              {/* Full Name - Only for Signup */}
              <div className={`overflow-hidden transition-all duration-300 ${mode === 'signup' ? 'max-h-24 opacity-100 mb-5' : 'max-h-0 opacity-0 mb-0'}`}>
                <label className="block text-slate-300 mb-1.5 text-sm font-medium">Full Name</label>
                <input 
                  type="text" 
                  placeholder="John Doe"
                  required={mode === 'signup'} 
                  className="w-full px-4 h-12 bg-[#0a0f1c] border border-slate-700/50 rounded-xl focus:outline-none focus:border-blue-500 focus:ring-[3px] focus:ring-blue-500/20 transition-all placeholder:text-slate-600 text-white shadow-inner" 
                  value={fullName} 
                  onChange={e => setFullName(e.target.value)} 
                  autoComplete="name"
                />
              </div>

              {/* Email */}
              <div className="mb-5">
                <label className="block text-slate-300 mb-1.5 text-sm font-medium">Email</label>
                <input 
                  type="email" 
                  placeholder="you@example.com"
                  required 
                  className="w-full px-4 h-12 bg-[#0a0f1c] border border-slate-700/50 rounded-xl focus:outline-none focus:border-blue-500 focus:ring-[3px] focus:ring-blue-500/20 transition-all placeholder:text-slate-600 text-white shadow-inner" 
                  value={email} 
                  onChange={e => setEmail(e.target.value)} 
                  autoComplete="email"
                />
              </div>

              {/* Password */}
              <div className="mb-1">
                <label className="block text-slate-300 mb-1.5 text-sm font-medium">Password</label>
                <div className="relative">
                  <input 
                    type={showPassword ? "text" : "password"} 
                    placeholder={mode === 'signup' ? "At least 8 characters" : "Enter your password"}
                    required 
                    className="w-full pl-4 pr-12 h-12 bg-[#0a0f1c] border border-slate-700/50 rounded-xl focus:outline-none focus:border-blue-500 focus:ring-[3px] focus:ring-blue-500/20 transition-all placeholder:text-slate-600 text-white shadow-inner" 
                    value={password} 
                    onChange={e => setPassword(e.target.value)} 
                    autoComplete={mode === 'signup' ? 'new-password' : 'current-password'}
                  />
                  <button 
                    type="button" 
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 focus:outline-none"
                    title={showPassword ? "Hide password" : "Show password"}
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              {/* Password Validation Feedback - Only for Signup */}
              <div className={`overflow-hidden transition-all duration-300 ${mode === 'signup' ? 'max-h-32 opacity-100 mb-5 mt-2' : 'max-h-0 opacity-0 mb-0'}`}>
                {isPasswordValid && password.length > 0 ? (
                  <div className="text-xs text-green-400 flex items-center space-x-1">
                    <Check className="w-3.5 h-3.5" />
                    <span>Strong password</span>
                  </div>
                ) : password.length > 0 ? (
                  <div className="text-xs text-slate-400 space-y-1">
                    <p className="font-medium text-slate-300 mb-1">Password must contain:</p>
                    <div className={`flex items-center space-x-1 ${hasMinLength ? 'text-green-400' : ''}`}>
                      {hasMinLength ? <Check className="w-3 h-3" /> : <span className="w-3 h-3 inline-block" />} 
                      <span>8+ characters</span>
                    </div>
                    <div className={`flex items-center space-x-1 ${hasUppercase ? 'text-green-400' : ''}`}>
                      {hasUppercase ? <Check className="w-3 h-3" /> : <span className="w-3 h-3 inline-block" />} 
                      <span>One uppercase letter</span>
                    </div>
                    <div className={`flex items-center space-x-1 ${hasNumber ? 'text-green-400' : ''}`}>
                      {hasNumber ? <Check className="w-3 h-3" /> : <span className="w-3 h-3 inline-block" />} 
                      <span>One number</span>
                    </div>
                  </div>
                ) : (
                  <div className="h-0" />
                )}
              </div>

              {/* Remember Me / Forgot Password - Only for Login */}
              <div className={`overflow-hidden transition-all duration-300 ${mode === 'login' ? 'max-h-12 opacity-100 mb-6 mt-4' : 'max-h-0 opacity-0 mb-0'}`}>
                <div className="flex items-center justify-between">
                  <label className="flex items-center space-x-2 cursor-pointer group">
                    <div className="relative flex items-center justify-center">
                      <input 
                        type="checkbox" 
                        checked={rememberMe}
                        onChange={(e) => setRememberMe(e.target.checked)}
                        className="peer appearance-none w-4 h-4 border border-slate-600 rounded bg-[#0a0f1c] checked:bg-blue-600 checked:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition-colors"
                      />
                      <Check className="w-3 h-3 text-white absolute pointer-events-none opacity-0 peer-checked:opacity-100" />
                    </div>
                    <span className="text-sm text-slate-400 group-hover:text-slate-300 transition-colors">Remember me</span>
                  </label>
                  
                  <Link to="/forgot-password" className="text-sm text-blue-500 hover:text-blue-400 transition-colors">
                    Forgot password?
                  </Link>
                </div>
              </div>

              {/* Confirm Password - Only for Signup */}
              <div className={`overflow-hidden transition-all duration-300 ${mode === 'signup' ? 'max-h-24 opacity-100 mb-5' : 'max-h-0 opacity-0 mb-0'}`}>
                <label className="block text-slate-300 mb-1.5 text-sm font-medium">Confirm Password</label>
                <input 
                  type={showPassword ? "text" : "password"} 
                  placeholder=""
                  required={mode === 'signup'} 
                  className="w-full px-4 h-12 bg-[#0a0f1c] border border-slate-700/50 rounded-xl focus:outline-none focus:border-blue-500 focus:ring-[3px] focus:ring-blue-500/20 transition-all text-white shadow-inner" 
                  value={confirmPassword} 
                  onChange={e => setConfirmPassword(e.target.value)} 
                  autoComplete="new-password"
                />
              </div>

              {/* Terms - Only for Signup */}
              <div className={`overflow-hidden transition-all duration-300 ${mode === 'signup' ? 'max-h-12 opacity-100 mb-6 mt-1' : 'max-h-0 opacity-0 mb-0'}`}>
                <label className="flex items-start space-x-2 cursor-pointer group">
                  <div className="relative flex items-center justify-center mt-0.5 shrink-0">
                    <input 
                      type="checkbox" 
                      required={mode === 'signup'}
                      checked={agreedToTerms}
                      onChange={(e) => setAgreedToTerms(e.target.checked)}
                      className="peer appearance-none w-4 h-4 border border-slate-600 rounded bg-[#0a0f1c] checked:bg-blue-600 checked:border-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition-colors"
                    />
                    <Check className="w-3 h-3 text-white absolute pointer-events-none opacity-0 peer-checked:opacity-100" />
                  </div>
                  <span className="text-xs text-slate-400 group-hover:text-slate-300 transition-colors leading-relaxed">
                    I agree to the <a href="#" className="text-blue-500 hover:underline">Terms of Service</a> and <a href="#" className="text-blue-500 hover:underline">Privacy Policy</a>.
                  </span>
                </label>
              </div>

              {/* Action Button */}
              <button 
                type="submit" 
                disabled={loading || (mode === 'signup' && (!isPasswordValid || !agreedToTerms))} 
                className="w-full h-12 bg-blue-600 hover:bg-blue-500 text-white font-bold rounded-xl shadow-[0_0_20px_rgba(37,99,235,0.2)] transition-all disabled:opacity-50 disabled:hover:bg-blue-600 disabled:cursor-not-allowed flex items-center justify-center"
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

            <div className="mt-8 text-center text-sm">
              <span className="text-slate-400">
                {mode === 'login' ? "Don't have an account? " : "Already have an account? "}
              </span>
              <button 
                type="button"
                onClick={() => toggleMode(mode === 'login' ? 'signup' : 'login')} 
                className="text-white hover:text-blue-400 font-bold hover:underline focus:outline-none transition-colors"
              >
                {mode === 'login' ? "Sign up" : "Log in"}
              </button>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

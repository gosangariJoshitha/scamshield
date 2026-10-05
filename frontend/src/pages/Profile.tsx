import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  User, Shield, Calendar, Activity, ArrowRight,
  CheckCircle, FileText, AlertTriangle, ChevronRight
} from 'lucide-react';
import { auth } from '../services/auth';
import { dashboardService, type DashboardStats } from '../services/dashboard';

export default function Profile() {
  const [user, setUser] = useState<any>(null);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchProfileData = async () => {
      try {
        const userData = await auth.me();
        setUser(userData);
        
        // Fetch stats for the activity summary
        const statsData = await dashboardService.getStats().catch(() => null);
        if (statsData) setStats(statsData);
      } catch {
        auth.logout();
        navigate('/login');
      } finally {
        setLoading(false);
      }
    };
    
    fetchProfileData();
  }, [navigate]);

  if (loading || !user) {
    return (
      <div className="space-y-6">
        <div className="mb-8">
          <div className="h-8 bg-slate-200 rounded w-48 mb-2 animate-pulse"></div>
          <div className="h-4 bg-slate-200 rounded w-64 animate-pulse"></div>
        </div>
        <div className="bg-card rounded-2xl shadow-sm border border-border-light h-64 animate-pulse"></div>
      </div>
    );
  }

  const initials = user?.full_name 
    ? user.full_name.split(' ').map((n: string) => n[0]).join('').substring(0, 2).toUpperCase()
    : 'U';

  const memberSince = new Date(user.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex flex-col @content-sm:flex-row @content-sm:items-end justify-between gap-4 mb-2">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-2">My Profile</h1>
          <p className="text-text-muted text-base">Your account at a glance.</p>
        </div>
      </div>

      {/* Profile Hero Card */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden relative">
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary to-purple-500"></div>
        <div className="p-8 flex flex-col @content-sm:flex-row items-center @content-sm:items-start space-y-4 @content-sm:space-y-0 @content-sm:space-x-6">
          <div className="shrink-0">
            <div className="w-20 h-20 bg-primary/10 text-primary rounded-full flex items-center justify-center text-3xl font-bold border border-primary/20">
              {initials}
            </div>
          </div>
          <div className="flex-1 text-center @content-sm:text-left min-w-0">
            <div className="flex flex-col @content-sm:flex-row @content-sm:items-center @content-sm:space-x-3 mb-2 gap-y-2">
              <h2 className="text-2xl font-bold text-text-main truncate">{user.full_name}</h2>
              {user.is_active && (
                <span className="inline-flex items-center text-[10px] font-bold px-2 py-0.5 rounded-full bg-success/20 text-success uppercase tracking-wider mx-auto @content-sm:mx-0">
                  <span className="w-1.5 h-1.5 rounded-full bg-success mr-1.5 animate-pulse"></span>
                  Active
                </span>
              )}
            </div>
            <div className="space-y-1 mt-3">
              <div className="flex items-center justify-center @content-sm:justify-start space-x-2 text-sm text-text-secondary">
                <User className="w-4 h-4 text-text-muted shrink-0" />
                <span className="capitalize">{user.role}</span>
              </div>
              <div className="flex items-center justify-center @content-sm:justify-start space-x-2 text-sm text-text-secondary">
                <Shield className="w-4 h-4 text-text-muted shrink-0" />
                <span className="truncate">{user.email}</span>
              </div>
              <div className="flex items-center justify-center @content-sm:justify-start space-x-2 text-sm text-text-secondary">
                <Calendar className="w-4 h-4 text-text-muted shrink-0" />
                <span>Member since {memberSince}</span>
              </div>
            </div>
          </div>
          
          <div className="shrink-0 pt-2 @content-sm:pt-0">
            <button onClick={() => navigate('/profile/settings', { state: { tab: 'account', openEditModal: true } })} className="border border-border-main hover:bg-background text-text-main font-bold py-2 px-6 rounded-xl transition text-sm flex items-center space-x-2 shadow-sm">
              <span>Edit Profile</span>
            </button>
          </div>
        </div>
      </div>

      {/* Activity Summary */}
      <div className="space-y-4 pt-2">
        <h3 className="text-lg font-bold text-text-main">Your Activity</h3>
        <div className="grid grid-cols-2 @content-md:grid-cols-4 gap-4">
          <div className="bg-card border border-border-light rounded-xl p-5 shadow-sm text-center">
            <div className="flex justify-center mb-2"><FileText className="w-5 h-5 text-primary" /></div>
            <div className="text-3xl font-bold text-text-main leading-none mb-1">{stats?.total_analyses ?? '—'}</div>
            <div className="text-xs text-text-muted font-semibold">Analyses</div>
          </div>
          <div className="bg-card border border-border-light rounded-xl p-5 shadow-sm text-center">
            <div className="flex justify-center mb-2"><AlertTriangle className="w-5 h-5 text-danger" /></div>
            <div className="text-3xl font-bold text-text-main leading-none mb-1">{stats?.scams_detected ?? '—'}</div>
            <div className="text-xs text-text-muted font-semibold">Scams</div>
          </div>
          <div className="bg-card border border-border-light rounded-xl p-5 shadow-sm text-center">
            <div className="flex justify-center mb-2"><CheckCircle className="w-5 h-5 text-success" /></div>
            <div className="text-3xl font-bold text-text-main leading-none mb-1">{stats?.safe_messages ?? '—'}</div>
            <div className="text-xs text-text-muted font-semibold">Safe</div>
          </div>
          <div className="bg-card border border-border-light rounded-xl p-5 shadow-sm text-center">
            <div className="flex justify-center mb-2"><Activity className="w-5 h-5 text-warning" /></div>
            <div className="text-3xl font-bold text-text-main leading-none mb-1">{stats?.high_risk ?? '—'}</div>
            <div className="text-xs text-text-muted font-semibold">High Risk</div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 @content-md:grid-cols-2 gap-6 pt-2">
        {/* Security Status */}
        <div className="space-y-4">
          <h3 className="text-lg font-bold text-text-main">Security Status</h3>
          <div className="bg-card border border-border-light rounded-2xl p-5 shadow-sm space-y-4">
            <div className={`flex items-center space-x-3 ${user.is_active ? 'text-text-main' : 'text-text-muted'}`}>
              {user.is_active ? <CheckCircle className="w-5 h-5 text-success" /> : <Shield className="w-5 h-5 text-text-muted" />}
              <span className="font-semibold text-sm">Account {user.is_active ? 'Active' : 'Inactive'}</span>
            </div>
            <div className="flex items-center space-x-3 text-text-muted">
              <Shield className="w-5 h-5" />
              <span className="font-semibold text-sm">Two-factor authentication is not enforced yet</span>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="space-y-4">
          <h3 className="text-lg font-bold text-text-main">Quick Actions</h3>
          <div className="space-y-2">
            <button onClick={() => navigate('/profile/settings', { state: { tab: 'account', openEditModal: true } })} className="w-full bg-card border border-border-light hover:border-primary/50 hover:bg-background rounded-xl p-4 flex items-center justify-between text-text-main transition shadow-sm">
              <span className="font-bold text-sm">Edit Profile</span>
              <ChevronRight className="w-4 h-4 text-text-muted" />
            </button>
            <button onClick={() => navigate('/profile/settings', { state: { tab: 'security' } })} className="w-full bg-card border border-border-light hover:border-primary/50 hover:bg-background rounded-xl p-4 flex items-center justify-between text-text-main transition shadow-sm">
              <span className="font-bold text-sm">Security Settings</span>
              <ChevronRight className="w-4 h-4 text-text-muted" />
            </button>
            <button onClick={() => navigate('/history')} className="w-full bg-card border border-border-light hover:border-primary/50 hover:bg-background rounded-xl p-4 flex items-center justify-between text-text-main transition shadow-sm">
              <span className="font-bold text-sm">View Analysis History</span>
              <ChevronRight className="w-4 h-4 text-text-muted" />
            </button>
          </div>
        </div>
      </div>

      {/* Primary CTA */}
      <div className="mt-8">
        <div className="bg-primary/5 border border-primary/20 rounded-2xl p-6 @content-sm:p-8 flex flex-col @content-sm:flex-row @content-sm:items-center justify-between gap-4">
          <div>
            <h3 className="text-xl font-bold text-primary mb-1">Manage your account</h3>
            <p className="text-text-muted text-sm">Account information, security & preferences</p>
          </div>
          <button onClick={() => navigate('/profile/settings')} className="shrink-0 bg-primary hover:bg-primary-hover text-white px-6 py-3 rounded-xl font-bold flex items-center justify-center space-x-2 transition shadow-sm">
            <span>Open Settings</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      </div>

    </div>
  );
}

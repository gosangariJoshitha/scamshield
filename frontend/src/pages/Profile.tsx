import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  User, Mail, Calendar, Edit2, Lock, Shield, 
  Smartphone, Monitor, LogOut, Trash2, Camera,
  FileText, AlertTriangle, CheckCircle, Activity,
  Bell, Users, Send, Clock
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
        
        // Also fetch stats for the profile header
        const statsData = await dashboardService.getStats().catch(() => null);
        if (statsData) setStats(statsData);
      } catch (err) {
        auth.logout();
        navigate('/login');
      } finally {
        setLoading(false);
      }
    };
    
    fetchProfileData();
  }, [navigate]);

  const handleLogout = () => {
    auth.logout();
    window.location.href = '/login';
  };

  if (loading || !user) {
    return (
      <div className="space-y-6">
        <div className="mb-8">
          <div className="h-8 bg-slate-200 rounded w-48 mb-2 animate-pulse"></div>
          <div className="h-4 bg-slate-200 rounded w-64 animate-pulse"></div>
        </div>
        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 h-64 animate-pulse"></div>
      </div>
    );
  }

  const initials = user?.full_name 
    ? user.full_name.split(' ').map((n: string) => n[0]).join('').substring(0, 2).toUpperCase()
    : 'U';

  const memberSince = new Date(user.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
  // Mock last login to just now for display purposes
  const lastLogin = new Date().toLocaleString('en-US', { year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute: '2-digit' });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-2">
        <div>
          <h1 className="text-3xl font-bold text-slate-800 mb-2">My Profile</h1>
          <p className="text-slate-500 text-sm">View and manage your account information, security settings, and preferences.</p>
        </div>
        <button className="flex items-center space-x-2 bg-white border border-slate-200 hover:border-slate-300 text-blue-600 font-semibold py-2.5 px-6 rounded-xl shadow-sm transition shrink-0">
          <Edit2 className="w-4 h-4" />
          <span>Edit Profile</span>
        </button>
      </div>

      {/* Top Card (Profile summary + Stats) */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 flex flex-col md:flex-row overflow-hidden">
        {/* Left Profile Area */}
        <div className="p-8 md:w-5/12 bg-gradient-to-br from-blue-50/80 via-white to-white flex items-center space-x-6 border-b md:border-b-0 md:border-r border-slate-100">
          <div className="relative shrink-0">
            <div className="w-24 h-24 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-3xl font-bold border-4 border-white shadow-sm">
              {initials}
            </div>
            <button className="absolute bottom-0 right-0 p-1.5 bg-slate-700 text-white rounded-full hover:bg-slate-800 transition shadow-sm border-2 border-white">
              <Camera className="w-3.5 h-3.5" />
            </button>
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center space-x-3 mb-2 flex-wrap gap-y-2">
              <h2 className="text-xl font-bold text-slate-800 truncate">{user.full_name}</h2>
              <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-green-100 text-green-700 uppercase tracking-wider">
                {user.is_active ? 'Active' : 'Inactive'}
              </span>
            </div>
            <div className="space-y-1.5">
              <div className="flex items-center space-x-2 text-sm text-slate-600">
                <User className="w-4 h-4 text-slate-400" />
                <span className="capitalize">{user.role}</span>
              </div>
              <div className="flex items-center space-x-2 text-sm text-slate-600">
                <Mail className="w-4 h-4 text-slate-400" />
                <span className="truncate">{user.email}</span>
              </div>
              <div className="flex items-center space-x-2 text-sm text-slate-600">
                <Calendar className="w-4 h-4 text-slate-400" />
                <span>Member since {memberSince}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Stats Area */}
        <div className="p-8 md:w-7/12 flex items-center">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 w-full">
            <div className="border border-slate-100 rounded-xl p-4 bg-slate-50/50 flex flex-col justify-center">
              <FileText className="w-5 h-5 text-blue-500 mb-2" />
              <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{stats?.total_analyses || 0}</div>
              <div className="text-[10px] text-slate-500 font-medium">Total Analyses</div>
            </div>
            <div className="border border-slate-100 rounded-xl p-4 bg-slate-50/50 flex flex-col justify-center">
              <AlertTriangle className="w-5 h-5 text-red-500 mb-2" />
              <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{stats?.scams_detected || 0}</div>
              <div className="text-[10px] text-slate-500 font-medium">Scams Detected</div>
            </div>
            <div className="border border-slate-100 rounded-xl p-4 bg-slate-50/50 flex flex-col justify-center">
              <CheckCircle className="w-5 h-5 text-green-500 mb-2" />
              <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{stats?.safe_messages || 0}</div>
              <div className="text-[10px] text-slate-500 font-medium">Safe Messages</div>
            </div>
            <div className="border border-slate-100 rounded-xl p-4 bg-slate-50/50 flex flex-col justify-center">
              <Activity className="w-5 h-5 text-orange-500 mb-2" />
              <div className="text-2xl font-bold text-slate-800 leading-none mb-1">58</div>
              <div className="text-[10px] text-slate-500 font-medium">Avg. Risk Score</div>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Left Column */}
        <div className="lg:col-span-5 space-y-6">
          
          {/* Account Information */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center space-x-2 text-slate-800">
                <div className="bg-blue-50 text-blue-600 p-1.5 rounded-lg">
                  <User className="w-4 h-4" />
                </div>
                <h2 className="text-base font-bold">Account Information</h2>
              </div>
              <button className="flex items-center space-x-1.5 text-xs font-semibold text-blue-600 bg-blue-50 hover:bg-blue-100 px-3 py-1.5 rounded-lg transition-colors">
                <Edit2 className="w-3.5 h-3.5" />
                <span>Edit</span>
              </button>
            </div>
            
            <div className="space-y-5">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3 text-slate-500">
                  <User className="w-4 h-4 shrink-0" />
                  <span className="text-sm">Full Name</span>
                </div>
                <span className="text-sm font-medium text-slate-800">{user.full_name}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3 text-slate-500">
                  <Mail className="w-4 h-4 shrink-0" />
                  <span className="text-sm">Email Address</span>
                </div>
                <span className="text-sm font-medium text-slate-800">{user.email}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3 text-slate-500">
                  <Shield className="w-4 h-4 shrink-0" />
                  <span className="text-sm">Role</span>
                </div>
                <span className="text-xs font-bold px-2 py-0.5 rounded bg-blue-100 text-blue-700 uppercase tracking-wider">{user.role}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3 text-slate-500">
                  <CheckCircle className="w-4 h-4 shrink-0 text-green-500" />
                  <span className="text-sm">Account Status</span>
                </div>
                <span className="text-xs font-bold px-2 py-0.5 rounded bg-green-100 text-green-700 uppercase tracking-wider">{user.is_active ? 'Active' : 'Inactive'}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3 text-slate-500">
                  <Calendar className="w-4 h-4 shrink-0" />
                  <span className="text-sm">Member Since</span>
                </div>
                <span className="text-sm font-medium text-slate-800">{memberSince}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3 text-slate-500">
                  <Clock className="w-4 h-4 shrink-0" />
                  <span className="text-sm">Last Login</span>
                </div>
                <span className="text-sm font-medium text-slate-800">{lastLogin}</span>
              </div>
            </div>
          </div>

          {/* Preferences */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <div className="flex items-center space-x-2 text-slate-800 mb-6">
              <div className="bg-purple-50 text-purple-600 p-1.5 rounded-lg">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
              </div>
              <h2 className="text-base font-bold">Preferences</h2>
            </div>
            
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div className="flex items-start space-x-3">
                  <Bell className="w-5 h-5 text-blue-500 shrink-0 mt-0.5" />
                  <div>
                    <div className="text-sm font-bold text-slate-800">Email Notifications</div>
                    <div className="text-xs text-slate-500">Receive important updates about your analyses and account.</div>
                  </div>
                </div>
                {/* Toggle on */}
                <div className="w-11 h-6 bg-blue-600 rounded-full relative cursor-pointer flex-shrink-0 transition-colors shadow-inner">
                  <div className="absolute top-1 right-1 w-4 h-4 bg-white rounded-full shadow-sm"></div>
                </div>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="flex items-start space-x-3">
                  <Users className="w-5 h-5 text-purple-500 shrink-0 mt-0.5" />
                  <div>
                    <div className="text-sm font-bold text-slate-800">Community Updates</div>
                    <div className="text-xs text-slate-500">Get notified about new community reports and scam trends.</div>
                  </div>
                </div>
                {/* Toggle on */}
                <div className="w-11 h-6 bg-blue-600 rounded-full relative cursor-pointer flex-shrink-0 transition-colors shadow-inner">
                  <div className="absolute top-1 right-1 w-4 h-4 bg-white rounded-full shadow-sm"></div>
                </div>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="flex items-start space-x-3">
                  <Send className="w-5 h-5 text-green-500 shrink-0 mt-0.5" />
                  <div>
                    <div className="text-sm font-bold text-slate-800">Marketing Updates</div>
                    <div className="text-xs text-slate-500">Receive product updates and security tips.</div>
                  </div>
                </div>
                {/* Toggle off */}
                <div className="w-11 h-6 bg-slate-200 rounded-full relative cursor-pointer flex-shrink-0 transition-colors shadow-inner">
                  <div className="absolute top-1 left-1 w-4 h-4 bg-white rounded-full shadow-sm"></div>
                </div>
              </div>
            </div>
          </div>
          
        </div>

        {/* Right Column */}
        <div className="lg:col-span-7 space-y-6">
          
          {/* Security */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <div className="flex items-center space-x-2 text-slate-800 mb-6">
              <div className="bg-blue-50 text-blue-600 p-1.5 rounded-lg">
                <Lock className="w-4 h-4" />
              </div>
              <h2 className="text-base font-bold">Security</h2>
            </div>
            
            <div className="space-y-4">
              <div className="flex items-center justify-between p-4 border border-slate-100 rounded-xl bg-slate-50/50 hover:bg-slate-50 transition">
                <div className="flex items-start space-x-3">
                  <div className="bg-white p-2 rounded-lg border border-slate-200 shadow-sm shrink-0">
                    <Lock className="w-4 h-4 text-slate-600" />
                  </div>
                  <div>
                    <div className="text-sm font-bold text-slate-800">Password</div>
                    <div className="text-xs text-slate-500">Keep your account secure with a strong password.</div>
                  </div>
                </div>
                <button className="border border-blue-200 text-blue-600 hover:bg-blue-50 font-semibold px-4 py-2 rounded-lg transition-colors text-xs shrink-0">
                  Change Password
                </button>
              </div>

              <div className="flex items-center justify-between p-4 border border-slate-100 rounded-xl bg-slate-50/50 hover:bg-slate-50 transition">
                <div className="flex items-start space-x-3">
                  <div className="bg-white p-2 rounded-lg border border-slate-200 shadow-sm shrink-0">
                    <Mail className="w-4 h-4 text-blue-500" />
                  </div>
                  <div>
                    <div className="text-sm font-bold text-slate-800">Email</div>
                    <div className="text-xs text-slate-500">Your email address is used for login and important notifications.</div>
                  </div>
                </div>
                <span className="bg-green-100 text-green-700 text-[10px] font-bold px-2.5 py-1 rounded-full uppercase tracking-wider shrink-0">
                  Verified
                </span>
              </div>

              <div className="flex items-center justify-between p-4 border border-slate-100 rounded-xl bg-slate-50/50 hover:bg-slate-50 transition">
                <div className="flex items-start space-x-3">
                  <div className="bg-white p-2 rounded-lg border border-slate-200 shadow-sm shrink-0">
                    <Shield className="w-4 h-4 text-purple-500" />
                  </div>
                  <div>
                    <div className="text-sm font-bold text-slate-800">Two-Factor Authentication</div>
                    <div className="text-xs text-slate-500">Add an extra layer of security to your account.</div>
                  </div>
                </div>
                <span className="bg-purple-100 text-purple-700 text-[10px] font-bold px-2.5 py-1 rounded-full uppercase tracking-wider shrink-0">
                  Coming Soon
                </span>
              </div>

              <div className="flex items-center justify-between p-4 border border-slate-100 rounded-xl bg-slate-50/50 hover:bg-slate-50 transition">
                <div className="flex items-start space-x-3">
                  <div className="bg-white p-2 rounded-lg border border-slate-200 shadow-sm shrink-0">
                    <Monitor className="w-4 h-4 text-slate-600" />
                  </div>
                  <div>
                    <div className="text-sm font-bold text-slate-800">Active Sessions</div>
                    <div className="text-xs text-slate-500">Manage your active login sessions.</div>
                  </div>
                </div>
                <button className="border border-slate-200 text-slate-600 hover:bg-slate-100 font-semibold px-4 py-2 rounded-lg transition-colors text-xs shrink-0 bg-white shadow-sm">
                  View Sessions
                </button>
              </div>
            </div>
          </div>

          {/* Account Actions */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <div className="flex items-center space-x-2 text-slate-800 mb-6">
              <div className="bg-blue-50 text-blue-600 p-1.5 rounded-lg">
                <User className="w-4 h-4" />
              </div>
              <h2 className="text-base font-bold">Account Actions</h2>
            </div>
            
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-start space-x-3">
                  <div className="bg-red-50 text-red-500 p-2 rounded-lg shrink-0 mt-0.5">
                    <LogOut className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-sm font-bold text-slate-800">Logout</div>
                    <div className="text-xs text-slate-500">Sign out from your account on this device.</div>
                  </div>
                </div>
                <button onClick={handleLogout} className="border border-red-200 text-red-600 hover:bg-red-50 font-semibold px-6 py-2 rounded-lg transition-colors text-xs shrink-0">
                  Logout
                </button>
              </div>
              
              <div className="w-full h-px bg-slate-100"></div>

              <div className="flex items-center justify-between">
                <div className="flex items-start space-x-3">
                  <div className="bg-red-50 text-red-500 p-2 rounded-lg shrink-0 mt-0.5">
                    <Trash2 className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-sm font-bold text-slate-800">Delete Account</div>
                    <div className="text-xs text-slate-500 mb-1">Permanently delete your account and all data.</div>
                    <div className="text-[10px] text-red-500 font-bold flex items-center">
                      <AlertTriangle className="w-3 h-3 mr-1" />
                      This action cannot be undone.
                    </div>
                  </div>
                </div>
                <button className="border border-red-200 text-red-600 hover:bg-red-50 font-semibold px-4 py-2 rounded-lg transition-colors text-xs shrink-0">
                  Delete Account
                </button>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

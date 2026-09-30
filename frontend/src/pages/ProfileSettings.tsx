import { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { 
  User, Lock, AlertTriangle,
  Bell, ArrowLeft, Monitor
} from 'lucide-react';
import { auth } from '../services/auth';

export default function ProfileSettings() {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const location = useLocation();

  // Navigation state (horizontal tabs)
  const [activeTab, setActiveTab] = useState<'account' | 'security' | 'preferences' | 'actions'>(
    location.state?.tab || 'account'
  );

  // Modals state
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isPasswordModalOpen, setIsPasswordModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);

  // Forms state
  const [newName, setNewName] = useState('');
  const [passwords, setPasswords] = useState({ current: '', new: '', confirm: '' });

  useEffect(() => {
    const fetchProfileData = async () => {
      try {
        const userData = await auth.me();
        setUser(userData);
        if (location.state?.openEditModal) {
          setNewName(userData.full_name);
          setIsEditModalOpen(true);
        }
      } catch (err) {
        auth.logout();
        navigate('/login');
      } finally {
        setLoading(false);
      }
    };
    
    fetchProfileData();
  }, [navigate, location.state]);

  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) return;
    try {
      const res = await auth.updateProfile(newName);
      setUser(res);
      setIsEditModalOpen(false);
    } catch (err) {
      alert("Failed to update profile");
    }
  };

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (passwords.new !== passwords.confirm) {
      alert("New passwords do not match!");
      return;
    }
    try {
      await auth.changePassword(passwords.current, passwords.new);
      alert("Password updated successfully!");
      setIsPasswordModalOpen(false);
      setPasswords({ current: '', new: '', confirm: '' });
    } catch (err) {
      alert("Failed to change password. Check your current password.");
    }
  };

  const handleDeleteAccount = async () => {
    try {
      await auth.deleteAccount();
      auth.logout();
      window.location.href = '/login';
    } catch (err) {
      alert("Failed to delete account");
    }
  };

  const handleLogout = () => {
    auth.logout();
    window.location.href = '/login';
  };

  if (loading || !user) {
    return (
      <div className="space-y-6 animate-pulse">
        <div className="h-8 bg-slate-200 rounded w-48 mb-2"></div>
        <div className="bg-card rounded-2xl h-96"></div>
      </div>
    );
  }

  const memberSince = new Date(user.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
  const lastLogin = new Date().toLocaleString('en-US', { year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute: '2-digit' });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="mb-2">
        <button 
          onClick={() => navigate('/profile')}
          className="flex items-center space-x-2 text-text-muted hover:text-text-main font-semibold mb-4 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back to Profile</span>
        </button>
        <h1 className="text-3xl font-bold text-text-main mb-2">Account & Settings</h1>
        <p className="text-text-muted text-base">Manage your account information, security and preferences.</p>
      </div>

      {/* Tabs */}
      <div className="flex overflow-x-auto space-x-2 border-b border-border-light pb-px hide-scrollbar">
        {[
          { id: 'account', label: 'Account Information', icon: User },
          { id: 'security', label: 'Security', icon: Lock },
          { id: 'preferences', label: 'Preferences', icon: Bell },
          { id: 'actions', label: 'Account Actions', icon: AlertTriangle }
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`flex items-center space-x-2 px-4 py-3 border-b-2 font-bold whitespace-nowrap transition-colors ${
              activeTab === tab.id 
                ? 'border-primary text-primary' 
                : 'border-transparent text-text-muted hover:text-text-main hover:border-border-main'
            }`}
          >
            <tab.icon className="w-4 h-4" />
            <span>{tab.label}</span>
          </button>
        ))}
      </div>

      {/* Content Area */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6 min-h-[400px]">
        
        {/* Account Tab */}
        {activeTab === 'account' && (
          <div className="space-y-6 max-w-2xl">
            <div className="flex items-center justify-between mb-8">
              <div>
                <h2 className="text-lg font-bold text-text-main">Account Information</h2>
                <p className="text-sm text-text-muted">Your personal and account details.</p>
              </div>
              <button 
                onClick={() => { setNewName(user.full_name); setIsEditModalOpen(true); }}
                className="px-4 py-2 bg-primary/10 hover:bg-primary/20 text-primary rounded-xl font-bold transition text-sm"
              >
                Edit Profile
              </button>
            </div>

            <div className="space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-border-light pb-4">
                <div className="text-text-muted text-sm font-semibold">Full Name</div>
                <div className="text-text-main font-bold">{user.full_name}</div>
              </div>
              
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-border-light pb-4">
                <div>
                  <div className="text-text-muted text-sm font-semibold">Email Address</div>
                  <div className="text-[11px] text-text-muted mt-1">Used for login and account communication.</div>
                </div>
                <div className="text-text-main font-bold">{user.email}</div>
              </div>
              
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-border-light pb-4">
                <div className="text-text-muted text-sm font-semibold">Role</div>
                <div className="bg-primary/10 text-primary px-2.5 py-1 rounded text-xs font-bold uppercase tracking-wider">{user.role}</div>
              </div>

              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-border-light pb-4">
                <div className="text-text-muted text-sm font-semibold">Account Status</div>
                <div className={user.is_active ? "bg-success/20 text-success px-2.5 py-1 rounded text-xs font-bold uppercase tracking-wider" : "bg-danger/20 text-danger px-2.5 py-1 rounded text-xs font-bold uppercase tracking-wider"}>
                  {user.is_active ? 'Active' : 'Inactive'}
                </div>
              </div>

              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-border-light pb-4">
                <div className="text-text-muted text-sm font-semibold">Member Since</div>
                <div className="text-text-main font-bold">{memberSince}</div>
              </div>

              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div className="text-text-muted text-sm font-semibold">Last Login</div>
                <div className="text-text-main font-bold">{lastLogin}</div>
              </div>
            </div>
          </div>
        )}

        {/* Security Tab */}
        {activeTab === 'security' && (
          <div className="space-y-6 max-w-3xl">
            <div className="mb-8">
              <h2 className="text-lg font-bold text-text-main">Security</h2>
              <p className="text-sm text-text-muted">Protect your ScamShield account.</p>
            </div>

            <div className="bg-background/50 rounded-xl border border-border-light divide-y divide-border-light overflow-hidden">
              <div className="flex items-center justify-between p-5">
                <div>
                  <div className="text-base font-bold text-text-main">Password</div>
                  <div className="text-sm text-text-muted">Keep your account secure with a strong password.</div>
                </div>
                <button 
                  onClick={() => setIsPasswordModalOpen(true)}
                  className="px-4 py-2 border border-border-main text-text-main hover:bg-background rounded-xl font-bold transition text-sm bg-card shadow-sm"
                >
                  Change Password
                </button>
              </div>

              <div className="flex items-center justify-between p-5">
                <div>
                  <div className="text-base font-bold text-text-main">Email</div>
                  <div className="text-sm text-text-muted">Your email is used for authentication.</div>
                </div>
                <div className="bg-success/20 text-success px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider">
                  Verified
                </div>
              </div>

              <div className="flex items-center justify-between p-5">
                <div>
                  <div className="text-base font-bold text-text-main">Two-Factor Authentication</div>
                  <div className="text-sm text-text-muted">Add another layer of security to your account.</div>
                </div>
                <button 
                  onClick={async () => {
                    const res = await auth.updateProfile({ two_factor_enabled: !user.two_factor_enabled });
                    setUser(res);
                  }}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-background ${user.two_factor_enabled ? 'bg-primary' : 'bg-slate-300 dark:bg-slate-700'}`}
                >
                  <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${user.two_factor_enabled ? 'translate-x-6' : 'translate-x-1'}`} />
                </button>
              </div>

              <div className="flex flex-col sm:flex-row sm:items-center justify-between p-5 gap-4">
                <div>
                  <div className="text-base font-bold text-text-main">Active Sessions</div>
                  <div className="text-sm text-text-muted">Manage your active login sessions.</div>
                </div>
                <div className="bg-card border border-border-light p-3 rounded-lg flex items-center space-x-3 text-sm flex-1 sm:max-w-xs shadow-sm">
                  <Monitor className="w-5 h-5 text-primary shrink-0" />
                  <div className="min-w-0">
                    <div className="font-semibold text-text-main truncate">Windows • Chrome</div>
                    <div className="text-xs text-success font-bold mt-0.5">Current Session</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Preferences Tab */}
        {activeTab === 'preferences' && (
          <div className="space-y-6 max-w-3xl">
            <div className="mb-8">
              <h2 className="text-lg font-bold text-text-main">Preferences</h2>
              <p className="text-sm text-text-muted">Customize how ScamShield works for you.</p>
            </div>

            <div className="bg-background/50 rounded-xl border border-border-light divide-y divide-border-light overflow-hidden">
              <div className="flex items-center justify-between p-5">
                <div>
                  <div className="text-base font-bold text-text-main">Email Notifications</div>
                  <div className="text-sm text-text-muted">Receive important updates about your analyses and account.</div>
                </div>
                <button 
                  onClick={async () => {
                    const res = await auth.updateProfile({ email_notifications: !user.email_notifications });
                    setUser(res);
                  }}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-background ${user.email_notifications ? 'bg-primary' : 'bg-slate-300 dark:bg-slate-700'}`}
                >
                  <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${user.email_notifications ? 'translate-x-6' : 'translate-x-1'}`} />
                </button>
              </div>
              
              <div className="flex items-center justify-between p-5">
                <div>
                  <div className="text-base font-bold text-text-main">Community Updates</div>
                  <div className="text-sm text-text-muted">Get notified about new community reports and scam trends.</div>
                </div>
                <button 
                  onClick={async () => {
                    const res = await auth.updateProfile({ community_updates: !user.community_updates });
                    setUser(res);
                  }}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-background ${user.community_updates ? 'bg-primary' : 'bg-slate-300 dark:bg-slate-700'}`}
                >
                  <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${user.community_updates ? 'translate-x-6' : 'translate-x-1'}`} />
                </button>
              </div>
              
              <div className="flex items-center justify-between p-5">
                <div>
                  <div className="text-base font-bold text-text-main">Marketing Updates</div>
                  <div className="text-sm text-text-muted">Receive product updates and security tips.</div>
                </div>
                <button 
                  onClick={async () => {
                    const res = await auth.updateProfile({ marketing_updates: !user.marketing_updates });
                    setUser(res);
                  }}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-background ${user.marketing_updates ? 'bg-primary' : 'bg-slate-300 dark:bg-slate-700'}`}
                >
                  <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${user.marketing_updates ? 'translate-x-6' : 'translate-x-1'}`} />
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Account Actions Tab */}
        {activeTab === 'actions' && (
          <div className="space-y-6 max-w-3xl">
            <div className="mb-8">
              <h2 className="text-lg font-bold text-text-main">Account Actions</h2>
              <p className="text-sm text-text-muted">Sign out or permanently delete your account.</p>
            </div>

            <div className="bg-background/50 rounded-xl border border-border-light divide-y divide-border-light overflow-hidden">
              <div className="flex items-center justify-between p-5">
                <div>
                  <div className="text-base font-bold text-text-main">Logout</div>
                  <div className="text-sm text-text-muted">Sign out from your account on this device.</div>
                </div>
                <button 
                  onClick={handleLogout} 
                  className="px-6 py-2 bg-card border border-border-main hover:bg-background text-text-main rounded-xl font-bold transition text-sm shadow-sm"
                >
                  Logout
                </button>
              </div>
              
              <div className="flex items-center justify-between p-5 bg-danger/5">
                <div>
                  <div className="text-base font-bold text-danger">Delete Account</div>
                  <div className="text-sm text-danger/80 mt-1">Permanently delete your account and associated data.</div>
                  <div className="text-[11px] font-bold text-danger mt-2 flex items-center">
                    <AlertTriangle className="w-3.5 h-3.5 mr-1" />
                    This action cannot be undone.
                  </div>
                </div>
                <button 
                  onClick={() => setIsDeleteModalOpen(true)} 
                  className="px-6 py-2 bg-danger hover:bg-danger/90 text-white rounded-xl font-bold transition text-sm shadow-sm"
                >
                  Delete Account
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Modals */}
      {/* Edit Profile Modal */}
      {isEditModalOpen && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-card rounded-2xl max-w-md w-full p-6 shadow-xl border border-border-light">
            <h3 className="text-xl font-bold text-text-main mb-4">Edit Profile</h3>
            <form onSubmit={handleUpdateProfile} className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-text-main mb-1.5">Full Name</label>
                <input 
                  type="text" 
                  value={newName} 
                  onChange={(e) => setNewName(e.target.value)}
                  className="w-full px-4 py-2 border border-border-light rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary bg-background text-text-main"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-text-main mb-1.5">Email Address</label>
                <input 
                  type="email" 
                  value={user.email} 
                  disabled
                  className="w-full px-4 py-2 border border-border-light rounded-xl bg-background/50 text-text-muted cursor-not-allowed"
                />
                <p className="text-xs text-text-muted mt-1">Email cannot be changed.</p>
              </div>
              <div className="flex justify-end space-x-3 mt-6 pt-2">
                <button type="button" onClick={() => setIsEditModalOpen(false)} className="px-4 py-2 text-text-muted hover:text-text-main font-semibold">Cancel</button>
                <button type="submit" className="px-5 py-2 bg-primary hover:bg-primary-hover text-white rounded-xl font-bold shadow-sm transition">Save Changes</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Change Password Modal */}
      {isPasswordModalOpen && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-card rounded-2xl max-w-md w-full p-6 shadow-xl border border-border-light">
            <h3 className="text-xl font-bold text-text-main mb-4">Change Password</h3>
            <form onSubmit={handleChangePassword} className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-text-main mb-1.5">Current Password</label>
                <input 
                  type="password" 
                  value={passwords.current} 
                  onChange={(e) => setPasswords({...passwords, current: e.target.value})}
                  className="w-full px-4 py-2 border border-border-light rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary bg-background text-text-main"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-text-main mb-1.5">New Password</label>
                <input 
                  type="password" 
                  value={passwords.new} 
                  onChange={(e) => setPasswords({...passwords, new: e.target.value})}
                  className="w-full px-4 py-2 border border-border-light rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary bg-background text-text-main"
                  required
                  minLength={6}
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-text-main mb-1.5">Confirm New Password</label>
                <input 
                  type="password" 
                  value={passwords.confirm} 
                  onChange={(e) => setPasswords({...passwords, confirm: e.target.value})}
                  className="w-full px-4 py-2 border border-border-light rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary bg-background text-text-main"
                  required
                />
              </div>
              <div className="flex justify-end space-x-3 mt-6 pt-2">
                <button type="button" onClick={() => setIsPasswordModalOpen(false)} className="px-4 py-2 text-text-muted hover:text-text-main font-semibold">Cancel</button>
                <button type="submit" className="px-5 py-2 bg-primary hover:bg-primary-hover text-white rounded-xl font-bold shadow-sm transition">Update Password</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Account Modal */}
      {isDeleteModalOpen && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-card rounded-2xl max-w-md w-full p-6 shadow-xl border border-danger/30">
            <div className="flex items-center space-x-3 mb-4 text-danger">
              <AlertTriangle className="w-6 h-6" />
              <h3 className="text-xl font-bold">Delete your account?</h3>
            </div>
            <p className="text-text-main mb-6">This will permanently remove your account and associated data.<br/><br/>This action cannot be undone.</p>
            <div className="flex justify-end space-x-3">
              <button onClick={() => setIsDeleteModalOpen(false)} className="px-4 py-2 text-text-muted hover:text-text-main font-semibold">Cancel</button>
              <button onClick={handleDeleteAccount} className="px-5 py-2 bg-danger hover:bg-danger/90 text-white rounded-xl font-bold shadow-sm transition">Delete Account</button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}

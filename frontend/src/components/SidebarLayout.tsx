import { useState, useEffect, useRef } from 'react';
import { Outlet, Link, useLocation, useNavigate } from 'react-router-dom';
import { 
  ShieldCheck, LayoutDashboard, Search, History, Users, 
  User, LogOut, Bell, Settings, Check, Trash2,
  Moon, Sun
} from 'lucide-react';
import { auth } from '../services/auth';
import { useTheme } from '../hooks/useTheme';

interface Notification {
  id: string;
  title: string;
  message: string;
  isRead: boolean;
  time: string;
  type: 'alert' | 'info' | 'success';
}

export default function SidebarLayout() {
  const location = useLocation();
  const navigate = useNavigate();
  const path = location.pathname;

  const [user, setUser] = useState<any>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const { theme, toggleTheme } = useTheme();
  
  // Dropdown states
  const [showNotifications, setShowNotifications] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  
  // Refs for clicking outside
  const notifRef = useRef<HTMLDivElement>(null);
  const profileRef = useRef<HTMLDivElement>(null);

  // Mock Notifications
  const [notifications, setNotifications] = useState<Notification[]>([]);

  useEffect(() => {
    auth.me().then(data => {
      setUser(data);
      if (data && data.role === 'admin') {
        navigate('/admin');
      }
    }).catch(() => {
      // If unauthorized, the protected route will handle it
    });
  }, [navigate]);

  // Handle clicking outside to close dropdowns
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
        setShowNotifications(false);
      }
      if (profileRef.current && !profileRef.current.contains(event.target as Node)) {
        setShowProfileMenu(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, []);

  const handleLogout = () => {
    auth.logout();
    navigate('/login');
  };

  const navItems = [
    { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
    { name: 'Analyze', path: '/analyze', icon: Search },
    { name: 'History', path: '/history', icon: History },
    { name: 'Community', path: '/community', icon: Users },
    { name: 'Profile', path: '/profile', icon: User },
  ];

  const unreadCount = notifications.filter(n => !n.isRead).length;

  const markAllAsRead = () => {
    setNotifications(notifications.map(n => ({ ...n, isRead: true })));
  };

  const clearAllNotifications = () => {
    setNotifications([]);
  };

  const toggleNotification = (id: string) => {
    setNotifications(notifications.map(n => n.id === id ? { ...n, isRead: !n.isRead } : n));
  };

  return (
    <div className="flex h-screen bg-background text-text-main font-sans">
      <aside className="w-64 bg-card text-text-main flex flex-col h-full shrink-0 border-r border-border-light shadow-sm z-20">
        <Link to="/dashboard" className="p-6 flex items-center space-x-2 border-b border-border-light mb-4 hover:bg-background transition-colors cursor-pointer block">
          <div className="flex items-center space-x-2">
            <ShieldCheck className="w-8 h-8 text-primary shrink-0" />
            <span className="text-xl font-bold tracking-wide">SCAMSHIELD</span>
          </div>
        </Link>
        <nav className="flex-1 px-4 py-2 space-y-2">
          {navItems.map(item => {
            const source = location.state?.from;
            const isActive = path === item.path || (path === '/results' && (source === item.path || (!source && item.path === '/analyze')));
            return (
              <Link key={item.path} to={item.path} className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-colors ${isActive ? 'bg-primary/10 text-primary font-bold' : 'text-text-secondary hover:bg-background hover:text-text-main'}`}>
                <item.icon className={`w-5 h-5 ${isActive ? 'text-primary' : 'text-text-muted'}`} />
                <span className="font-bold text-sm">{item.name}</span>
              </Link>
            );
          })}
        </nav>
        <div className="p-4 border-t border-border-light mt-auto">
          <button onClick={handleLogout} className="flex items-center space-x-3 px-4 py-3 w-full rounded-xl text-text-secondary hover:bg-danger/10 hover:text-danger transition-colors">
            <LogOut className="w-5 h-5" />
            <span className="font-bold text-sm">Logout</span>
          </button>
        </div>
      </aside>
      
      <main className="flex-1 overflow-auto flex flex-col relative">
        <div className="h-16 border-b border-border-light bg-card flex items-center justify-between px-8 shrink-0 shadow-sm z-10 relative">
          {/* Top Header Search */}
          <div className="flex-1 max-w-2xl flex items-center">
            <div className="relative w-full max-w-md">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-text-muted" />
              </div>
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && searchQuery.trim()) {
                    navigate(`/history?q=${encodeURIComponent(searchQuery)}`);
                  }
                }}
                placeholder="Search analyses, reports, or anything..."
                className="block w-full pl-10 pr-12 py-2 border border-border-light rounded-xl leading-5 bg-background placeholder:text-text-muted focus:outline-none focus:bg-card focus:ring-[3px] focus:ring-primary/20 focus:border-primary sm:text-sm font-semibold transition-colors text-text-main"
              />
              <div className="absolute inset-y-0 right-0 pr-2 flex items-center">
                <button 
                  onClick={() => {
                    if (searchQuery.trim()) {
                      navigate(`/history?q=${encodeURIComponent(searchQuery)}`);
                    }
                  }}
                  className="p-1.5 hover:bg-border-light text-text-muted hover:text-primary rounded-lg transition-colors focus:outline-none"
                  title="Search"
                >
                  <Search className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
          
          <div className="flex items-center space-x-6">
            {/* Theme Toggle */}
            <button
              onClick={toggleTheme}
              className="p-2 text-text-muted hover:bg-background hover:text-text-main rounded-full transition-colors"
              aria-label="Toggle Dark Mode"
            >
              {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            </button>
            
            {/* Notification Bell */}
            <div className="relative" ref={notifRef}>
              <button 
                onClick={() => setShowNotifications(!showNotifications)}
                className="relative p-2 text-text-muted hover:bg-background hover:text-text-main rounded-full transition-colors"
              >
                <Bell className="w-5 h-5" />
                {unreadCount > 0 && (
                  <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-danger rounded-full border border-white"></span>
                )}
              </button>
              
              {/* Notifications Dropdown */}
              {showNotifications && (
                <div className="absolute right-0 mt-2 w-80 bg-card rounded-2xl shadow-xl border border-border-light overflow-hidden z-50">
                  <div className="p-4 border-b border-border-light flex items-center justify-between bg-background">
                    <h3 className="font-bold text-text-main text-sm">Notifications</h3>
                    <div className="flex space-x-2">
                      <button onClick={markAllAsRead} className="text-xs font-bold text-primary hover:text-primary-hover flex items-center space-x-1" title="Mark all as read">
                        <Check className="w-3.5 h-3.5" />
                      </button>
                      <button onClick={clearAllNotifications} className="text-xs font-bold text-text-muted hover:text-danger flex items-center space-x-1" title="Clear all">
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                  <div className="max-h-96 overflow-y-auto">
                    {notifications.length === 0 ? (
                      <div className="p-6 text-center text-sm text-text-muted flex flex-col items-center justify-center space-y-2">
                         <Bell className="w-8 h-8 text-border-main" />
                         <span className="font-semibold">No new notifications</span>
                      </div>
                    ) : (
                      <div className="divide-y divide-border-light">
                        {notifications.map((n) => (
                          <div key={n.id} onClick={() => toggleNotification(n.id)} className={`p-4 hover:bg-background cursor-pointer transition flex items-start space-x-3 ${!n.isRead ? 'bg-primary/5' : ''}`}>
                            <div className={`w-2 h-2 rounded-full mt-1.5 shrink-0 ${!n.isRead ? 'bg-primary' : 'bg-transparent'}`}></div>
                            <div className="flex-1">
                              <div className="flex justify-between items-start mb-0.5">
                                <h4 className={`text-sm font-bold ${!n.isRead ? 'text-text-main' : 'text-text-secondary'}`}>{n.title}</h4>
                                <span className="text-[10px] font-bold text-text-muted whitespace-nowrap ml-2">{n.time}</span>
                              </div>
                              <p className={`text-xs font-medium ${!n.isRead ? 'text-text-secondary' : 'text-text-muted'} line-clamp-2 mt-1`}>{n.message}</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                  <div className="p-3 border-t border-border-light text-center bg-background">
                    <button onClick={() => { setShowNotifications(false); navigate('/profile/settings'); }} className="text-xs font-bold text-primary hover:text-primary-hover">Manage Notification Settings</button>
                  </div>
                </div>
              )}
            </div>

            {/* User Profile */}
            <div className="relative">
              <button 
                onClick={() => setShowProfileMenu(!showProfileMenu)}
                className="w-10 h-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold hover:bg-primary/20 transition-colors focus:outline-none"
              >
                {user?.full_name ? user.full_name.charAt(0).toUpperCase() : <User className="w-5 h-5" />}
              </button>
              
              {showProfileMenu && (
                <div className="absolute right-0 mt-2 w-48 bg-card rounded-xl shadow-lg border border-border-light py-1 z-50">
                  <div className="px-4 py-2 border-b border-border-light mb-1">
                    <p className="text-sm font-bold text-text-main truncate">{user?.full_name || 'User'}</p>
                    <p className="text-xs font-medium text-text-muted truncate">{user?.email || ''}</p>
                  </div>
                  <Link to="/profile" onClick={() => setShowProfileMenu(false)} className="flex items-center px-4 py-2 text-sm font-semibold text-text-secondary hover:bg-background hover:text-primary transition-colors">
                    <User className="w-4 h-4 mr-3" />
                    Profile
                  </Link>
                  <Link to="/profile/settings" onClick={() => setShowProfileMenu(false)} className="flex items-center px-4 py-2 text-sm font-semibold text-text-secondary hover:bg-background hover:text-primary transition-colors">
                    <Settings className="w-4 h-4 mr-3" />
                    Settings
                  </Link>
                  <button onClick={handleLogout} className="w-full flex items-center px-4 py-2 text-sm font-semibold text-danger hover:bg-danger/5 transition-colors mt-1 border-t border-border-light pt-2">
                    <LogOut className="w-4 h-4 mr-3" />
                    Logout
                  </button>
                </div>
              )}
            </div>

          </div>
        </div>
        
        <div className="p-8 flex-1 pb-24 max-w-7xl mx-auto w-full">
          <Outlet context={{ user }} />
        </div>
      </main>
    </div>
  );
}

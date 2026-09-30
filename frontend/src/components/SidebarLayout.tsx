import { useState, useEffect, useRef } from 'react';
import { Outlet, Link, useLocation, useNavigate } from 'react-router-dom';
import { 
  ShieldCheck, LayoutDashboard, Search, History, Users, 
  User, LogOut, Bell, Settings, Check, Trash2, ShieldAlert
} from 'lucide-react';
import { auth } from '../services/auth';

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
  
  // Dropdown states
  const [showNotifications, setShowNotifications] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  
  // Refs for clicking outside
  const notifRef = useRef<HTMLDivElement>(null);
  const profileRef = useRef<HTMLDivElement>(null);

  // Mock Notifications
  const [notifications, setNotifications] = useState<Notification[]>([
    {
      id: '1',
      title: 'High Risk Detected',
      message: 'Your recent analysis found a high-risk phishing attempt.',
      isRead: false,
      time: '5m ago',
      type: 'alert'
    },
    {
      id: '2',
      title: 'Analysis Complete',
      message: 'The PDF document analysis has finished successfully.',
      isRead: false,
      time: '1h ago',
      type: 'success'
    },
    {
      id: '3',
      title: 'Community Update',
      message: 'A new common scam pattern was added to the database.',
      isRead: true,
      time: '1d ago',
      type: 'info'
    }
  ]);

  useEffect(() => {
    auth.me().then(data => setUser(data)).catch(() => {
      // If unauthorized, the protected route will handle it
    });
  }, []);

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

  const initials = user?.full_name 
    ? user.full_name.split(' ').map((n: string) => n[0]).join('').substring(0, 2).toUpperCase()
    : 'U';

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
    <div className="flex h-screen bg-[#f4f7fb] text-slate-900 font-sans">
      <aside className="w-64 bg-[#0a0f1c] text-white flex flex-col h-full shrink-0 border-r border-slate-800">
        <div className="p-6 flex items-center space-x-3 border-b border-slate-800">
          <ShieldCheck className="w-8 h-8 text-blue-500" />
          <span className="text-xl font-bold tracking-wide">ScamShield</span>
        </div>
        <nav className="flex-1 px-4 py-6 space-y-2">
          {navItems.map(item => {
            const source = location.state?.from;
            const isActive = path === item.path || (path === '/results' && (source === item.path || (!source && item.path === '/analyze')));
            return (
              <Link key={item.path} to={item.path} className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-colors ${isActive ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/20' : 'text-slate-400 hover:bg-slate-800 hover:text-white'}`}>
                <item.icon className="w-5 h-5" />
                <span className="font-medium text-sm">{item.name}</span>
              </Link>
            );
          })}
        </nav>
        <div className="p-4 border-t border-slate-800">
          <button onClick={handleLogout} className="flex items-center space-x-3 px-4 py-3 w-full rounded-xl text-slate-400 hover:bg-slate-800 hover:text-white transition-colors">
            <LogOut className="w-5 h-5" />
            <span className="font-medium text-sm">Logout</span>
          </button>
        </div>
      </aside>
      
      <main className="flex-1 overflow-auto flex flex-col relative">
        <div className="h-16 border-b border-slate-200 bg-white flex items-center justify-between px-8 shrink-0 shadow-sm z-10 relative">
          {/* Top Header Search */}
          <div className="flex-1 max-w-2xl flex items-center">
            <div className="relative w-full max-w-md">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-slate-400" />
              </div>
              <input
                type="text"
                placeholder="Search analyses, reports, or anything..."
                className="block w-full pl-10 pr-16 py-2 border border-slate-200 rounded-xl leading-5 bg-slate-50 placeholder-slate-400 focus:outline-none focus:bg-white focus:ring-1 focus:ring-blue-500 focus:border-blue-500 sm:text-sm transition-colors"
              />
              <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                <span className="text-xs text-slate-400 font-medium bg-slate-200 px-1.5 py-0.5 rounded">Ctrl K</span>
              </div>
            </div>
          </div>
          
          <div className="flex items-center space-x-6">
            {/* Notification Bell */}
            <div className="relative" ref={notifRef}>
              <button 
                onClick={() => setShowNotifications(!showNotifications)}
                className="relative p-2 text-slate-500 hover:bg-slate-100 rounded-full transition-colors"
              >
                <Bell className="w-5 h-5" />
                {unreadCount > 0 && (
                  <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border border-white"></span>
                )}
              </button>
              
              {/* Notifications Dropdown */}
              {showNotifications && (
                <div className="absolute right-0 mt-2 w-80 bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden z-50">
                  <div className="p-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
                    <h3 className="font-bold text-slate-800 text-sm">Notifications</h3>
                    <div className="flex space-x-2">
                      <button onClick={markAllAsRead} className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center space-x-1" title="Mark all as read">
                        <Check className="w-3.5 h-3.5" />
                      </button>
                      <button onClick={clearAllNotifications} className="text-xs font-semibold text-slate-400 hover:text-red-500 flex items-center space-x-1" title="Clear all">
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                  <div className="max-h-96 overflow-y-auto">
                    {notifications.length === 0 ? (
                      <div className="p-6 text-center text-sm text-slate-500 flex flex-col items-center justify-center space-y-2">
                         <Bell className="w-8 h-8 text-slate-200" />
                         <span>No new notifications</span>
                      </div>
                    ) : (
                      <div className="divide-y divide-slate-50">
                        {notifications.map((n) => (
                          <div key={n.id} onClick={() => toggleNotification(n.id)} className={`p-4 hover:bg-slate-50 cursor-pointer transition flex items-start space-x-3 ${!n.isRead ? 'bg-blue-50/30' : ''}`}>
                            <div className={`w-2 h-2 rounded-full mt-1.5 shrink-0 ${!n.isRead ? 'bg-blue-500' : 'bg-transparent'}`}></div>
                            <div className="flex-1">
                              <div className="flex justify-between items-start mb-0.5">
                                <h4 className={`text-sm font-semibold ${!n.isRead ? 'text-slate-800' : 'text-slate-600'}`}>{n.title}</h4>
                                <span className="text-[10px] text-slate-400 whitespace-nowrap ml-2">{n.time}</span>
                              </div>
                              <p className={`text-xs ${!n.isRead ? 'text-slate-600' : 'text-slate-500'} line-clamp-2`}>{n.message}</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                  <div className="p-3 border-t border-slate-100 text-center bg-slate-50">
                    <button className="text-xs font-bold text-blue-600 hover:text-blue-700">View All Notifications</button>
                  </div>
                </div>
              )}
            </div>

            {/* Profile Dropdown */}
            <div className="relative border-l border-slate-200 pl-6" ref={profileRef}>
              <div 
                onClick={() => setShowProfileMenu(!showProfileMenu)}
                className="flex items-center space-x-3 cursor-pointer group"
              >
                <div className="text-right hidden sm:block">
                  <div className="text-sm font-bold text-slate-800">{user?.full_name || 'Loading...'}</div>
                  <div className="text-xs text-slate-500 capitalize">{user?.role || 'user'}</div>
                </div>
                <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold group-hover:bg-blue-200 transition ring-2 ring-transparent group-hover:ring-blue-100">
                  {initials}
                </div>
                <svg className={`w-4 h-4 text-slate-400 transition transform ${showProfileMenu ? 'rotate-180' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
              </div>

              {/* Profile Menu Dropdown */}
              {showProfileMenu && (
                <div className="absolute right-0 mt-3 w-56 bg-white rounded-2xl shadow-xl border border-slate-200 overflow-hidden z-50">
                  <div className="p-4 border-b border-slate-100 bg-slate-50 sm:hidden">
                     <div className="text-sm font-bold text-slate-800 truncate">{user?.full_name}</div>
                     <div className="text-xs text-slate-500 truncate">{user?.email}</div>
                  </div>
                  <div className="p-2 space-y-1">
                    <Link to="/profile" onClick={() => setShowProfileMenu(false)} className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-sm text-slate-700 hover:bg-slate-50 hover:text-blue-600 transition font-medium">
                      <User className="w-4 h-4" />
                      <span>My Profile</span>
                    </Link>
                    <Link to="/profile" onClick={() => setShowProfileMenu(false)} className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-sm text-slate-700 hover:bg-slate-50 hover:text-blue-600 transition font-medium">
                      <Settings className="w-4 h-4" />
                      <span>Account Settings</span>
                    </Link>
                  </div>
                  <div className="p-2 border-t border-slate-100">
                    <button onClick={handleLogout} className="flex items-center space-x-3 w-full px-3 py-2.5 rounded-lg text-sm text-red-600 hover:bg-red-50 transition font-medium">
                      <LogOut className="w-4 h-4" />
                      <span>Sign Out</span>
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
        
        <div className="p-8 flex-1 pb-24">
          <Outlet context={{ user }} />
        </div>
      </main>
    </div>
  );
}

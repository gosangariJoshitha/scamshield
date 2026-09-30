import { useState, useEffect } from 'react';
import { Outlet, Link, useLocation } from 'react-router-dom';
import { ShieldCheck, LayoutDashboard, Search, History, Users, User, LogOut } from 'lucide-react';
import { auth } from '../services/auth';

export default function SidebarLayout() {
  const location = useLocation();
  const path = location.pathname;

  const [user, setUser] = useState<any>(null);

  useEffect(() => {
    auth.me().then(data => setUser(data)).catch(() => {
      // If unauthorized, the protected route will handle it or we can force redirect
    });
  }, []);

  const handleLogout = () => {
    auth.logout();
    window.location.href = '/login';
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
      <main className="flex-1 overflow-auto flex flex-col">
        <div className="h-16 border-b border-slate-200 bg-white flex items-center justify-end px-8 shrink-0 shadow-sm">
          <div className="flex items-center space-x-3 cursor-pointer group">
            <div className="text-right">
              <div className="text-sm font-bold text-slate-800">{user?.full_name || 'Loading...'}</div>
              <div className="text-xs text-slate-500 capitalize">{user?.role || 'user'}</div>
            </div>
            <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold group-hover:bg-blue-200 transition">
              {initials}
            </div>
          </div>
        </div>
        <div className="p-8 flex-1">
          <Outlet context={{ user }} />
        </div>
      </main>
    </div>
  );
}

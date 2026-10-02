import React, { useState, useEffect, useRef } from 'react';
import { Outlet, Link, useLocation, useNavigate } from 'react-router-dom';
import { 
  ShieldCheck, LayoutDashboard, Search, Users, 
  User, LogOut, Settings, ShieldAlert,
  Activity, ClipboardList, Database, Menu, BookOpen
} from 'lucide-react';
import { auth } from '../services/auth';

export default function AdminLayout() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [user, setUser] = useState<any>(null);
  
  const location = useLocation();
  const navigate = useNavigate();
  const profileMenuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    auth.me().then(data => {
      setUser(data);
      // Check if user is admin
      if (!data || data.role !== 'admin') {
        navigate('/dashboard'); // Redirect non-admins to user dashboard
      }
    }).catch(() => {
      navigate('/dashboard');
    });
  }, [navigate]);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (profileMenuRef.current && !profileMenuRef.current.contains(event.target as Node)) {
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
    { name: 'Overview', path: '/admin', icon: LayoutDashboard },
    { name: 'Analyses', path: '/admin/analyses', icon: Search },
    { name: 'Human Reviews', path: '/admin/reviews', icon: ShieldAlert },
    { name: 'Community Reports', path: '/admin/community', icon: Users },
    { name: 'Knowledge Base', path: '/admin/knowledge', icon: BookOpen },
    { name: 'Users', path: '/admin/users', icon: User },
    { name: 'Monitoring', path: '/admin/monitoring', icon: Activity },
    { name: 'Audit Logs', path: '/admin/audit', icon: ClipboardList },
    { name: 'System Health', path: '/admin/health', icon: Database },
    { name: 'Settings', path: '/admin/settings', icon: Settings },
  ];

  // Get current page title
  const currentNavItem = navItems.find(item => 
    location.pathname === item.path || 
    (item.path !== '/admin' && location.pathname.startsWith(item.path))
  );
  const pageTitle = currentNavItem ? currentNavItem.name : 'Admin Operations';

  return (
    <div className="flex h-screen bg-background overflow-hidden">
      {/* Mobile sidebar backdrop */}
      {isMobileMenuOpen && (
        <div 
          className="fixed inset-0 z-40 bg-background/80 backdrop-blur-sm lg:hidden"
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside 
        className={`fixed inset-y-0 left-0 z-50 w-64 bg-card border-r border-border-light transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-0 ${
          isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="h-16 flex items-center px-6 border-b border-border-light shrink-0">
            <Link to="/admin" className="flex items-center space-x-2 group">
              <div className="bg-primary/10 p-1.5 rounded-lg group-hover:bg-primary/20 transition-colors">
                <ShieldCheck className="w-6 h-6 text-primary" />
              </div>
              <div>
                <span className="text-lg font-bold text-text-main tracking-tight block leading-tight">SCAMSHIELD</span>
                <span className="text-[10px] font-bold text-primary tracking-widest uppercase block leading-tight">ADMIN CONSOLE</span>
              </div>
            </Link>
          </div>

          {/* Nav Links */}
          <div className="flex-1 overflow-y-auto custom-scrollbar py-4 px-3 space-y-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path || (item.path !== '/admin' && location.pathname.startsWith(item.path));
              
              return (
                <Link
                  key={item.name}
                  to={item.path}
                  onClick={() => setIsMobileMenuOpen(false)}
                  className={`flex items-center space-x-3 px-3 py-2.5 rounded-xl transition-all duration-200 ${
                    isActive 
                      ? 'bg-primary/10 text-primary font-semibold' 
                      : 'text-text-secondary hover:bg-background hover:text-text-main font-medium'
                  }`}
                >
                  <Icon className={`w-5 h-5 ${isActive ? 'text-primary' : 'text-text-muted'}`} />
                  <span>{item.name}</span>
                </Link>
              );
            })}
          </div>

          {/* User Profile (Sidebar Bottom) */}
          <div className="p-4 border-t border-border-light shrink-0">
            <div className="flex items-center justify-between bg-background p-2 rounded-xl border border-border-light">
              <div className="flex items-center space-x-3 truncate">
                <div className="w-8 h-8 rounded-full bg-primary/20 text-primary flex items-center justify-center font-bold text-xs shrink-0">
                  {user?.full_name ? user.full_name.charAt(0).toUpperCase() : 'A'}
                </div>
                <div className="truncate">
                  <p className="text-sm font-bold text-text-main truncate">{user?.full_name || 'Admin User'}</p>
                  <p className="text-[10px] text-text-muted font-semibold uppercase tracking-wider">Administrator</p>
                </div>
              </div>
              <button 
                onClick={handleLogout}
                className="p-1.5 text-text-muted hover:text-danger hover:bg-danger/10 rounded-lg transition-colors"
                title="Logout"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-w-0 overflow-hidden bg-background">
        {/* Topbar */}
        <header className="h-16 flex items-center justify-between px-4 sm:px-6 lg:px-8 border-b border-border-light bg-card shrink-0">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setIsMobileMenuOpen(true)}
              className="p-2 text-text-secondary hover:text-text-main hover:bg-background rounded-lg lg:hidden transition-colors"
            >
              <Menu className="w-5 h-5" />
            </button>
            <h1 className="text-xl font-bold text-text-main hidden sm:block">{pageTitle}</h1>
          </div>

          <div className="flex items-center space-x-2 sm:space-x-4">
            {/* Profile Dropdown */}
            <div className="relative" ref={profileMenuRef}>
              <button 
                onClick={() => setShowProfileMenu(!showProfileMenu)}
                className="flex items-center justify-center w-8 h-8 rounded-full bg-primary/10 text-primary font-bold text-sm hover:bg-primary/20 transition-colors"
              >
                {user?.full_name ? user.full_name.charAt(0).toUpperCase() : 'A'}
              </button>
              
              {showProfileMenu && (
                <div className="absolute right-0 mt-2 w-48 bg-card rounded-xl shadow-lg border border-border-light py-1 z-50">
                  <div className="px-4 py-2 border-b border-border-light mb-1">
                    <p className="text-sm font-bold text-text-main truncate">{user?.full_name || 'Admin User'}</p>
                    <p className="text-xs font-medium text-text-muted truncate">{user?.email || ''}</p>
                  </div>
                  <Link to="/admin/settings" onClick={() => setShowProfileMenu(false)} className="flex items-center px-4 py-2 text-sm font-semibold text-text-secondary hover:bg-background hover:text-primary transition-colors">
                    <Settings className="w-4 h-4 mr-3" />
                    Admin Settings
                  </Link>
                  <button onClick={handleLogout} className="w-full flex items-center px-4 py-2 text-sm font-semibold text-danger hover:bg-danger/5 transition-colors mt-1 border-t border-border-light pt-2">
                    <LogOut className="w-4 h-4 mr-3" />
                    Logout
                  </button>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Page Content */}
        <div className="flex-1 overflow-auto custom-scrollbar">
          <div className="p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto w-full">
            <Outlet />
          </div>
        </div>
      </main>
    </div>
  );
}

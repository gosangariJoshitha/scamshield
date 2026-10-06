import { useState, useEffect, useRef } from 'react';
import { Outlet, Link, useLocation, useNavigate } from 'react-router-dom';
import { 
  ShieldCheck, LayoutDashboard, Search, History, Users,
  User, LogOut, Settings, PanelLeftClose,
  Moon, Sun, Menu, X
} from 'lucide-react';
import { auth } from '../services/auth';
import { useTheme } from '../hooks/useTheme';

export default function SidebarLayout() {
  const location = useLocation();
  const navigate = useNavigate();
  const path = location.pathname;

  const [user, setUser] = useState<any>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(
    () => window.localStorage.getItem('scamshield-sidebar-collapsed') === 'true'
  );
  const { theme, toggleTheme } = useTheme();
  
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  
  const profileRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    window.localStorage.setItem('scamshield-sidebar-collapsed', String(sidebarCollapsed));
  }, [sidebarCollapsed]);

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

  const positionCollapsedTooltip = (trigger: HTMLElement) => {
    const tooltip = trigger.querySelector<HTMLElement>('.sidebar-layout__tooltip');
    if (!tooltip) return;

    const bounds = trigger.getBoundingClientRect();
    tooltip.style.left = `${bounds.right + 12}px`;
    tooltip.style.top = `${bounds.top + bounds.height / 2}px`;
  };

  const navItems = [
    { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard, section: 'Main' },
    { name: 'Analyze', path: '/analyze', icon: Search, section: 'Main' },
    { name: 'History', path: '/history', icon: History, section: 'Main' },
    { name: 'Community', path: '/community', icon: Users, section: 'Main' },
    { name: 'Profile', path: '/profile', icon: User, section: 'Account' },
    { name: 'Settings', path: '/profile/settings', icon: Settings, section: 'System' },
  ];

  return (
    <div className="flex h-screen min-w-0 overflow-hidden bg-background text-text-main font-sans">
      {mobileNavOpen && (
        <button
          type="button"
          aria-label="Close navigation menu"
          onClick={() => setMobileNavOpen(false)}
          className="fixed inset-0 z-30 bg-black/40 md:hidden"
        />
      )}
      <aside
        data-collapsed={sidebarCollapsed}
        className={`sidebar-layout__sidebar fixed inset-y-0 left-0 z-40 flex h-full w-72 shrink-0 flex-col border-r border-slate-700/70 bg-midnight text-slate-100 shadow-sm transition-[width,transform] duration-200 ease-in-out md:translate-x-0 ${mobileNavOpen ? 'translate-x-0' : '-translate-x-full'}`}
      >
        <div className="sidebar-layout__header relative mb-2 flex min-h-20 items-center justify-between gap-2 border-b border-slate-700/70 px-4">
          <Link to="/dashboard" onClick={() => setMobileNavOpen(false)} aria-label="ScamShield dashboard" className="sidebar-layout__brand flex min-w-0 items-center gap-2 rounded-lg px-2 py-2 hover:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary">
            <ShieldCheck className="sidebar-layout__brand-icon h-8 w-8 shrink-0 text-primary-light" />
            <span className="sidebar-layout__brand-label min-w-0">
              <span className="block truncate text-sm font-extrabold tracking-wide text-white">ScamShield</span>
              <span className="sidebar-layout__portal-label block text-[11px] font-medium text-slate-400">User Portal</span>
            </span>
          </Link>
          <button
            type="button"
            onClick={() => setMobileNavOpen(false)}
            aria-label="Close navigation menu"
            className="absolute right-3 rounded-lg p-2 text-slate-400 transition-colors hover:bg-slate-800 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary md:hidden"
          >
            <X className="h-5 w-5" />
          </button>
          <div className="sidebar-layout__toggle-slot hidden md:grid" aria-label="Sidebar controls">
            <button
              type="button"
              onClick={() => setSidebarCollapsed(collapsed => !collapsed)}
              aria-label={sidebarCollapsed ? 'Open sidebar' : 'Close sidebar'}
              aria-expanded={!sidebarCollapsed}
              onMouseEnter={(event) => positionCollapsedTooltip(event.currentTarget)}
              onFocus={(event) => positionCollapsedTooltip(event.currentTarget)}
              className="sidebar-layout__toggle group relative rounded-full p-2 text-slate-400 transition-colors hover:bg-slate-800 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            >
              <PanelLeftClose
                className={`h-5 w-5 transition-transform duration-200 ${sidebarCollapsed ? 'rotate-180' : ''}`}
                aria-hidden="true"
              />
              <span role="tooltip" className="sidebar-layout__tooltip pointer-events-none fixed left-0 top-0 z-50 -translate-y-1/2 translate-x-1 whitespace-nowrap rounded-md bg-slate-950 px-2.5 py-1.5 text-xs font-semibold text-white opacity-0 shadow-lg transition duration-150 group-hover:translate-x-0 group-hover:opacity-100 group-focus-visible:translate-x-0 group-focus-visible:opacity-100">
                {sidebarCollapsed ? 'Open sidebar' : 'Close sidebar'}
              </span>
            </button>
          </div>
        </div>
        <nav aria-label="Main navigation" className="sidebar-layout__nav flex-1 space-y-4 overflow-x-hidden overflow-y-auto px-3 py-2">
          {navItems.map((item, index) => {
            const source = location.state?.from;
            const isActive = path === item.path
              || (path.startsWith('/results') && (source === item.path || (!source && item.path === '/analyze')));
            const isNewSection = index === 0 || item.section !== navItems[index - 1].section;
            return (
              <div key={item.path}>
                {isNewSection && (
                  <p className="sidebar-layout__section-label mb-2 px-3 text-[10px] font-bold uppercase tracking-[0.16em] text-slate-400">
                    {item.section}
                  </p>
                )}
                <Link
                  to={item.path}
                  onClick={() => setMobileNavOpen(false)}
                  aria-label={item.name}
                  aria-current={isActive ? 'page' : undefined}
                  onMouseEnter={(event) => positionCollapsedTooltip(event.currentTarget)}
                  onFocus={(event) => positionCollapsedTooltip(event.currentTarget)}
                  className={`sidebar-layout__nav-link group relative flex h-12 items-center gap-3 rounded-xl border border-transparent px-3 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary ${isActive ? 'border-primary/20 bg-primary/20 font-bold text-white before:absolute before:bottom-2 before:left-0 before:top-2 before:w-0.5 before:rounded-full before:bg-primary-light' : 'text-slate-300 hover:bg-slate-800/80 hover:text-white'}`}
                >
                  <item.icon className={`h-6 w-6 shrink-0 ${isActive ? 'text-primary-light' : 'text-slate-400 group-hover:text-white'}`} aria-hidden="true" />
                  <span className="sidebar-layout__nav-label truncate text-sm font-semibold">{item.name}</span>
                  {sidebarCollapsed && (
                    <span role="tooltip" className="sidebar-layout__tooltip pointer-events-none fixed left-0 top-0 z-50 -translate-y-1/2 translate-x-1 whitespace-nowrap rounded-md bg-slate-950 px-2.5 py-1.5 text-xs font-semibold text-white opacity-0 shadow-lg transition duration-150 group-hover:translate-x-0 group-hover:opacity-100 group-focus-visible:translate-x-0 group-focus-visible:opacity-100">
                      {item.name}
                    </span>
                  )}
                </Link>
              </div>
            );
          })}
        </nav>
        <div className="mt-auto border-t border-slate-700/70 p-3">
          <button onClick={handleLogout} onMouseEnter={(event) => positionCollapsedTooltip(event.currentTarget)} onFocus={(event) => positionCollapsedTooltip(event.currentTarget)} aria-label="Logout" className="sidebar-layout__nav-link group relative flex h-12 w-full items-center gap-3 rounded-xl px-3 text-slate-300 transition-colors hover:bg-danger/10 hover:text-danger focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary">
            <LogOut className="h-6 w-6 shrink-0" aria-hidden="true" />
            <span className="sidebar-layout__logout-label text-sm font-semibold">Logout</span>
            {sidebarCollapsed && (
              <span role="tooltip" className="sidebar-layout__tooltip pointer-events-none fixed left-0 top-0 z-50 -translate-y-1/2 translate-x-1 whitespace-nowrap rounded-md bg-slate-950 px-2.5 py-1.5 text-xs font-semibold text-white opacity-0 shadow-lg transition duration-150 group-hover:translate-x-0 group-hover:opacity-100 group-focus-visible:translate-x-0 group-focus-visible:opacity-100">
                Logout
              </span>
            )}
          </button>
        </div>
      </aside>
      
      <main className={`@container relative flex h-screen min-w-0 flex-1 flex-col overflow-x-hidden overflow-y-auto transition-[margin] duration-200 ease-in-out ${sidebarCollapsed ? 'md:ml-20' : 'md:ml-[17rem]'}`}>
        <div className="sidebar-layout__topbar relative sticky top-0 z-10 flex h-16 shrink-0 items-center justify-between gap-3 border-b border-border-light bg-card px-4 shadow-sm @content-sm:px-8">
          <button
            type="button"
            onClick={() => setMobileNavOpen(true)}
            aria-label="Open navigation menu"
            aria-expanded={mobileNavOpen}
            className="p-2 -ml-2 text-text-muted hover:bg-background hover:text-text-main rounded-lg transition-colors md:hidden"
          >
            <Menu className="w-5 h-5" />
          </button>
          {/* Top Header Search */}
          <div className="sidebar-layout__search flex min-w-0 flex-1 items-center">
            <div className="relative w-full max-w-[520px]">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && searchQuery.trim()) {
                    navigate(`/history?q=${encodeURIComponent(searchQuery)}`);
                  }
                }}
                aria-label="Search analyses, reports, or anything"
                placeholder="Search analyses, reports, or anything..."
                className="block w-full pl-4 pr-12 py-2 border border-border-light rounded-xl leading-5 bg-background placeholder:text-text-muted focus:outline-none focus:bg-card focus:ring-[3px] focus:ring-primary/20 focus:border-primary @content-sm:text-sm font-semibold transition-colors text-text-main"
              />
              <div className="absolute inset-y-0 right-0 pr-2 flex items-center">
                <button 
                  onClick={() => {
                    if (searchQuery.trim()) {
                      navigate(`/history?q=${encodeURIComponent(searchQuery)}`);
                    }
                  }}
                  aria-label="Search"
                  className="p-1.5 hover:bg-border-light text-text-muted hover:text-primary rounded-lg transition-colors focus:outline-none"
                  title="Search"
                >
                  <Search className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
          
          <div className="ml-auto flex shrink-0 items-center space-x-2 sm:space-x-6">
            {/* Theme Toggle */}
            <button
              onClick={toggleTheme}
              className="p-2 text-text-muted hover:bg-background hover:text-text-main rounded-full transition-colors"
              aria-label="Toggle Dark Mode"
            >
              {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            </button>
            
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
        
        <div className="p-4 @content-sm:p-8 flex-1 pb-24 max-w-7xl mx-auto w-full">
          <Outlet context={{ user }} />
        </div>
      </main>
    </div>
  );
}

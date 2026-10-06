import { FormEvent, useEffect, useRef, useState } from 'react';
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom';
import {
  Activity, BookOpen, ClipboardList, LayoutDashboard, LogOut, Menu, Moon,
  PanelLeftClose, Search, Settings, ShieldAlert, ShieldCheck, Sun, User, Users, UserRound, X
} from 'lucide-react';
import { auth } from '../services/auth';
import { hasToken } from '../services/token';
import { useTheme } from '../hooks/useTheme';

type AdminUser = {
  full_name?: string;
  email?: string;
  role?: string;
  is_active?: boolean;
};

const navigation = [
  { name: 'Dashboard', path: '/admin', icon: LayoutDashboard },
  { name: 'Analyses', path: '/admin/analyses', icon: ClipboardList },
  { name: 'Human Review', path: '/admin/reviews', icon: ShieldAlert },
  { name: 'Community', path: '/admin/community', icon: Users },
  { name: 'Knowledge Base', path: '/admin/knowledge', icon: BookOpen },
  { name: 'Users', path: '/admin/users', icon: UserRound },
  { name: 'Monitoring', path: '/admin/monitoring', icon: Activity },
  { name: 'Audit Log', path: '/admin/audit', icon: ClipboardList },
];

function isNavigationItemActive(pathname: string, itemPath: string) {
  if (itemPath === '/admin') return pathname === itemPath;
  return pathname === itemPath || pathname.startsWith(`${itemPath}/`);
}

export default function AdminLayout() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(
    () => window.localStorage.getItem('scamshield-sidebar-collapsed') === 'true'
  );
  const [user, setUser] = useState<AdminUser | null>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [authError, setAuthError] = useState<string | null>(null);
  const [searchValue, setSearchValue] = useState('');
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const profileRef = useRef<HTMLDivElement>(null);
  const location = useLocation();
  const navigate = useNavigate();
  const { theme, toggleTheme } = useTheme();

  useEffect(() => {
    window.localStorage.setItem('scamshield-sidebar-collapsed', String(sidebarCollapsed));
  }, [sidebarCollapsed]);

  useEffect(() => {
    setSearchValue(new URLSearchParams(location.search).get('search') ?? '');
  }, [location.search]);

  // Handle clicking outside to close profile dropdown
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (profileRef.current && !profileRef.current.contains(event.target as Node)) {
        setShowProfileMenu(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  useEffect(() => {
    let active = true;
    const loadAdmin = async () => {
      try {
        const profile = await auth.me() as AdminUser;
        if (!active) return;
        if (profile?.role !== 'admin' || profile.is_active === false) {
          setAuthError('Admin access is required for this page.');
          return;
        }
        setUser(profile);
        setAuthError(null);
      } catch (error) {
        if (!active) return;
        const status = (error as { response?: { status?: number } })?.response?.status;
        if (status === 401 || status === 403) {
          auth.logout();
          navigate('/admin/login', { replace: true });
        } else {
          setAuthError('Unable to verify your admin session. Check your connection and retry.');
        }
      } finally {
        if (active) setAuthLoading(false);
      }
    };
    if (!hasToken()) {
      navigate('/admin/login', { replace: true });
      return;
    }
    void loadAdmin();
    return () => { active = false; };
  }, [navigate]);

  const handleLogout = () => {
    auth.logout();
    navigate('/admin/login', { replace: true });
  };

  const positionCollapsedTooltip = (trigger: HTMLElement) => {
    const tooltip = trigger.querySelector<HTMLElement>('.sidebar-layout__tooltip');
    if (!tooltip) return;
    const bounds = trigger.getBoundingClientRect();
    tooltip.style.left = `${bounds.right + 12}px`;
    tooltip.style.top = `${bounds.top + bounds.height / 2}px`;
  };

  const submitSearch = (event?: FormEvent<HTMLFormElement> | React.KeyboardEvent | React.MouseEvent) => {
    if (event && 'preventDefault' in event) event.preventDefault();
    const query = searchValue.trim();
    const pathname = location.pathname;
    const target = pathname.startsWith('/admin/users') ? '/admin/users'
      : pathname.startsWith('/admin/community') ? '/admin/community'
      : pathname.startsWith('/admin/reviews') ? '/admin/reviews'
      : pathname.startsWith('/admin/knowledge') ? '/admin/knowledge'
      : pathname.startsWith('/admin/audit') ? '/admin/audit'
      : '/admin/analyses';
    navigate(query ? `${target}?search=${encodeURIComponent(query)}` : target);
    setIsMobileMenuOpen(false);
  };

  if (authLoading || !user) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background p-6">
        <div className="w-full max-w-md rounded-2xl border border-border-light bg-card p-6 text-center shadow-sm">
          {authLoading ? (
            <>
              <div className="mx-auto h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
              <p className="mt-4 text-sm font-medium text-text-secondary">Verifying administrator access…</p>
            </>
          ) : (
            <>
              <p role="alert" className="text-sm font-medium text-danger">{authError}</p>
              <button
                onClick={() => window.location.reload()}
                className="mt-4 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-primary-hover"
              >
                Retry
              </button>
              <button
                onClick={handleLogout}
                className="ml-2 rounded-lg border border-border-light px-4 py-2 text-sm font-semibold text-text-secondary hover:bg-background"
              >
                Sign in
              </button>
            </>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen overflow-hidden bg-background text-text-main">
      {isMobileMenuOpen && (
        <button
          type="button"
          aria-label="Close navigation menu"
          className="fixed inset-0 z-40 bg-midnight/60 backdrop-blur-sm md:hidden"
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}

      <aside data-collapsed={sidebarCollapsed} className={`sidebar-layout__sidebar admin-layout__sidebar fixed inset-y-0 left-0 z-50 flex h-full w-72 shrink-0 flex-col border-r border-slate-700/70 bg-midnight text-slate-100 shadow-sm transition-[width,transform] duration-200 ease-in-out md:translate-x-0 ${
        isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full'
      }`}>
        <div className="sidebar-layout__header admin-layout__brand-header group relative mb-2 flex min-h-20 items-center justify-between gap-2 border-b border-slate-700/70 px-4">
          <div aria-label="ScamShield admin portal" className="sidebar-layout__brand flex min-w-0 items-center gap-2 rounded-lg px-2 py-2">
            <ShieldCheck className="sidebar-layout__brand-icon h-8 w-8 shrink-0 text-primary-light" aria-hidden="true" />
            <span className="sidebar-layout__brand-label min-w-0">
              <span className="block truncate text-sm font-extrabold tracking-wide text-white">ScamShield</span>
              <span className="block text-[11px] font-medium text-slate-400">Admin Portal</span>
            </span>
          </div>
          <button
            type="button"
            className="rounded-lg p-2 text-slate-400 transition-colors hover:bg-slate-800 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary md:hidden"
            onClick={() => setIsMobileMenuOpen(false)}
            aria-label="Close navigation menu"
          >
            <X className="h-5 w-5" />
          </button>
          <div className="admin-layout__toggle-slot hidden md:grid" aria-label="Sidebar controls">
            <button
              type="button"
              onClick={() => setSidebarCollapsed((collapsed) => !collapsed)}
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

        <nav aria-label="Admin navigation" className="sidebar-layout__nav admin-layout__nav flex-1 space-y-1 overflow-x-hidden overflow-y-auto px-3 py-2">
          {navigation.map(({ name, path, icon: Icon }) => {
            const active = isNavigationItemActive(location.pathname, path);
            return (
              <Link
                key={path}
                to={path}
                onClick={() => setIsMobileMenuOpen(false)}
                aria-current={active ? 'page' : undefined}
                onMouseEnter={(event) => positionCollapsedTooltip(event.currentTarget)}
                onFocus={(event) => positionCollapsedTooltip(event.currentTarget)}
                aria-label={name}
                className={`sidebar-layout__nav-link group relative flex h-12 items-center gap-3 rounded-xl border border-transparent px-3 text-sm font-semibold transition-colors hover:bg-slate-800/80 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary ${
                  active
                    ? 'border-primary/20 bg-primary/20 font-bold text-white before:absolute before:bottom-2 before:left-0 before:top-2 before:w-0.5 before:rounded-full before:bg-primary-light'
                    : 'text-slate-300'
                }`}
              >
                <Icon className={`h-6 w-6 shrink-0 transition-colors ${
                  active ? 'text-primary-light' : 'text-slate-400 group-hover:text-white'
                }`} aria-hidden="true" />
                <span className="sidebar-layout__nav-label truncate">{name}</span>
                {sidebarCollapsed && (
                  <span role="tooltip" className="sidebar-layout__tooltip pointer-events-none fixed left-0 top-0 z-50 -translate-y-1/2 translate-x-1 whitespace-nowrap rounded-md bg-slate-950 px-2.5 py-1.5 text-xs font-semibold text-white opacity-0 shadow-lg transition duration-150 group-hover:translate-x-0 group-hover:opacity-100 group-focus-visible:translate-x-0 group-focus-visible:opacity-100">
                    {name}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>

        <div className="mt-auto space-y-3 border-t border-slate-700/70 p-3">
          <Link
            to="/admin/settings"
            onClick={() => setIsMobileMenuOpen(false)}
            aria-current={isNavigationItemActive(location.pathname, '/admin/settings') ? 'page' : undefined}
            onMouseEnter={(event) => positionCollapsedTooltip(event.currentTarget)}
            onFocus={(event) => positionCollapsedTooltip(event.currentTarget)}
            aria-label="Settings"
            className={`sidebar-layout__nav-link group relative flex h-12 items-center gap-3 rounded-xl border border-transparent px-3 text-sm font-semibold transition-colors hover:bg-slate-800/80 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary ${
              isNavigationItemActive(location.pathname, '/admin/settings')
                ? 'border-primary/20 bg-primary/20 font-bold text-white before:absolute before:bottom-2 before:left-0 before:top-2 before:w-0.5 before:rounded-full before:bg-primary-light'
                : 'text-slate-300'
            }`}
          >
            <Settings className={`h-6 w-6 shrink-0 transition-colors ${
              isNavigationItemActive(location.pathname, '/admin/settings')
                ? 'text-primary-light'
                : 'text-slate-400 group-hover:text-white'
            }`} aria-hidden="true" />
            <span className="sidebar-layout__nav-label">Settings</span>
            {sidebarCollapsed && (
              <span role="tooltip" className="sidebar-layout__tooltip pointer-events-none fixed left-0 top-0 z-50 -translate-y-1/2 translate-x-1 whitespace-nowrap rounded-md bg-slate-950 px-2.5 py-1.5 text-xs font-semibold text-white opacity-0 shadow-lg transition duration-150 group-hover:translate-x-0 group-hover:opacity-100 group-focus-visible:translate-x-0 group-focus-visible:opacity-100">
                Settings
              </span>
            )}
          </Link>

          <button
            type="button"
            onClick={handleLogout}
            onMouseEnter={(event) => positionCollapsedTooltip(event.currentTarget)}
            onFocus={(event) => positionCollapsedTooltip(event.currentTarget)}
            aria-label="Log out"
            className="sidebar-layout__nav-link group relative flex h-12 w-full items-center gap-3 rounded-xl px-3 text-slate-300 transition-colors hover:bg-danger/10 hover:text-danger focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
          >
            <LogOut className="h-6 w-6 shrink-0" aria-hidden="true" />
            <span className="sidebar-layout__nav-label text-sm font-semibold">Log out</span>
            {sidebarCollapsed && (
              <span role="tooltip" className="sidebar-layout__tooltip pointer-events-none fixed left-0 top-0 z-50 -translate-y-1/2 translate-x-1 whitespace-nowrap rounded-md bg-slate-950 px-2.5 py-1.5 text-xs font-semibold text-white opacity-0 shadow-lg transition duration-150 group-hover:translate-x-0 group-hover:opacity-100 group-focus-visible:translate-x-0 group-focus-visible:opacity-100">
                Log out
              </span>
            )}
          </button>
        </div>
      </aside>

      <main className={`@container flex h-screen min-w-0 flex-1 flex-col overflow-x-hidden transition-[margin] duration-200 ease-in-out ${sidebarCollapsed ? 'md:ml-20' : 'md:ml-[17rem]'}`}>
        <div className="sidebar-layout__topbar relative sticky top-0 z-30 flex h-16 shrink-0 items-center justify-between gap-3 border-b border-border-light bg-card px-4 shadow-sm @content-sm:px-8">
          <button
            type="button"
            onClick={() => setIsMobileMenuOpen(true)}
            aria-label="Open navigation menu"
            aria-expanded={isMobileMenuOpen}
            className="p-2 -ml-2 text-text-muted hover:bg-background hover:text-text-main rounded-lg transition-colors md:hidden"
          >
            <Menu className="w-5 h-5" />
          </button>

          {/* Top Header Search */}
          <div className="sidebar-layout__search flex min-w-0 flex-1 items-center justify-center">
            <div className="relative w-full max-w-[520px]">
              <input
                type="text"
                value={searchValue}
                onChange={(e) => setSearchValue(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    submitSearch(e);
                  }
                }}
                aria-label="Search analyses, reviews, users, or anything"
                placeholder="Search analyses, reviews, users, or anything..."
                className="block w-full pl-4 pr-12 py-2 border border-border-light rounded-xl leading-5 bg-background placeholder:text-text-muted focus:outline-none focus:bg-card focus:ring-[3px] focus:ring-primary/20 focus:border-primary @content-sm:text-sm font-semibold transition-colors text-text-main"
              />
              <div className="absolute inset-y-0 right-0 pr-2 flex items-center">
                <button
                  type="button"
                  onClick={(e) => submitSearch(e)}
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

            {/* Admin Profile Dropdown */}
            <div className="relative" ref={profileRef}>
              <button
                type="button"
                onClick={() => setShowProfileMenu(!showProfileMenu)}
                className="w-10 h-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold hover:bg-primary/20 transition-colors focus:outline-none"
                aria-label="Admin Profile Menu"
              >
                {user?.full_name ? user.full_name.charAt(0).toUpperCase() : <User className="w-5 h-5" />}
              </button>

              {showProfileMenu && (
                <div className="absolute right-0 mt-2 w-48 bg-card rounded-xl shadow-lg border border-border-light py-1 z-50">
                  <div className="px-4 py-2 border-b border-border-light mb-1">
                    <p className="text-sm font-bold text-text-main truncate">{user?.full_name || 'Admin'}</p>
                    <p className="text-xs font-medium text-text-muted truncate">{user?.email || ''}</p>
                  </div>
                  <Link to="/admin/settings" onClick={() => setShowProfileMenu(false)} className="flex items-center px-4 py-2 text-sm font-semibold text-text-secondary hover:bg-background hover:text-primary transition-colors">
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

        <div className="min-h-0 flex-1 overflow-auto">
          <div className="mx-auto w-full max-w-[1600px] p-4 @content-sm:p-6 @content-xl:p-7">
            <Outlet key={`${location.pathname}${location.search}`} />
          </div>
        </div>
      </main>
    </div>
  );
}

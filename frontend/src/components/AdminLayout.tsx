import { FormEvent, useEffect, useMemo, useRef, useState } from 'react';
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom';
import {
  Activity, BookOpen, ChevronDown, ClipboardList, LayoutDashboard,
  LogOut, Menu, Moon, Search, Settings, ShieldAlert, ShieldCheck, Sun, Users, UserRound, X
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
  { name: 'Human Review', path: '/admin/reviews', icon: ShieldAlert },
  { name: 'Community', path: '/admin/community', icon: Users },
  { name: 'Knowledge Base', path: '/admin/knowledge', icon: BookOpen },
  { name: 'Users', path: '/admin/users', icon: UserRound },
  { name: 'Monitoring', path: '/admin/monitoring', icon: Activity },
];

function getPageTitle(pathname: string) {
  const selected = navigation.find((item) =>
    item.path === '/admin' ? pathname === item.path : pathname.startsWith(item.path)
  );
  if (pathname.startsWith('/admin/settings')) return 'Settings';
  if (pathname.startsWith('/admin/audit')) return 'Audit Log';
  if (pathname.startsWith('/admin/analyses')) return 'Analysis Details';
  return selected?.name ?? 'Admin Portal';
}

export default function AdminLayout() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [user, setUser] = useState<AdminUser | null>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [authError, setAuthError] = useState<string | null>(null);
  const [searchValue, setSearchValue] = useState('');
  const location = useLocation();
  const navigate = useNavigate();
  const { theme, toggleTheme } = useTheme();
  const profileMenuRef = useRef<HTMLDivElement>(null);
  const pageTitle = useMemo(() => getPageTitle(location.pathname), [location.pathname]);

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

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (profileMenuRef.current && !profileMenuRef.current.contains(event.target as Node)) {
        setShowProfileMenu(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleLogout = () => {
    auth.logout();
    navigate('/admin/login', { replace: true });
  };

  const submitSearch = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const query = searchValue.trim();
    if (!query) return;
    const pathname = location.pathname;
    const target = pathname.startsWith('/admin/users') ? '/admin/users'
      : pathname.startsWith('/admin/community') ? '/admin/community'
      : pathname.startsWith('/admin/reviews') ? '/admin/reviews'
      : pathname.startsWith('/admin/knowledge') ? '/admin/knowledge'
      : '/admin/analyses';
    navigate(`${target}?search=${encodeURIComponent(query)}`);
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
    <div className="flex min-h-screen overflow-hidden bg-background text-text-main">
      {isMobileMenuOpen && (
        <button
          type="button"
          aria-label="Close navigation"
          className="fixed inset-0 z-40 bg-midnight/60 backdrop-blur-sm lg:hidden"
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}

      <aside className={`fixed inset-y-0 left-0 z-50 flex w-56 flex-col bg-midnight text-slate-100 transition-transform duration-200 lg:static lg:translate-x-0 ${
        isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full'
      }`}>
        <div className="flex h-[68px] items-center gap-3 border-b border-slate-700/70 px-5">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/15 text-primary-light">
            <ShieldCheck size={22} aria-hidden="true" />
          </div>
          <div className="min-w-0">
            <p className="truncate text-sm font-extrabold tracking-wide text-white">ScamShield</p>
            <p className="text-[11px] font-medium text-slate-400">Admin Portal</p>
          </div>
          <button
            type="button"
            className="ml-auto rounded-md p-1 text-slate-400 hover:bg-slate-800 lg:hidden"
            onClick={() => setIsMobileMenuOpen(false)}
            aria-label="Close menu"
          >
            <X size={17} />
          </button>
        </div>

        <nav aria-label="Admin navigation" className="flex-1 space-y-1 overflow-y-auto px-3 py-5">
          {navigation.map(({ name, path, icon: Icon }) => {
            const active = path === '/admin'
              ? location.pathname === path
              : location.pathname.startsWith(path);
            return (
              <Link
                key={path}
                to={path}
                onClick={() => setIsMobileMenuOpen(false)}
                aria-current={active ? 'page' : undefined}
                className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-[13px] font-semibold transition-colors ${
                  active
                    ? 'bg-primary/20 text-primary-light'
                    : 'text-slate-300 hover:bg-slate-800/80 hover:text-white'
                }`}
              >
                <Icon size={18} aria-hidden="true" />
                <span>{name}</span>
              </Link>
            );
          })}
        </nav>

        <div className="space-y-3 border-t border-slate-700/70 p-3">
          <Link
            to="/admin/settings"
            onClick={() => setIsMobileMenuOpen(false)}
            className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-[13px] font-semibold transition-colors ${
              location.pathname.startsWith('/admin/settings')
                ? 'bg-primary/20 text-primary-light'
                : 'text-slate-300 hover:bg-slate-800/80 hover:text-white'
            }`}
          >
            <Settings size={18} aria-hidden="true" />
            Settings
          </Link>

          <div className="flex items-center gap-2 rounded-lg border border-slate-700 bg-slate-900/70 p-2.5">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/20 text-sm font-bold text-primary-light">
              {(user.full_name || user.email || 'A').charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-xs font-semibold text-white">{user.full_name || 'Administrator'}</p>
              <p className="truncate text-[10px] text-slate-400">{user.email}</p>
            </div>
            <button
              type="button"
              onClick={handleLogout}
              title="Log out"
              aria-label="Log out"
              className="rounded-md p-1.5 text-slate-400 transition hover:bg-slate-800 hover:text-white"
            >
              <LogOut size={16} />
            </button>
          </div>
        </div>
      </aside>

      <main className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-[68px] shrink-0 items-center justify-between gap-3 border-b border-border-light bg-card/95 px-4 backdrop-blur sm:px-6">
          <div className="flex min-w-0 items-center gap-3">
            <button
              type="button"
              onClick={() => setIsMobileMenuOpen(true)}
              aria-label="Open navigation"
              className="rounded-lg p-2 text-text-secondary hover:bg-background lg:hidden"
            >
              <Menu size={19} />
            </button>
            <form onSubmit={submitSearch} role="search" className="relative hidden w-full max-w-lg sm:block">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
              <input
                value={searchValue}
                onChange={(event) => setSearchValue(event.target.value)}
                aria-label={`Search ${pageTitle.toLowerCase()}`}
                placeholder={`Search ${pageTitle.toLowerCase()}…`}
                className="h-10 w-full rounded-lg border border-border-light bg-background pl-9 pr-3 text-sm text-text-main outline-none transition placeholder:text-text-muted focus:border-primary focus:ring-2 focus:ring-primary/15"
              />
            </form>
            <h1 className="truncate text-sm font-bold text-text-main sm:hidden">{pageTitle}</h1>
          </div>

          <div className="flex shrink-0 items-center gap-2 sm:gap-3">
            <button
              type="button"
              onClick={toggleTheme}
              aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
              title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
              className="rounded-lg border border-border-light p-2 text-text-secondary transition hover:bg-background hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            >
              {theme === 'dark' ? <Sun size={17} /> : <Moon size={17} />}
            </button>
            <span className="hidden text-sm font-semibold text-text-main md:inline">{pageTitle}</span>
            <div className="relative" ref={profileMenuRef}>
              <button
                type="button"
                onClick={() => setShowProfileMenu((open) => !open)}
                aria-expanded={showProfileMenu}
                aria-label="Open admin profile menu"
                className="flex items-center gap-2 rounded-lg p-1.5 text-text-secondary transition hover:bg-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
              >
                <span className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/15 text-sm font-bold text-primary">
                  {(user.full_name || user.email || 'A').charAt(0).toUpperCase()}
                </span>
                <ChevronDown size={15} className="hidden sm:block" />
              </button>
              {showProfileMenu && (
                <div className="absolute right-0 mt-2 w-60 rounded-xl border border-border-light bg-card p-2 shadow-xl">
                  <div className="border-b border-border-light px-3 py-2">
                    <p className="truncate text-sm font-semibold text-text-main">{user.full_name || 'Administrator'}</p>
                    <p className="truncate text-xs text-text-muted">{user.email}</p>
                  </div>
                  <Link
                    to="/admin/settings"
                    onClick={() => setShowProfileMenu(false)}
                    className="mt-1 flex items-center gap-2 rounded-lg px-3 py-2 text-sm text-text-secondary hover:bg-background hover:text-primary"
                  >
                    <Settings size={16} /> Settings
                  </Link>
                  <Link
                    to="/admin/audit"
                    onClick={() => setShowProfileMenu(false)}
                    className="flex items-center gap-2 rounded-lg px-3 py-2 text-sm text-text-secondary hover:bg-background hover:text-primary"
                  >
                    <ClipboardList size={16} /> Audit log
                  </Link>
                  <button
                    type="button"
                    onClick={handleLogout}
                    className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-sm text-danger hover:bg-danger/5"
                  >
                    <LogOut size={16} /> Log out
                  </button>
                </div>
              )}
            </div>
          </div>
        </header>

        <form onSubmit={submitSearch} role="search" className="relative mx-4 mt-3 sm:hidden">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
          <input
            value={searchValue}
            onChange={(event) => setSearchValue(event.target.value)}
            aria-label={`Search ${pageTitle.toLowerCase()}`}
            placeholder={`Search ${pageTitle.toLowerCase()}…`}
            className="h-10 w-full rounded-lg border border-border-light bg-card pl-9 pr-3 text-sm text-text-main outline-none placeholder:text-text-muted focus:border-primary focus:ring-2 focus:ring-primary/15"
          />
        </form>

        <div className="min-h-0 flex-1 overflow-auto">
          <div className="mx-auto w-full max-w-[1600px] p-4 sm:p-6 xl:p-7">
            <Outlet key={`${location.pathname}${location.search}`} />
          </div>
        </div>
      </main>
    </div>
  );
}

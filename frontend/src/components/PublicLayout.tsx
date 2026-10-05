import { Outlet, Link, useLocation } from 'react-router-dom';
import { ShieldCheck, Menu, X, ArrowRight, Moon, Sun } from 'lucide-react';
import { useState, useEffect } from 'react';
import Footer from './Footer';
import { useTheme } from '../hooks/useTheme';

export default function PublicLayout() {
  const [activeSection, setActiveSection] = useState('home');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();
  const { theme, toggleTheme } = useTheme();

  const isLandingPage = location.pathname === '/';

  useEffect(() => {
    if (!isLandingPage) return;

    const sections = ['home', 'how-it-works', 'features', 'security', 'about'];
    
    const observerOptions = {
      root: null,
      rootMargin: '-100px 0px -60% 0px',
      threshold: 0
    };

    const observerCallback = (entries: IntersectionObserverEntry[]) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          setActiveSection(entry.target.id);
        }
      });
    };

    const observer = new IntersectionObserver(observerCallback, observerOptions);

    sections.forEach((section) => {
      const element = document.getElementById(section);
      if (element) observer.observe(element);
    });

    return () => observer.disconnect();
  }, [isLandingPage]);

  const handleNavClick = (e: React.MouseEvent<HTMLAnchorElement>, targetId: string) => {
    if (isLandingPage) {
      e.preventDefault();
      const element = document.getElementById(targetId);
      if (element) {
        const offset = 80;
        const elementPosition = element.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - offset;
        
        window.scrollTo({
          top: offsetPosition,
          behavior: 'smooth'
        });
      }
      setMobileMenuOpen(false);
    }
  };

  const navItems = [
    { id: 'home', label: 'Home' },
    { id: 'how-it-works', label: 'How It Works' },
    { id: 'features', label: 'Features' },
    { id: 'security', label: 'Security' },
    { id: 'about', label: 'About' }
  ];

  return (
    <div className="public-layout flex flex-col min-h-screen bg-card text-text-main font-sans">
      <nav className="fixed top-0 left-0 right-0 z-50 bg-card border-b border-border-light shadow-[0_4px_20px_-15px_rgba(0,0,0,0.1)] h-20">
        <div className="max-w-7xl mx-auto h-full px-6 lg:px-8 flex items-center justify-between">
          
          <div className="flex items-center space-x-2 group cursor-pointer h-full" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
            <div className="bg-gradient-to-tr from-primary to-blue-400 p-1.5 rounded-xl shadow-sm text-white relative overflow-hidden group-hover:scale-105 transition-transform">
               <ShieldCheck className="w-5 h-5 relative z-10" strokeWidth={2.5} />
               <div className="absolute top-0 right-0 w-3 h-3 bg-card/20 rounded-full blur-[2px]"></div>
            </div>
            <Link 
              to="/" 
              className="text-[1.3rem] font-bold tracking-tight flex"
              onClick={(e) => {
                if (isLandingPage) e.preventDefault();
              }}
            >
              <span className="text-text-main">Scam</span>
              <span className="text-primary">Shield</span>
            </Link>
          </div>
          
          <div className="hidden xl:flex items-center space-x-8 h-full">
            {navItems.map(item => (
              <a 
                key={item.id}
                href={`/#${item.id}`}
                onClick={(e) => handleNavClick(e, item.id)}
                className={`text-sm font-bold transition-all duration-300 relative h-full flex items-center ${
                  isLandingPage && activeSection === item.id
                    ? 'text-text-main'
                    : 'text-text-muted hover:text-text-main'
                }`}
              >
                {item.label}
                {isLandingPage && activeSection === item.id && (
                  <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-8 h-[3px] bg-primary rounded-t-full" />
                )}
              </a>
            ))}
          </div>

          <div className="hidden xl:flex items-center space-x-4">
            <button
              type="button"
              onClick={toggleTheme}
              aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
              title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
              className="rounded-full border border-border-light p-2.5 text-text-secondary transition-colors hover:border-primary hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            >
              {theme === 'dark' ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
            </button>
            <Link to="/login" className="px-6 py-2.5 rounded-full text-sm font-bold text-primary border-2 border-primary hover:bg-primary/10 transition-colors">
              Login
            </Link>
            <Link to="/signup" className="bg-primary hover:bg-primary-hover px-6 py-2.5 rounded-full text-sm font-bold text-white shadow-lg shadow-primary/30 transition flex items-center space-x-1.5">
              <span>Get Started</span>
              <ArrowRight className="w-4 h-4 ml-1" />
            </Link>
          </div>

          <div className="xl:hidden flex items-center gap-2">
            <button
              type="button"
              onClick={toggleTheme}
              aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
              title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
              className="rounded-full border border-border-light p-2 text-text-secondary transition-colors hover:border-primary hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            >
              {theme === 'dark' ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
            </button>
            <button
              type="button"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label={mobileMenuOpen ? 'Close navigation menu' : 'Open navigation menu'}
              aria-expanded={mobileMenuOpen}
              className="text-text-main p-2"
            >
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {mobileMenuOpen && (
          <div className="xl:hidden absolute top-full left-0 right-0 bg-card border-b border-border-light p-4 shadow-xl flex flex-col space-y-2">
            {navItems.map(item => (
              <a 
                key={item.id}
                href={`/#${item.id}`}
                onClick={(e) => handleNavClick(e, item.id)}
                className={`text-sm font-bold transition-all p-3 rounded-xl ${
                  isLandingPage && activeSection === item.id
                    ? 'text-primary bg-primary/10'
                    : 'text-text-secondary hover:text-text-main hover:bg-background'
                }`}
              >
                {item.label}
              </a>
            ))}
            <button
              type="button"
              onClick={toggleTheme}
              className="flex items-center justify-center gap-2 rounded-full border border-border-light p-3 text-sm font-bold text-text-secondary transition hover:border-primary hover:text-primary"
            >
              {theme === 'dark' ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
              Switch to {theme === 'dark' ? 'light' : 'dark'} theme
            </button>
            <div className="flex flex-col space-y-3 pt-4 mt-2 border-t border-border-light">
              <Link to="/login" onClick={() => setMobileMenuOpen(false)} className="text-sm font-bold text-center p-3 text-primary border-2 border-primary rounded-full hover:bg-primary/10 transition">Login</Link>
              <Link to="/signup" onClick={() => setMobileMenuOpen(false)} className="bg-primary hover:bg-primary-hover p-3 rounded-full text-sm font-bold text-white text-center shadow-md transition">Get Started</Link>
            </div>
          </div>
        )}
      </nav>
      
      <main className="flex-grow flex flex-col pt-20">
        <Outlet />
      </main>
      
      <Footer />
    </div>
  );
}

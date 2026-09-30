import { Outlet, Link, useLocation } from 'react-router-dom';
import { ShieldCheck, Menu, X } from 'lucide-react';
import { useState, useEffect } from 'react';

export default function PublicLayout() {
  const [activeSection, setActiveSection] = useState('home');
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();

  const isLandingPage = location.pathname === '/';

  useEffect(() => {
    if (!isLandingPage) return;

    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
      
      // If user scrolled to the absolute bottom, activate the About section
      // since the footer might not be tall enough to trigger the IntersectionObserver
      if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight - 50) {
        setActiveSection('about');
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [isLandingPage]);

  useEffect(() => {
    if (!isLandingPage) return;

    const sections = ['home', 'how-it-works', 'features', 'security', 'about'];
    
    const observerOptions = {
      root: null,
      rootMargin: '-80px 0px -60% 0px',
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
        const offset = 70;
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
    <div className="flex flex-col min-h-screen bg-[#0a0f1c] text-white font-sans">
      <nav 
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          isScrolled 
            ? 'bg-[#0a0f1c]/90 backdrop-blur-md border-b border-slate-800/80 shadow-lg py-3' 
            : 'bg-transparent border-b border-transparent py-5'
        } px-8`}
      >
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <ShieldCheck className="w-8 h-8 text-blue-500" />
            <Link 
              to="/" 
              className="text-xl font-bold tracking-wider"
              onClick={(e) => {
                if (isLandingPage) {
                  e.preventDefault();
                  window.scrollTo({ top: 0, behavior: 'smooth' });
                }
              }}
            >
              ScamShield
            </Link>
          </div>
          
          <div className="hidden md:flex items-center space-x-8">
            {navItems.map(item => (
              <a 
                key={item.id}
                href={`/#${item.id}`}
                onClick={(e) => handleNavClick(e, item.id)}
                className={`text-sm font-medium transition-all duration-300 relative py-1 ${
                  isLandingPage && activeSection === item.id
                    ? 'text-white'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
                aria-current={isLandingPage && activeSection === item.id ? 'page' : undefined}
              >
                {item.label}
                {isLandingPage && activeSection === item.id && (
                  <span className="absolute bottom-0 left-0 w-full h-[2px] bg-blue-500 rounded-full" />
                )}
              </a>
            ))}
          </div>

          <div className="hidden md:flex space-x-4 items-center">
            <Link to="/login" className="text-sm font-medium text-slate-300 hover:text-white transition">Login</Link>
            <Link to="/signup" className="bg-blue-600 hover:bg-blue-500 px-5 py-2 rounded-lg text-sm font-bold shadow-lg shadow-blue-500/20 transition">Get Started</Link>
          </div>

          {/* Mobile menu toggle */}
          <div className="md:hidden">
            <button onClick={() => setMobileMenuOpen(!mobileMenuOpen)} className="text-slate-300 hover:text-white p-2">
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        {mobileMenuOpen && (
          <div className="md:hidden absolute top-full left-0 right-0 bg-[#0d1326] border-b border-slate-800 p-4 shadow-xl flex flex-col space-y-4">
            {navItems.map(item => (
              <a 
                key={item.id}
                href={`/#${item.id}`}
                onClick={(e) => handleNavClick(e, item.id)}
                className={`text-sm font-medium transition-all p-2 rounded-lg ${
                  isLandingPage && activeSection === item.id
                    ? 'text-white bg-slate-800/50 border-l-2 border-blue-500 pl-3'
                    : 'text-slate-400 hover:text-slate-200 pl-4'
                }`}
              >
                {item.label}
              </a>
            ))}
            <div className="flex flex-col space-y-2 pt-4 border-t border-slate-800">
              <Link to="/login" onClick={() => setMobileMenuOpen(false)} className="text-sm font-medium text-center p-2 text-slate-300 hover:text-white transition">Login</Link>
              <Link to="/signup" onClick={() => setMobileMenuOpen(false)} className="bg-blue-600 hover:bg-blue-500 px-5 py-2 rounded-lg text-sm font-bold text-center shadow-lg shadow-blue-500/20 transition">Get Started</Link>
            </div>
          </div>
        )}
      </nav>
      
      {/* Adding top padding so content doesn't jump under fixed navbar */}
      <main className="flex-grow flex flex-col pt-[72px]">
        <Outlet />
      </main>
    </div>
  );
}

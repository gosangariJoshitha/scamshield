import { Link, useLocation } from 'react-router-dom';
import { ShieldCheck, ArrowRight, Moon, Sun } from 'lucide-react';
import { useState, useEffect } from 'react';
import { useTheme } from '../hooks/useTheme';

export default function Navbar() {
  const location = useLocation();
  const [scrolled, setScrolled] = useState(false);
  const [activeSection, setActiveSection] = useState('home');
  const { theme, toggleTheme } = useTheme();

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
      
      // Simple scrollspy logic for landing page sections
      if (location.pathname === '/') {
        const sections = ['home', 'how-it-works', 'features', 'security', 'about'];
        let current = 'home';
        
        for (const section of sections) {
          const element = document.getElementById(section);
          if (element && window.scrollY >= element.offsetTop - 100) {
            current = section;
          }
        }
        setActiveSection(current);
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [location]);

  const navLinks = [
    { name: 'Home', href: '/#home', id: 'home' },
    { name: 'How It Works', href: '/#how-it-works', id: 'how-it-works' },
    { name: 'Features', href: '/#features', id: 'features' },
    { name: 'Security', href: '/#security', id: 'security' },
    { name: 'About', href: '/#about', id: 'about' }
  ];

  const handleNavClick = (href: string) => {
    if (href.startsWith('/#')) {
      const id = href.replace('/#', '');
      const element = document.getElementById(id);
      if (element) {
        window.scrollTo({ top: element.offsetTop - 80, behavior: 'smooth' });
      }
    }
  };

  return (
    <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 bg-card ${scrolled ? 'shadow-sm border-b border-border-light' : 'border-b border-transparent'}`}>
      <div className="max-w-7xl mx-auto px-6 lg:px-8">
        <div className="flex items-center justify-between h-20">
          
          {/* Logo */}
          <Link 
            to="/" 
            onClick={() => window.scrollTo(0, 0)}
            className="flex items-center space-x-2 group"
          >
            <ShieldCheck className="w-8 h-8 text-primary" />
            <span className="text-xl font-bold tracking-wide flex">
              <span className="text-text-main">SCAM</span>
              <span className="text-primary">SHIELD</span>
            </span>
          </Link>
          
          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center h-full">
            <div className="flex space-x-8 h-full">
              {navLinks.map((link) => (
                <Link 
                  key={link.name}
                  to={link.href} 
                  onClick={() => handleNavClick(link.href)}
                  className={`relative flex items-center h-full text-sm font-semibold transition-colors ${
                    activeSection === link.id && location.pathname === '/' ? 'text-primary' : 'text-text-secondary hover:text-text-main'
                  }`}
                >
                  {link.name}
                  {activeSection === link.id && location.pathname === '/' && (
                    <span className="absolute bottom-0 left-0 w-full h-0.5 bg-primary rounded-t-full"></span>
                  )}
                </Link>
              ))}
            </div>
          </div>
          
          {/* Auth Actions & Theme Toggle */}
          <div className="flex items-center space-x-4">
            <button
              onClick={toggleTheme}
              className="p-2 rounded-xl text-text-muted hover:text-text-main hover:bg-border-light/50 transition-colors"
              aria-label="Toggle Dark Mode"
            >
              {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            </button>
            <Link 
              to="/login" 
              className="hidden md:flex text-sm font-bold text-text-main hover:text-primary transition-colors py-2"
            >
              Login
            </Link>
            <Link 
              to="/signup" 
              className="bg-primary hover:bg-primary-hover text-white px-5 py-2.5 rounded-xl font-bold transition-all shadow-sm flex items-center space-x-1.5"
            >
              <span>Get Started</span>
              <ArrowRight className="w-4 h-4 hidden sm:block" />
            </Link>
          </div>
        </div>
      </div>
    </nav>
  );
}

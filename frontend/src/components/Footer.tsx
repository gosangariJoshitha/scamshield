import { Link } from 'react-router-dom';
import { ShieldCheck } from 'lucide-react';

export default function Footer() {
  return (
    <footer className="bg-card border-t border-border-light pt-20 pb-10 font-sans text-text-secondary">
      <div className="max-w-7xl mx-auto px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-12 lg:gap-8 mb-16">
          
          {/* Brand */}
          <div className="lg:col-span-2">
            <Link to="/" className="flex items-center space-x-2 mb-4 group w-max" onClick={() => window.scrollTo(0, 0)}>
              <div className="bg-gradient-to-tr from-primary to-blue-400 p-1.5 rounded-xl shadow-sm text-white group-hover:scale-105 transition-transform">
                 <ShieldCheck className="w-5 h-5" strokeWidth={2.5} />
              </div>
              <span className="text-[1.3rem] font-bold tracking-tight flex">
                <span className="text-[#0F172A]">Scam</span>
                <span className="text-primary">Shield</span>
              </span>
            </Link>
            <p className="text-text-muted text-sm leading-relaxed max-w-sm font-medium">
              Explainable AI-driven framework for real-time scam detection and risk verification.
            </p>
          </div>
          
          {/* Product */}
          <div>
            <h4 className="font-bold text-[#0F172A] mb-6 text-sm">Product</h4>
            <ul className="space-y-4">
              <li><Link to="/analyze" className="text-text-muted hover:text-primary transition-colors text-sm font-semibold">Analyze</Link></li>
              <li><Link to="/history" className="text-text-muted hover:text-primary transition-colors text-sm font-semibold">History</Link></li>
              <li><Link to="/community" className="text-text-muted hover:text-primary transition-colors text-sm font-semibold">Community</Link></li>
            </ul>
          </div>
          
          {/* Resources */}
          <div>
            <h4 className="font-bold text-[#0F172A] mb-6 text-sm">Resources</h4>
            <ul className="space-y-4">
              <li><a href="/#how-it-works" className="text-text-muted hover:text-primary transition-colors text-sm font-semibold">How it Works</a></li>
              <li><a href="/#security" className="text-text-muted hover:text-primary transition-colors text-sm font-semibold">Security</a></li>
              <li><a href="/#about" className="text-text-muted hover:text-primary transition-colors text-sm font-semibold">About</a></li>
            </ul>
          </div>
          
          {/* Account */}
          <div>
            <h4 className="font-bold text-[#0F172A] mb-6 text-sm">Account</h4>
            <ul className="space-y-4">
              <li><Link to="/login" className="text-text-muted hover:text-primary transition-colors text-sm font-semibold">Login</Link></li>
              <li><Link to="/signup" className="text-text-muted hover:text-primary transition-colors text-sm font-semibold">Create Account</Link></li>
            </ul>
          </div>

          {/* Socials */}
          <div className="flex space-x-4 lg:justify-end">
            <a href="#" className="w-10 h-10 bg-background rounded-full flex items-center justify-center text-slate-400 hover:bg-border-light hover:text-[#0F172A] transition-colors"><svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.477 2 2 6.477 2 12c0 4.42 2.865 8.166 6.839 9.49.5.092.682-.217.682-.482 0-.237-.008-.866-.013-1.7-2.782.603-3.369-1.34-3.369-1.34-.454-1.156-1.11-1.462-1.11-1.462-.908-.62.069-.608.069-.608 1.003.07 1.531 1.03 1.531 1.03.892 1.529 2.341 1.087 2.91.831.092-.646.35-1.086.636-1.336-2.22-.253-4.555-1.11-4.555-4.943 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.27.098-2.647 0 0 .84-.269 2.75 1.025A9.578 9.578 0 0112 6.836c.85.004 1.705.114 2.504.336 1.909-1.294 2.747-1.025 2.747-1.025.546 1.379.203 2.394.1 2.647.64.699 1.028 1.592 1.028 2.683 0 3.842-2.339 4.687-4.566 4.935.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.578.688.48C19.138 20.163 22 16.418 22 12c0-5.523-4.477-10-10-10z"/></svg></a>
            <a href="#" className="w-10 h-10 bg-background rounded-full flex items-center justify-center text-slate-400 hover:bg-border-light hover:text-[#0A66C2] transition-colors"><svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg></a>
            <a href="#" className="w-10 h-10 bg-background rounded-full flex items-center justify-center text-slate-400 hover:bg-border-light hover:text-[#0F172A] transition-colors"><svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg></a>
            <a href="#" className="w-10 h-10 bg-background rounded-full flex items-center justify-center text-slate-400 hover:bg-border-light hover:text-[#FF0000] transition-colors"><svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.5 12 3.5 12 3.5s-7.505 0-9.377.55a3.015 3.015 0 0 0-2.122 2.136C0 8.07 0 12 0 12s0 3.93.501 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.55 9.377.55 9.377.55s7.505 0 9.377-.55a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></svg></a>
          </div>
          
        </div>
        
        <div className="border-t border-border-light pt-8 flex flex-col md:flex-row justify-between items-center text-xs font-semibold text-slate-400">
          <p>© 2026 ScamShield Project. All rights reserved.</p>
          <p className="mt-4 md:mt-0">Milestone 1 Implementation</p>
        </div>
      </div>
    </footer>
  );
}

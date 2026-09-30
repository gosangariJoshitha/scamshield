import { Link } from 'react-router-dom';

export default function Footer() {
  return (
    <footer className="bg-slate-900 text-slate-400 py-8 border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col md:flex-row justify-between items-center">
        <div className="mb-4 md:mb-0">
          <span className="text-xl font-bold text-white tracking-wider">SCAMSHIELD</span>
          <p className="text-sm mt-2">Don't Just Detect Scams. Understand Them.</p>
        </div>
        <div className="flex space-x-6 text-sm">
          <Link to="/" className="hover:text-white transition">Privacy</Link>
          <Link to="/" className="hover:text-white transition">Terms</Link>
          <Link to="/" className="hover:text-white transition">Contact</Link>
        </div>
      </div>
    </footer>
  );
}

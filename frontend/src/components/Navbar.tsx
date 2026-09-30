import { Link, useNavigate } from 'react-router-dom';
import { auth } from '../services/auth';

export default function Navbar() {
  const navigate = useNavigate();
  const isAuthenticated = !!localStorage.getItem('token');

  const handleLogout = () => {
    auth.logout();
    navigate('/login');
  };

  return (
    <nav className="bg-slate-900 text-white shadow-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center space-x-8">
            <Link to="/" className="text-xl font-bold tracking-wider">SCAMSHIELD</Link>
            {!isAuthenticated && (
              <div className="hidden md:flex space-x-4">
                <Link to="/" className="hover:text-blue-400">Home</Link>
                <Link to="/" className="hover:text-blue-400">How It Works</Link>
              </div>
            )}
            {isAuthenticated && (
              <div className="hidden md:flex space-x-4">
                <Link to="/dashboard" className="hover:text-blue-400">Dashboard</Link>
                <Link to="/analyze" className="hover:text-blue-400">Analyze</Link>
                <Link to="/history" className="hover:text-blue-400">History</Link>
                <Link to="/community" className="hover:text-blue-400">Community</Link>
              </div>
            )}
          </div>
          <div>
            {isAuthenticated ? (
              <div className="flex items-center space-x-4">
                <Link to="/profile" className="hover:text-blue-400">Profile</Link>
                <button onClick={handleLogout} className="bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded transition">Logout</button>
              </div>
            ) : (
              <div className="flex space-x-4">
                <Link to="/login" className="hover:text-blue-400 py-2">Login</Link>
                <Link to="/signup" className="bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded transition">Get Started</Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}

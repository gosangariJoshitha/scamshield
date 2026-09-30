import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { auth } from '../services/auth';
import { Lock } from 'lucide-react';

export default function Profile() {
  const [user, setUser] = useState<any>(null);
  const navigate = useNavigate();

  useEffect(() => {
    auth.me().then(data => setUser(data)).catch(() => {
      auth.logout();
      navigate('/login');
    });
  }, [navigate]);

  const handleLogout = () => {
    auth.logout();
    window.location.href = '/login';
  };

  if (!user) {
    return (
      <div className="max-w-5xl">
        <div className="mb-8">
          <div className="h-8 bg-slate-200 rounded w-48 mb-2 animate-pulse"></div>
          <div className="h-4 bg-slate-200 rounded w-64 animate-pulse"></div>
        </div>
        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden flex flex-col md:flex-row">
          <div className="p-8 md:w-2/3 space-y-6">
            <div className="h-6 bg-slate-200 rounded w-40 mb-6 animate-pulse"></div>
            {[1, 2, 3, 4, 5].map(i => (
              <div key={i} className="grid grid-cols-3 items-center border-b border-slate-50 pb-4">
                <div className="h-4 bg-slate-200 rounded w-24 animate-pulse"></div>
                <div className="col-span-2 h-4 bg-slate-200 rounded w-48 animate-pulse"></div>
              </div>
            ))}
          </div>
          <div className="p-8 md:w-1/3 bg-slate-50 flex flex-col items-center justify-center">
            <div className="w-16 h-16 bg-slate-200 rounded-full mb-4 animate-pulse"></div>
            <div className="h-5 bg-slate-200 rounded w-32 mb-2 animate-pulse"></div>
            <div className="h-3 bg-slate-200 rounded w-24 animate-pulse"></div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-5xl">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-800 mb-1">My Profile</h1>
        <p className="text-slate-500 text-sm">View and manage your account information.</p>
      </div>
      
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden flex flex-col md:flex-row">
        <div className="p-8 md:w-2/3 border-b md:border-b-0 md:border-r border-slate-100">
          <h2 className="text-lg font-bold text-slate-800 mb-6">Account Information</h2>
          <div className="space-y-6">
            <div className="grid grid-cols-3 items-center border-b border-slate-50 pb-4">
              <div className="text-sm font-medium text-slate-500">Full Name</div>
              <div className="col-span-2 font-medium text-slate-800">{user.full_name}</div>
            </div>
            
            <div className="grid grid-cols-3 items-center border-b border-slate-50 pb-4">
              <div className="text-sm font-medium text-slate-500">Email</div>
              <div className="col-span-2 font-medium text-slate-800">{user.email}</div>
            </div>
            
            <div className="grid grid-cols-3 items-center border-b border-slate-50 pb-4">
              <div className="text-sm font-medium text-slate-500">Role</div>
              <div className="col-span-2 font-medium text-slate-800 capitalize">{user.role}</div>
            </div>
            
            <div className="grid grid-cols-3 items-center border-b border-slate-50 pb-4">
              <div className="text-sm font-medium text-slate-500">Account Status</div>
              <div className="col-span-2">
                <span className="bg-green-50 text-green-600 text-xs font-bold px-3 py-1 rounded-full">
                  {user.is_active ? 'Active' : 'Inactive'}
                </span>
              </div>
            </div>
            
            <div className="grid grid-cols-3 items-center">
              <div className="text-sm font-medium text-slate-500">Member Since</div>
              <div className="col-span-2 font-medium text-slate-800">
                {new Date(user.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}
              </div>
            </div>
          </div>
          
          <div className="mt-12">
            <button onClick={handleLogout} className="border border-red-200 text-red-600 hover:bg-red-50 font-bold py-2 px-8 rounded-lg transition-colors text-sm">
              Logout
            </button>
          </div>
        </div>
        
        <div className="p-8 md:w-1/3 bg-slate-50 flex flex-col items-center justify-center text-center">
          <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-4">
            <Lock className="w-8 h-8 text-blue-500" />
          </div>
          <h3 className="font-bold text-slate-800 mb-2">Change Password</h3>
          <p className="text-xs text-slate-500 max-w-xs">(Coming Soon)</p>
          <p className="text-xs text-slate-400 mt-4 leading-relaxed max-w-[200px]">Password change functionality will be available in a future milestone.</p>
        </div>
      </div>
    </div>
  );
}

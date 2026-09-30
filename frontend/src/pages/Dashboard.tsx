import { useState, useEffect } from 'react';
import { Link, useNavigate, useOutletContext } from 'react-router-dom';
import { Search, AlertTriangle, CheckCircle, ShieldAlert, FileText, Image as ImageIcon, File, Mic, ArrowRight } from 'lucide-react';
import { dashboardService, type DashboardStats } from '../services/dashboard';
import { analysisService, type AnalysisResult } from '../services/analysis';
import { EmptyState } from '../components/common/EmptyState';
import { ErrorState } from '../components/common/ErrorState';

export default function Dashboard() {
  const navigate = useNavigate();
  const { user } = useOutletContext<{ user: any }>();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [recent, setRecent] = useState<AnalysisResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchDashboard = async () => {
      setLoading(true);
      setError(null);
      try {
        const [statsRes, historyRes] = await Promise.all([
          dashboardService.getStats(),
          analysisService.getRecentAnalyses(5)
        ]);
        setStats(statsRes);
        setRecent(historyRes);
      } catch (err) {
        console.error("Failed to load dashboard data", err);
        setError("Unable to load dashboard data.");
      } finally {
        setLoading(false);
      }
    };
    fetchDashboard();
  }, []);

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return "Good morning";
    if (hour < 18) return "Good afternoon";
    return "Good evening";
  };

  const firstName = user?.full_name ? user.full_name.split(' ')[0] : 'User';

  if (error) {
    return <ErrorState message={error} onRetry={() => window.location.reload()} />;
  }

  return (
    <div className="space-y-6 max-w-5xl">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-800 mb-1">{getGreeting()}, {firstName}</h1>
        <p className="text-slate-500 text-sm">Stay alert. Let ScamShield help you understand suspicious content before you act.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {/* Stat cards */}
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-center space-x-4">
          <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center font-bold text-xl">
            <FileText className="w-6 h-6" />
          </div>
          <div>
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-0.5">Total Analyses</div>
            <div className="text-2xl font-bold text-slate-800">{loading ? '-' : stats?.total_analyses || 0}</div>
          </div>
        </div>
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-center space-x-4">
          <div className="w-12 h-12 bg-red-50 text-red-500 rounded-full flex items-center justify-center font-bold text-xl">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div>
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-0.5">Scams Detected</div>
            <div className="text-2xl font-bold text-slate-800">{loading ? '-' : stats?.scams_detected || 0}</div>
          </div>
        </div>
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-center space-x-4">
          <div className="w-12 h-12 bg-green-50 text-green-500 rounded-full flex items-center justify-center font-bold text-xl">
            <CheckCircle className="w-6 h-6" />
          </div>
          <div>
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-0.5">Safe Messages</div>
            <div className="text-2xl font-bold text-slate-800">{loading ? '-' : stats?.safe_messages || 0}</div>
          </div>
        </div>
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-center space-x-4">
          <div className="w-12 h-12 bg-orange-50 text-orange-500 rounded-full flex items-center justify-center font-bold text-xl">
            <ShieldAlert className="w-6 h-6" />
          </div>
          <div>
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-0.5">High Risk</div>
            <div className="text-2xl font-bold text-slate-800">{loading ? '-' : stats?.high_risk || 0}</div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-8">
        <div className="md:col-span-2">
          {/* Start new analysis */}
          <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-2xl border border-blue-100 p-8 flex justify-between items-center relative overflow-hidden h-48">
            <div className="relative z-10">
              <h2 className="text-xl font-bold text-slate-800 mb-2">Start a New Analysis</h2>
              <p className="text-slate-600 mb-6 max-w-xs text-sm">Analyze messages, screenshots, documents or audio for potential scams.</p>
              <Link to="/analyze" className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2.5 px-6 rounded-lg shadow-lg shadow-blue-600/30 transition-all inline-block text-sm">
                Start Analysis
              </Link>
            </div>
            <div className="absolute right-0 bottom-0 top-0 w-64 pointer-events-none flex items-center justify-center">
                <div className="absolute top-10 right-8 w-24 h-32 bg-blue-600 rounded-xl rotate-12 shadow-2xl opacity-90 flex items-center justify-center border border-white/20">
                  <Search className="w-10 h-10 text-white/50" />
                </div>
                <div className="absolute top-6 right-16 w-24 h-32 bg-[#0f172a] rounded-xl -rotate-6 shadow-2xl flex items-center justify-center border border-slate-700">
                  <ShieldAlert className="w-10 h-10 text-blue-500" />
                </div>
            </div>
          </div>

          <div className="mt-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-sm">
            <h3 className="font-bold text-slate-800 mb-6 text-sm">Supported Input Types</h3>
            <div className="flex space-x-8">
              <div className="flex flex-col items-center group cursor-pointer" onClick={() => navigate('/analyze')}>
                <div className="w-12 h-12 bg-blue-50 group-hover:bg-blue-100 text-blue-500 rounded-xl flex items-center justify-center mb-3 transition">
                  <FileText className="w-6 h-6" />
                </div>
                <span className="text-[10px] font-bold text-slate-500">Text</span>
              </div>
              <div className="flex flex-col items-center group cursor-pointer" onClick={() => navigate('/analyze')}>
                <div className="w-12 h-12 bg-blue-50 group-hover:bg-blue-100 text-blue-500 rounded-xl flex items-center justify-center mb-3 transition">
                  <ImageIcon className="w-6 h-6" />
                </div>
                <span className="text-[10px] font-bold text-slate-500">Image</span>
              </div>
              <div className="flex flex-col items-center group cursor-pointer" onClick={() => navigate('/analyze')}>
                <div className="w-12 h-12 bg-red-50 group-hover:bg-red-100 text-red-500 rounded-xl flex items-center justify-center mb-3 transition">
                  <File className="w-6 h-6" />
                </div>
                <span className="text-[10px] font-bold text-slate-500">PDF</span>
              </div>
              <div className="flex flex-col items-center group cursor-pointer" onClick={() => navigate('/analyze')}>
                <div className="w-12 h-12 bg-blue-50 group-hover:bg-blue-100 text-blue-500 rounded-xl flex items-center justify-center mb-3 transition">
                  <Mic className="w-6 h-6" />
                </div>
                <span className="text-[10px] font-bold text-slate-500">Audio</span>
              </div>
            </div>
          </div>
        </div>

        <div>
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm h-full flex flex-col">
            <div className="p-5 border-b border-slate-100 flex justify-between items-center">
              <h3 className="font-bold text-slate-800 text-sm">Recent Analyses</h3>
              <Link to="/history" className="text-xs font-bold text-blue-600 hover:text-blue-700">View All</Link>
            </div>
            
            {loading ? (
              <div className="flex-1 flex flex-col items-center justify-center p-8 space-y-4">
                {[1, 2, 3].map(i => (
                  <div key={i} className="animate-pulse flex items-start space-x-3 border-b border-slate-100 pb-4 w-full">
                    <div className="w-10 h-10 bg-slate-100 rounded-lg shrink-0"></div>
                    <div className="flex-1 space-y-2">
                      <div className="h-4 bg-slate-100 rounded w-1/2"></div>
                      <div className="h-3 bg-slate-100 rounded w-1/4"></div>
                    </div>
                  </div>
                ))}
              </div>
            ) : recent.length > 0 ? (
              <div className="flex-1 flex flex-col overflow-y-auto">
                {recent.map((item) => (
                  <div key={item.id} className="p-4 border-b border-slate-100 hover:bg-slate-50 transition cursor-pointer" onClick={() => navigate('/results', { state: { result: item, from: '/dashboard' } })}>
                    <div className="flex justify-between items-start mb-2">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded uppercase tracking-wider ${item.risk_level === 'HIGH' || item.risk_level === 'CRITICAL' ? 'bg-red-100 text-red-600' : item.risk_level === 'MEDIUM' ? 'bg-amber-100 text-amber-600' : 'bg-green-100 text-green-600'}`}>
                        {item.risk_level} RISK
                      </span>
                      <span className="text-[10px] text-slate-400">
                        {new Date(item.created_at).toLocaleDateString()}
                      </span>
                    </div>
                    <p className="text-xs text-slate-700 line-clamp-2 mb-2">{item.content}</p>
                    <div className="flex items-center text-[10px] font-bold text-blue-600 space-x-1">
                      <span>View details</span>
                      <ArrowRight className="w-3 h-3" />
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <EmptyState 
                title="No analyses yet" 
                description="Your first analysis will appear here."
              />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

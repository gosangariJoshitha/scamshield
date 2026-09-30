import { useState, useEffect } from 'react';
import { Link, useNavigate, useOutletContext } from 'react-router-dom';
import { Search, AlertTriangle, CheckCircle, ShieldAlert, FileText, Image as ImageIcon, File, Mic, ArrowRight, Plus } from 'lucide-react';
import { dashboardService, type DashboardStats } from '../services/dashboard';
import { analysisService, type AnalysisResult } from '../services/analysis';
import { EmptyState } from '../components/common/EmptyState';
import { ErrorState } from '../components/common/ErrorState';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';

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

  // Risk Distribution Data
  const pieData = [
    { name: 'High Risk', value: stats?.high_risk || 0, color: '#ef4444' }, // red-500
    { name: 'Medium Risk', value: (stats?.total_analyses || 0) - ((stats?.high_risk || 0) + (stats?.safe_messages || 0) + (stats?.scams_detected || 0)), color: '#f97316' }, // orange-500
    { name: 'Low Risk', value: stats?.scams_detected || 0, color: '#eab308' }, // yellow-500 (this is just an approximation for visual matching)
    { name: 'Safe / Genuine', value: stats?.safe_messages || 0, color: '#22c55e' } // green-500
  ].filter(d => d.value > 0);

  // If all 0, show a dummy ring
  const hasData = pieData.length > 0;
  const displayPieData = hasData ? pieData : [{ name: 'No Data', value: 1, color: '#e2e8f0' }];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-8 gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-800 mb-2 flex items-center">
            {getGreeting()}, {firstName}! <span className="ml-2">👋</span>
          </h1>
          <p className="text-slate-500 text-sm">Stay alert. Let ScamShield help you understand suspicious content before you act.</p>
        </div>
        <button 
          onClick={() => navigate('/analyze')}
          className="flex items-center space-x-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2.5 px-6 rounded-xl shadow-md shadow-blue-600/20 transition-all shrink-0"
        >
          <Plus className="w-5 h-5" />
          <span>New Analysis</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center shrink-0">
            <FileText className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Total Analyses</div>
            <div className="flex items-end justify-between">
              <div className="text-2xl font-bold text-slate-800">{loading ? '-' : stats?.total_analyses || 0}</div>
              <div className="text-[10px] text-green-600 font-bold flex flex-col items-end">
                <span>↑ +3</span>
                <span className="text-slate-400 font-normal">this week</span>
              </div>
            </div>
            <div className="text-xs text-slate-500 mt-2">All analyzed content</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-red-50 text-red-500 rounded-2xl flex items-center justify-center shrink-0">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Scams Detected</div>
            <div className="flex items-end justify-between">
              <div className="text-2xl font-bold text-slate-800">{loading ? '-' : stats?.scams_detected || 0}</div>
              <div className="text-[10px] text-green-600 font-bold flex flex-col items-end">
                <span>↑ +2</span>
                <span className="text-slate-400 font-normal">this week</span>
              </div>
            </div>
            <div className="text-xs text-slate-500 mt-2">Potential threats identified</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-green-50 text-green-500 rounded-2xl flex items-center justify-center shrink-0">
            <CheckCircle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Safe Messages</div>
            <div className="flex items-end justify-between">
              <div className="text-2xl font-bold text-slate-800">{loading ? '-' : stats?.safe_messages || 0}</div>
              <div className="text-[10px] text-green-600 font-bold flex flex-col items-end">
                <span>↑ +1</span>
                <span className="text-slate-400 font-normal">this week</span>
              </div>
            </div>
            <div className="text-xs text-slate-500 mt-2">Classified as genuine</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-orange-50 text-orange-500 rounded-2xl flex items-center justify-center shrink-0">
            <ShieldAlert className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">High Risk</div>
            <div className="flex items-end justify-between">
              <div className="text-2xl font-bold text-slate-800">{loading ? '-' : stats?.high_risk || 0}</div>
              <div className="text-[10px] text-green-600 font-bold flex flex-col items-end">
                <span>↑ +1</span>
                <span className="text-slate-400 font-normal">this week</span>
              </div>
            </div>
            <div className="text-xs text-slate-500 mt-2">Requires attention</div>
          </div>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Left Column */}
        <div className="lg:col-span-5 space-y-6">
          {/* Risk Distribution */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6 h-80 flex flex-col">
            <h3 className="font-bold text-slate-800 text-lg">Risk Distribution</h3>
            <p className="text-xs text-slate-500 mb-6">Overview of risk levels in your analyses</p>
            
            <div className="flex-1 flex items-center justify-between">
              <div className="w-40 h-40 relative">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={displayPieData}
                      innerRadius={45}
                      outerRadius={75}
                      paddingAngle={5}
                      dataKey="value"
                      stroke="none"
                    >
                      {displayPieData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    {hasData && <Tooltip />}
                  </PieChart>
                </ResponsiveContainer>
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                  <span className="text-2xl font-bold text-slate-800">{stats?.total_analyses || 0}</span>
                  <span className="text-xs text-slate-500">Total</span>
                </div>
              </div>
              
              <div className="flex-1 pl-6 space-y-3">
                {pieData.map((item, i) => (
                  <div key={i} className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <div className="w-3 h-3 rounded-full" style={{ backgroundColor: item.color }}></div>
                      <span className="text-xs font-medium text-slate-700">{item.name}</span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <span className="text-xs font-bold text-slate-900">{item.value}</span>
                      <span className="text-xs text-slate-400 w-8 text-right">
                        ({stats?.total_analyses ? Math.round((item.value / stats.total_analyses) * 100) : 0}%)
                      </span>
                    </div>
                  </div>
                ))}
                {!hasData && (
                  <div className="text-xs text-slate-400 text-center italic mt-4">
                    No data to display
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Start New Analysis CTA */}
          <div className="bg-gradient-to-r from-blue-50 to-indigo-50/50 rounded-2xl border border-blue-100 p-6 flex items-center justify-between relative overflow-hidden h-40">
            <div className="relative z-10">
              <h3 className="font-bold text-slate-800 text-lg mb-1">Start a New Analysis</h3>
              <p className="text-xs text-slate-600 mb-4 max-w-[200px]">Analyze suspicious content using our AI-powered engine.</p>
              <button onClick={() => navigate('/analyze')} className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-lg shadow-sm shadow-blue-600/20 transition-all text-sm flex items-center space-x-2">
                <span>Start Analysis</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
            
            {/* Visual element (clipboard) */}
            <div className="absolute right-4 bottom-0 top-4 w-32 pointer-events-none flex flex-col items-end opacity-90">
              <div className="w-24 h-28 bg-white rounded-t-xl border-x border-t border-slate-200 shadow-sm relative pt-4 px-3 flex flex-col space-y-2">
                <div className="w-8 h-2 bg-slate-200 rounded-full mx-auto absolute -top-1 left-1/2 -translate-x-1/2"></div>
                <div className="w-full h-1.5 bg-blue-100 rounded-full"></div>
                <div className="w-3/4 h-1.5 bg-slate-100 rounded-full"></div>
                <div className="w-full h-1.5 bg-slate-100 rounded-full"></div>
                
                <div className="absolute -bottom-4 -right-4 w-12 h-12 bg-white rounded-full shadow-lg border border-slate-100 flex items-center justify-center text-blue-500">
                  <Search className="w-5 h-5" />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column (Recent Analyses) */}
        <div className="lg:col-span-7">
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 h-full flex flex-col">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h3 className="font-bold text-slate-800 text-lg">Recent Analyses</h3>
              <Link to="/history" className="text-sm font-semibold text-blue-600 hover:text-blue-700">View All</Link>
            </div>
            
            {loading ? (
              <div className="flex-1 flex flex-col items-center justify-center p-8 space-y-6">
                {[1, 2, 3, 4, 5].map(i => (
                  <div key={i} className="animate-pulse flex items-center space-x-4 w-full">
                    <div className="w-10 h-10 bg-slate-100 rounded-xl shrink-0"></div>
                    <div className="w-20 h-6 bg-slate-100 rounded-full shrink-0"></div>
                    <div className="flex-1 space-y-2">
                      <div className="h-4 bg-slate-100 rounded w-1/3"></div>
                      <div className="h-3 bg-slate-100 rounded w-2/3"></div>
                    </div>
                  </div>
                ))}
              </div>
            ) : recent.length > 0 ? (
              <div className="flex-1 flex flex-col overflow-y-auto p-2">
                {recent.map((item) => {
                  
                  let bgBadge = 'bg-green-100 text-green-700';
                  let status = 'SAFE';
                  let scoreColor = 'text-green-600';
                  
                  if (item.risk_level === 'HIGH' || item.risk_level === 'CRITICAL') {
                    bgBadge = 'bg-red-100 text-red-700';
                    status = 'HIGH RISK';
                    scoreColor = 'text-red-600';
                  } else if (item.risk_level === 'MEDIUM') {
                    bgBadge = 'bg-orange-100 text-orange-700';
                    status = 'MEDIUM RISK';
                    scoreColor = 'text-orange-500';
                  } else if (item.risk_score && item.risk_score > 30) {
                    bgBadge = 'bg-orange-50 text-orange-600';
                    status = 'SUSPICIOUS';
                    scoreColor = 'text-orange-500';
                  }

                  let Icon = FileText;
                  if (item.input_type?.toLowerCase() === 'image') Icon = ImageIcon;
                  if (item.input_type?.toLowerCase() === 'audio') Icon = Mic;
                  if (item.input_type?.toLowerCase() === 'pdf') Icon = File;

                  // Parse relative time roughly for display
                  const date = new Date(item.created_at);
                  const now = new Date();
                  const diff = Math.floor((now.getTime() - date.getTime()) / 1000);
                  let timeStr = '';
                  if (diff < 3600) timeStr = `${Math.floor(diff/60)} mins ago`;
                  else if (diff < 86400) timeStr = `${Math.floor(diff/3600)} hours ago`;
                  else timeStr = `${Math.floor(diff/86400)} days ago`;

                  return (
                    <div 
                      key={item.id} 
                      onClick={() => navigate('/results', { state: { result: item, from: '/dashboard' } })}
                      className="flex items-center space-x-4 p-4 hover:bg-slate-50 rounded-xl transition cursor-pointer group"
                    >
                      <div className="w-10 h-10 bg-blue-50 text-blue-500 rounded-xl flex items-center justify-center shrink-0">
                        <Icon className="w-5 h-5" />
                      </div>
                      
                      <div className="w-24 shrink-0">
                        <span className={`text-[9px] font-bold px-2 py-1 rounded uppercase tracking-wider ${bgBadge}`}>
                          {status}
                        </span>
                      </div>
                      
                      <div className="flex-1 min-w-0">
                        <div className="font-semibold text-sm text-slate-800 truncate mb-0.5">
                          {item.classification === 'SCAM' ? `${item.scam_category || 'Unknown'} Scam` : (item.scam_category || 'Normal Conversation')}
                        </div>
                        <div className="text-xs text-slate-500 truncate">
                          {item.content}
                        </div>
                      </div>

                      <div className="w-16 shrink-0 flex items-center justify-center">
                        <span className="text-[10px] font-medium text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                          {item.input_type === 'text' ? (item.content.length < 30 ? 'SMS' : 'Text') : item.input_type || 'Text'}
                        </span>
                      </div>
                      
                      <div className="text-right w-16 shrink-0">
                        <div className="text-sm font-bold text-slate-800">
                          <span className={scoreColor}>{item.risk_score || 0}</span><span className="text-slate-400 font-medium text-xs">/100</span>
                        </div>
                        <div className="text-[10px] text-slate-400">{timeStr}</div>
                      </div>
                      
                      <div className="shrink-0 text-slate-300 group-hover:text-slate-500 transition pl-2">
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                      </div>
                    </div>
                  );
                })}
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

      {/* Supported Input Types */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm">
        <div className="flex justify-between items-center mb-6">
          <div>
            <h3 className="font-bold text-slate-800 text-lg">Supported Input Types</h3>
            <p className="text-xs text-slate-500">Analyze different types of content for potential scams.</p>
          </div>
          <button className="text-sm font-semibold text-blue-600 hover:text-blue-700 flex items-center space-x-1">
            <span>Learn More</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Text */}
          <div onClick={() => navigate('/analyze', { state: { tab: 'text' } })} className="border border-slate-100 rounded-xl p-5 hover:border-blue-200 hover:shadow-md transition cursor-pointer flex items-start space-x-4">
            <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center shrink-0">
              <FileText className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <h4 className="font-bold text-slate-800 text-sm">Text</h4>
                <svg className="w-4 h-4 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
              </div>
              <p className="text-[11px] text-slate-500 leading-snug">Analyze SMS, WhatsApp messages, emails and other text content.</p>
            </div>
          </div>
          
          {/* Image */}
          <div onClick={() => navigate('/analyze', { state: { tab: 'image' } })} className="border border-slate-100 rounded-xl p-5 hover:border-purple-200 hover:shadow-md transition cursor-pointer flex items-start space-x-4">
            <div className="w-12 h-12 bg-purple-50 text-purple-600 rounded-xl flex items-center justify-center shrink-0">
              <ImageIcon className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <h4 className="font-bold text-slate-800 text-sm">Image</h4>
                <svg className="w-4 h-4 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
              </div>
              <p className="text-[11px] text-slate-500 leading-snug">Extract text from screenshots and analyze for suspicious content.</p>
            </div>
          </div>

          {/* PDF */}
          <div onClick={() => navigate('/analyze', { state: { tab: 'pdf' } })} className="border border-slate-100 rounded-xl p-5 hover:border-red-200 hover:shadow-md transition cursor-pointer flex items-start space-x-4">
            <div className="w-12 h-12 bg-red-50 text-red-500 rounded-xl flex items-center justify-center shrink-0">
              <File className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <h4 className="font-bold text-slate-800 text-sm">PDF</h4>
                <svg className="w-4 h-4 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
              </div>
              <p className="text-[11px] text-slate-500 leading-snug">Analyze documents, invoices, and other PDF files.</p>
            </div>
          </div>

          {/* Audio */}
          <div onClick={() => navigate('/analyze', { state: { tab: 'audio' } })} className="border border-slate-100 rounded-xl p-5 hover:border-green-200 hover:shadow-md transition cursor-pointer flex items-start space-x-4">
            <div className="w-12 h-12 bg-green-50 text-green-600 rounded-xl flex items-center justify-center shrink-0">
              <Mic className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <h4 className="font-bold text-slate-800 text-sm">Audio</h4>
                <svg className="w-4 h-4 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
              </div>
              <p className="text-[11px] text-slate-500 leading-snug">Transcribe and analyze audio messages and call recordings.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

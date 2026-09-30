import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { 
  ArrowRight, ShieldAlert, Calendar, Download, 
  FileText, AlertTriangle, CheckCircle, Search, 
  MoreVertical, File, Image as ImageIcon, Mic, MessageSquare, Briefcase
} from 'lucide-react';
import { analysisService, type AnalysisResult } from '../services/analysis';
import { dashboardService, type DashboardStats } from '../services/dashboard';
import { EmptyState } from '../components/common/EmptyState';
import { ErrorState } from '../components/common/ErrorState';

export default function History() {
  const navigate = useNavigate();
  const [history, setHistory] = useState<AnalysisResult[]>([]);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const [histRes, statsRes] = await Promise.all([
        analysisService.getHistory(),
        dashboardService.getStats()
      ]);
      setHistory(histRes);
      setStats(statsRes);
    } catch (err) {
      console.error("Failed to load history data", err);
      setError("Failed to load analysis history. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const avgRiskScore = history.length > 0 
    ? Math.round(history.reduce((acc, curr) => acc + (curr.risk_score || 0), 0) / history.length)
    : 0;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-2">
        <div>
          <h1 className="text-3xl font-bold text-slate-800 mb-2">Analysis History</h1>
          <p className="text-slate-500 text-sm">View and manage all your previous analyses.</p>
        </div>
        <div className="flex items-center space-x-3 shrink-0">
          <button className="flex items-center space-x-2 bg-white border border-slate-200 hover:border-slate-300 text-slate-700 font-medium py-2 px-4 rounded-lg shadow-sm transition">
            <Calendar className="w-4 h-4 text-blue-500" />
            <span>Date Range</span>
          </button>
          <button className="flex items-center space-x-2 bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg shadow-sm shadow-blue-600/20 transition">
            <Download className="w-4 h-4" />
            <span>Export History</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center shrink-0">
            <FileText className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Total Analyses</div>
            <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{loading ? '-' : stats?.total_analyses || 0}</div>
            <div className="text-[11px] text-slate-500">All time</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-red-50 text-red-500 rounded-full flex items-center justify-center shrink-0">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Scams Detected</div>
            <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{loading ? '-' : stats?.scams_detected || 0}</div>
            <div className="text-[11px] text-slate-500">
              {stats?.total_analyses ? Math.round((stats.scams_detected / stats.total_analyses) * 100) : 0}% of total
            </div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-green-50 text-green-500 rounded-full flex items-center justify-center shrink-0">
            <CheckCircle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Safe Messages</div>
            <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{loading ? '-' : stats?.safe_messages || 0}</div>
            <div className="text-[11px] text-slate-500">
              {stats?.total_analyses ? Math.round((stats.safe_messages / stats.total_analyses) * 100) : 0}% of total
            </div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-orange-50 text-orange-500 rounded-full flex items-center justify-center shrink-0">
            <ShieldAlert className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Average Risk Score</div>
            <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{loading ? '-' : avgRiskScore}</div>
            <div className="text-[11px] text-slate-500">Across all analyses</div>
          </div>
        </div>
      </div>

      {/* Filters & Table container */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden flex flex-col">
        {/* Filter Bar */}
        <div className="p-4 border-b border-slate-100 flex flex-col lg:flex-row items-center gap-4 bg-slate-50/50">
          <div className="relative w-full lg:max-w-md">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search className="h-4 w-4 text-slate-400" />
            </div>
            <input
              type="text"
              placeholder="Search by keywords, content, or category..."
              className="block w-full pl-10 pr-3 py-2.5 border border-slate-200 rounded-xl leading-5 bg-white placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 sm:text-sm transition-colors"
            />
          </div>
          
          <div className="flex-1 flex flex-wrap lg:flex-nowrap items-center gap-3 w-full lg:w-auto">
            <div className="flex-1 min-w-[120px]">
              <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1 ml-1">Risk Level</div>
              <div className="relative">
                <select className="block w-full pl-3 pr-8 py-2 text-sm border border-slate-200 rounded-lg appearance-none bg-white focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 font-medium text-slate-700">
                  <option>All Risks</option>
                  <option>High</option>
                  <option>Medium</option>
                  <option>Low</option>
                </select>
                <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-slate-400">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                </div>
              </div>
            </div>
            
            <div className="flex-1 min-w-[120px]">
              <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1 ml-1">Classification</div>
              <div className="relative">
                <select className="block w-full pl-3 pr-8 py-2 text-sm border border-slate-200 rounded-lg appearance-none bg-white focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 font-medium text-slate-700">
                  <option>All</option>
                  <option>Scam</option>
                  <option>Genuine</option>
                </select>
                <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-slate-400">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                </div>
              </div>
            </div>

            <div className="flex-1 min-w-[120px]">
              <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1 ml-1">Input Type</div>
              <div className="relative">
                <select className="block w-full pl-3 pr-8 py-2 text-sm border border-slate-200 rounded-lg appearance-none bg-white focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 font-medium text-slate-700">
                  <option>All Types</option>
                  <option>Text</option>
                  <option>Image</option>
                  <option>Audio</option>
                  <option>PDF</option>
                </select>
                <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-slate-400">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                </div>
              </div>
            </div>
            
            <div className="mt-5 ml-auto">
              <button className="flex items-center space-x-1.5 text-blue-600 hover:text-blue-700 font-semibold text-sm px-3 py-2 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg>
                <span>Reset Filters</span>
              </button>
            </div>
          </div>
        </div>

        {/* Table */}
        {loading ? (
          <div className="p-12 flex flex-col items-center justify-center space-y-4">
             {[1, 2, 3, 4, 5].map(i => (
               <div key={i} className="animate-pulse flex items-center space-x-4 w-full">
                 <div className="w-6 h-6 bg-slate-100 rounded"></div>
                 <div className="flex-1 h-6 bg-slate-100 rounded"></div>
               </div>
             ))}
          </div>
        ) : error ? (
          <div className="p-8">
            <ErrorState message={error} onRetry={fetchData} />
          </div>
        ) : history.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="w-full text-left whitespace-nowrap">
              <thead className="bg-white border-b border-slate-100">
                <tr>
                  <th className="px-6 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-wider w-10">
                    <input type="checkbox" className="rounded border-slate-300 text-blue-600 focus:ring-blue-500" />
                  </th>
                  <th className="px-4 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                    <div className="flex items-center space-x-1 cursor-pointer hover:text-slate-600">
                      <span>Date & Time</span>
                      <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"></path></svg>
                    </div>
                  </th>
                  <th className="px-4 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-wider">Content Preview</th>
                  <th className="px-4 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-wider">Input Type</th>
                  <th className="px-4 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-wider">Category</th>
                  <th className="px-4 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-wider">Classification</th>
                  <th className="px-4 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-wider">Risk Score</th>
                  <th className="px-4 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-wider">Risk Level</th>
                  <th className="px-6 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {history.map((item) => {
                  
                  let badge = 'bg-green-100 text-green-700';
                  let status = 'LOW';
                  let scoreColor = 'text-green-600';
                  
                  if (item.risk_level === 'HIGH' || item.risk_level === 'CRITICAL') {
                    badge = 'bg-red-100 text-red-700';
                    status = 'HIGH';
                    scoreColor = 'text-red-600';
                  } else if (item.risk_level === 'MEDIUM') {
                    badge = 'bg-orange-100 text-orange-700';
                    status = 'MEDIUM';
                    scoreColor = 'text-orange-500';
                  }

                  let typeIcon = <MessageSquare className="w-3.5 h-3.5 text-blue-500" />;
                  let typeText = 'SMS';
                  if (item.input_type?.toLowerCase() === 'image') { typeIcon = <ImageIcon className="w-3.5 h-3.5 text-purple-500" />; typeText = 'Image'; }
                  if (item.input_type?.toLowerCase() === 'audio') { typeIcon = <Mic className="w-3.5 h-3.5 text-green-500" />; typeText = 'Audio'; }
                  if (item.input_type?.toLowerCase() === 'pdf') { typeIcon = <File className="w-3.5 h-3.5 text-red-500" />; typeText = 'PDF'; }

                  const isScam = item.classification === 'SCAM';

                  return (
                    <tr key={item.id} className="hover:bg-slate-50 transition">
                      <td className="px-6 py-4">
                        <input type="checkbox" className="rounded border-slate-300 text-blue-600 focus:ring-blue-500" />
                      </td>
                      <td className="px-4 py-4 text-sm text-slate-600">
                        {new Date(item.created_at).toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: 'numeric', minute: '2-digit' })}
                      </td>
                      <td className="px-4 py-4 text-sm text-slate-800 max-w-[200px] truncate">
                        {item.content}
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center space-x-1.5 border border-slate-200 rounded px-2 py-1 w-max">
                          {typeIcon}
                          <span className="text-[10px] font-semibold text-slate-600">{typeText}</span>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-sm text-slate-600">
                        {item.category || 'General'}
                      </td>
                      <td className="px-4 py-4">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded uppercase ${isScam ? 'bg-red-50 text-red-600' : (item.classification === 'SUSPICIOUS' ? 'bg-orange-50 text-orange-600' : 'bg-green-50 text-green-600')}`}>
                          {item.classification}
                        </span>
                      </td>
                      <td className="px-4 py-4 font-bold text-sm">
                        <span className={scoreColor}>{item.risk_score}</span><span className="text-slate-400">/100</span>
                      </td>
                      <td className="px-4 py-4">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded uppercase tracking-wider ${badge}`}>
                          {status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right flex items-center justify-end space-x-3">
                        <button onClick={() => navigate('/results', { state: { result: item, from: '/history' } })} className="flex items-center space-x-1 text-xs font-semibold text-blue-600 hover:text-blue-700">
                          <span>View</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </button>
                        <button className="text-slate-400 hover:text-slate-600">
                          <MoreVertical className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="p-12 flex flex-col justify-center items-center">
            <EmptyState 
              title="No analyses yet" 
              description="Start your first analysis to see your history here."
              icon={<ShieldAlert className="w-8 h-8" />}
              action={
                <Link to="/analyze" className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2.5 px-8 rounded-lg shadow-md shadow-blue-500/30 transition-all inline-block text-sm">
                  Start Analysis
                </Link>
              }
            />
          </div>
        )}
        
        {/* Pagination */}
        {history.length > 0 && (
          <div className="p-4 border-t border-slate-100 flex items-center justify-between bg-slate-50/50">
            <div className="text-xs text-slate-500">
              Showing 1 to {history.length} of {history.length} results
            </div>
            <div className="flex space-x-1">
              <button className="w-8 h-8 flex items-center justify-center rounded border border-slate-200 text-slate-400 disabled:opacity-50" disabled>
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 19l-7-7 7-7"></path></svg>
              </button>
              <button className="w-8 h-8 flex items-center justify-center rounded bg-blue-600 text-white font-medium text-xs shadow-sm">1</button>
              <button className="w-8 h-8 flex items-center justify-center rounded border border-slate-200 text-slate-600 hover:bg-slate-50 font-medium text-xs">2</button>
              <button className="w-8 h-8 flex items-center justify-center rounded border border-slate-200 text-slate-600 hover:bg-slate-50">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7"></path></svg>
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

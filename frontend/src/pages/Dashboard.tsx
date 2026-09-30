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

  const highRiskCount = stats?.high_risk || 0;
  const mediumLowRiskCount = Math.max(0, (stats?.scams_detected || 0) - highRiskCount);
  const safeCount = stats?.safe_messages || 0;

  // Risk Distribution Data
  const pieData = [
    { name: 'High Risk', value: highRiskCount, color: '#DC2626' }, // red-500
    { name: 'Medium/Low Risk', value: mediumLowRiskCount, color: '#F59E0B' }, // orange-500
    { name: 'Safe / Genuine', value: safeCount, color: '#16A34A' } // green-500
  ].filter(d => d.value > 0);

  // If all 0, show a dummy ring
  const hasData = pieData.length > 0;
  const displayPieData = hasData ? pieData : [{ name: 'No Data', value: 1, color: '#e2e8f0' }];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-8 gap-4">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-2 flex items-center">
            {getGreeting()}, {firstName}! <span className="ml-2">👋</span>
          </h1>
          <p className="text-text-muted text-base">Stay alert. Let ScamShield help you understand suspicious content before you act.</p>
        </div>
        <button 
          onClick={() => navigate('/analyze')}
          className="flex items-center space-x-2 bg-primary hover:bg-primary-hover text-white font-bold py-2.5 px-6 rounded-xl shadow-md shadow-primary/20 transition-all shrink-0"
        >
          <Plus className="w-5 h-5" />
          <span>New Analysis</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-primary/10 text-primary rounded-2xl flex items-center justify-center shrink-0">
            <FileText className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Total Analyses</div>
            <div className="flex items-end justify-between">
              <div className="text-2xl font-bold text-text-main">{loading ? '-' : stats?.total_analyses || 0}</div>
              <div className="text-[10px] text-success font-bold flex flex-col items-end">
                <span>↑ +3</span>
                <span className="text-text-muted font-normal">this week</span>
              </div>
            </div>
            <div className="text-sm text-text-muted mt-2">All analyzed content</div>
          </div>
        </div>

        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-danger/10 text-danger rounded-2xl flex items-center justify-center shrink-0">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Scams Detected</div>
            <div className="flex items-end justify-between">
              <div className="text-2xl font-bold text-text-main">{loading ? '-' : stats?.scams_detected || 0}</div>
              <div className="text-[10px] text-success font-bold flex flex-col items-end">
                <span>↑ +2</span>
                <span className="text-text-muted font-normal">this week</span>
              </div>
            </div>
            <div className="text-sm text-text-muted mt-2">Potential threats identified</div>
          </div>
        </div>

        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-success/10 text-success rounded-2xl flex items-center justify-center shrink-0">
            <CheckCircle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Safe Messages</div>
            <div className="flex items-end justify-between">
              <div className="text-2xl font-bold text-text-main">{loading ? '-' : stats?.safe_messages || 0}</div>
              <div className="text-[10px] text-success font-bold flex flex-col items-end">
                <span>↑ +1</span>
                <span className="text-text-muted font-normal">this week</span>
              </div>
            </div>
            <div className="text-sm text-text-muted mt-2">Classified as genuine</div>
          </div>
        </div>

        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-warning/10 text-warning rounded-2xl flex items-center justify-center shrink-0">
            <ShieldAlert className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">High Risk</div>
            <div className="flex items-end justify-between">
              <div className="text-2xl font-bold text-text-main">{loading ? '-' : stats?.high_risk || 0}</div>
              <div className="text-[10px] text-success font-bold flex flex-col items-end">
                <span>↑ +1</span>
                <span className="text-text-muted font-normal">this week</span>
              </div>
            </div>
            <div className="text-sm text-text-muted mt-2">Requires attention</div>
          </div>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Left Column */}
        <div className="lg:col-span-5 space-y-6">
          {/* Risk Distribution */}
          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6 h-80 flex flex-col">
            <h3 className="font-bold text-text-main text-lg">Risk Distribution</h3>
            <p className="text-sm text-text-muted mb-6">Overview of risk levels in your analyses</p>
            
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
                  <span className="text-2xl font-bold text-text-main">{stats?.total_analyses || 0}</span>
                  <span className="text-sm text-text-muted">Total</span>
                </div>
              </div>
              
              <div className="flex-1 pl-6 space-y-3">
                {pieData.map((item, i) => (
                  <div key={i} className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <div className="w-3 h-3 rounded-full" style={{ backgroundColor: item.color }}></div>
                      <span className="text-sm font-semibold text-text-secondary">{item.name}</span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <span className="text-sm font-bold text-text-main">{item.value}</span>
                      <span className="text-sm text-text-muted w-8 text-right">
                        ({stats?.total_analyses ? Math.round((item.value / stats.total_analyses) * 100) : 0}%)
                      </span>
                    </div>
                  </div>
                ))}
                {!hasData && (
                  <div className="text-sm text-text-muted text-center italic mt-4">
                    No data to display
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Start New Analysis CTA */}
          <div className="bg-gradient-to-r from-blue-50 to-indigo-50/50 rounded-2xl border border-blue-100 p-6 flex items-center justify-between relative overflow-hidden h-40">
            <div className="relative z-10">
              <h3 className="font-bold text-text-main text-lg mb-1">Start a New Analysis</h3>
              <p className="text-sm text-text-secondary mb-4 max-w-[200px]">Analyze suspicious content using our AI-powered engine.</p>
              <button onClick={() => navigate('/analyze')} className="bg-primary hover:bg-primary-hover text-white font-semibold py-2 px-6 rounded-lg shadow-sm shadow-primary/20 transition-all text-base flex items-center space-x-2">
                <span>Start Analysis</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
            
            {/* Visual element (clipboard) */}
            <div className="absolute right-4 bottom-0 top-4 w-32 pointer-events-none flex flex-col items-end opacity-90">
              <div className="w-24 h-28 bg-card rounded-t-xl border-x border-t border-border-light shadow-sm relative pt-4 px-3 flex flex-col space-y-2">
                <div className="w-8 h-2 bg-slate-200 rounded-full mx-auto absolute -top-1 left-1/2 -translate-x-1/2"></div>
                <div className="w-full h-1.5 bg-primary/10 rounded-full"></div>
                <div className="w-3/4 h-1.5 bg-background rounded-full"></div>
                <div className="w-full h-1.5 bg-background rounded-full"></div>
                
                <div className="absolute -bottom-4 -right-4 w-12 h-12 bg-card rounded-full shadow-lg border border-border-light flex items-center justify-center text-primary">
                  <Search className="w-5 h-5" />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column (Recent Analyses) */}
        <div className="lg:col-span-7">
          <div className="bg-card rounded-2xl shadow-sm border border-border-light h-full flex flex-col">
            <div className="p-6 border-b border-border-light flex justify-between items-center">
              <h3 className="font-bold text-text-main text-lg">Recent Analyses</h3>
              <Link to="/history" className="text-base font-bold text-primary hover:text-blue-700">View All</Link>
            </div>
            
            {loading ? (
              <div className="flex-1 flex flex-col items-center justify-center p-8 space-y-6">
                {[1, 2, 3, 4, 5].map(i => (
                  <div key={i} className="animate-pulse flex items-center space-x-4 w-full">
                    <div className="w-10 h-10 bg-background rounded-xl shrink-0"></div>
                    <div className="w-20 h-6 bg-background rounded-full shrink-0"></div>
                    <div className="flex-1 space-y-2">
                      <div className="h-4 bg-background rounded w-1/3"></div>
                      <div className="h-3 bg-background rounded w-2/3"></div>
                    </div>
                  </div>
                ))}
              </div>
            ) : recent.length > 0 ? (
              <div className="flex-1 flex flex-col overflow-y-auto p-2">
                {recent.map((item) => {
                  
                  let bgBadge = 'bg-success/20 text-success';
                  let status = 'SAFE';
                  let scoreColor = 'text-success';
                  
                  if (item.risk_level === 'HIGH' || item.risk_level === 'CRITICAL') {
                    bgBadge = 'bg-danger/20 text-red-700';
                    status = 'HIGH RISK';
                    scoreColor = 'text-danger';
                  } else if (item.risk_level === 'MEDIUM') {
                    bgBadge = 'bg-orange-100 text-orange-700';
                    status = 'MEDIUM RISK';
                    scoreColor = 'text-warning';
                  } else if (item.risk_score && item.risk_score > 30) {
                    bgBadge = 'bg-warning/10 text-warning';
                    status = 'SUSPICIOUS';
                    scoreColor = 'text-warning';
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
                      onClick={() => navigate(`/results/${item.id}`, { state: { result: item, from: '/dashboard' } })}
                      className="flex items-center space-x-4 p-4 hover:bg-background rounded-xl transition cursor-pointer group"
                    >
                      <div className="w-10 h-10 bg-primary/10 text-primary rounded-xl flex items-center justify-center shrink-0">
                        <Icon className="w-5 h-5" />
                      </div>
                      
                      <div className="w-24 shrink-0">
                        <span className={`text-[9px] font-bold px-2 py-1 rounded uppercase tracking-wider ${bgBadge}`}>
                          {status}
                        </span>
                      </div>
                      
                      <div className="flex-1 min-w-0">
                        <div className="font-bold text-base text-text-main truncate mb-0.5">
                          {item.classification === 'SCAM' ? `${item.category === 'Unknown' || !item.category ? 'Suspicious' : item.category} Scam` : (item.category === 'Unknown' || !item.category ? 'Normal Message' : item.category)}
                        </div>
                        <div className="text-sm text-text-muted truncate">
                          {item.content}
                        </div>
                      </div>

                      <div className="w-16 shrink-0 flex items-center justify-center">
                        <span className="text-[10px] font-semibold text-text-muted bg-background px-2 py-0.5 rounded">
                          {item.input_type === 'text' ? (item.content.length < 30 ? 'SMS' : 'Text') : item.input_type || 'Text'}
                        </span>
                      </div>
                      
                      <div className="text-right w-16 shrink-0">
                        <div className="text-base font-bold text-text-main">
                          <span className={scoreColor}>{item.risk_score || 0}</span><span className="text-text-muted font-semibold text-sm">/100</span>
                        </div>
                        <div className="text-[10px] text-text-muted">{timeStr}</div>
                      </div>
                      
                      <div className="shrink-0 text-text-secondary group-hover:text-text-muted transition pl-2">
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
      <div className="bg-card rounded-2xl border border-border-light p-6 shadow-sm">
        <div className="flex justify-between items-center mb-6">
          <div>
            <h3 className="font-bold text-text-main text-lg">Supported Input Types</h3>
            <p className="text-sm text-text-muted">Analyze different types of content for potential scams.</p>
          </div>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Text */}
          <div onClick={() => navigate('/analyze', { state: { tab: 'text' } })} className="border border-border-light rounded-xl p-5 hover:border-blue-200 hover:shadow-md transition cursor-pointer flex items-start space-x-4">
            <div className="w-12 h-12 bg-primary/10 text-primary rounded-xl flex items-center justify-center shrink-0">
              <FileText className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <h4 className="font-bold text-text-main text-base">Text</h4>
                <svg className="w-4 h-4 text-text-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
              </div>
              <p className="text-[11px] text-text-muted leading-snug">Analyze SMS, WhatsApp messages, emails and other text content.</p>
            </div>
          </div>
          
          {/* Image */}
          <div onClick={() => navigate('/analyze', { state: { tab: 'image' } })} className="border border-border-light rounded-xl p-5 hover:border-purple-200 hover:shadow-md transition cursor-pointer flex items-start space-x-4">
            <div className="w-12 h-12 bg-purple-50 text-purple-600 rounded-xl flex items-center justify-center shrink-0">
              <ImageIcon className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <h4 className="font-bold text-text-main text-base">Image</h4>
                <svg className="w-4 h-4 text-text-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
              </div>
              <p className="text-[11px] text-text-muted leading-snug">Extract text from screenshots and analyze for suspicious content.</p>
            </div>
          </div>

          {/* PDF */}
          <div onClick={() => navigate('/analyze', { state: { tab: 'pdf' } })} className="border border-border-light rounded-xl p-5 hover:border-danger/30 hover:shadow-md transition cursor-pointer flex items-start space-x-4">
            <div className="w-12 h-12 bg-danger/10 text-danger rounded-xl flex items-center justify-center shrink-0">
              <File className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <h4 className="font-bold text-text-main text-base">PDF</h4>
                <svg className="w-4 h-4 text-text-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
              </div>
              <p className="text-[11px] text-text-muted leading-snug">Analyze documents, invoices, and other PDF files.</p>
            </div>
          </div>

          {/* Audio */}
          <div onClick={() => navigate('/analyze', { state: { tab: 'audio' } })} className="border border-border-light rounded-xl p-5 hover:border-success/30 hover:shadow-md transition cursor-pointer flex items-start space-x-4">
            <div className="w-12 h-12 bg-success/10 text-success rounded-xl flex items-center justify-center shrink-0">
              <Mic className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <div className="flex justify-between items-center mb-1">
                <h4 className="font-bold text-text-main text-base">Audio</h4>
                <svg className="w-4 h-4 text-text-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
              </div>
              <p className="text-[11px] text-text-muted leading-snug">Transcribe and analyze audio messages and call recordings.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

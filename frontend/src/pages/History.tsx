import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  ArrowRight, ShieldAlert, Calendar, Download, 
  FileText, AlertTriangle, CheckCircle, Search, 
  File, Image as ImageIcon, Mic, MessageSquare
} from 'lucide-react';
import { analysisService, type AnalysisResult } from '../services/analysis';
import { dashboardService, type DashboardStats } from '../services/dashboard';
import { ErrorState } from '../components/common/ErrorState';

export default function History() {
  const navigate = useNavigate();
  const [history, setHistory] = useState<AnalysisResult[]>([]);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Filter States
  const [searchQuery, setSearchQuery] = useState('');
  const [riskFilter, setRiskFilter] = useState('All Risks');
  const [classificationFilter, setClassificationFilter] = useState('All');
  const [inputTypeFilter, setInputTypeFilter] = useState('All Types');
  const [dateRange, setDateRange] = useState({ start: '', end: '' });
  const [showDatePicker, setShowDatePicker] = useState(false);

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

  const filteredHistory = history.filter(item => {
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      if (!item.content.toLowerCase().includes(q) && !(item.category || '').toLowerCase().includes(q)) return false;
    }
    if (riskFilter !== 'All Risks' && item.risk_level !== riskFilter.toUpperCase()) return false;
    if (classificationFilter !== 'All' && item.classification !== classificationFilter.toUpperCase()) return false;
    if (inputTypeFilter !== 'All Types' && (item.input_type || 'text').toLowerCase() !== inputTypeFilter.toLowerCase()) return false;
    if (dateRange.start && new Date(item.created_at) < new Date(dateRange.start)) return false;
    if (dateRange.end && new Date(item.created_at) > new Date(dateRange.end)) return false;
    return true;
  });

  const handleExport = () => {
    if (filteredHistory.length === 0) {
      alert("No data to export.");
      return;
    }
    const headers = ["ID", "Date", "Classification", "Risk Level", "Risk Score", "Category", "Input Type", "Content Preview"];
    const rows = filteredHistory.map(item => [
      item.id,
      new Date(item.created_at).toLocaleString(),
      item.classification,
      item.risk_level,
      item.risk_score,
      item.category || '',
      item.input_type || 'text',
      `"${item.content.replace(/"/g, '""').substring(0, 100)}"`
    ]);
    const csvContent = "data:text/csv;charset=utf-8," + headers.join(",") + "\n" + rows.map(e => e.join(",")).join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "scamshield_history.csv");
    document.body.appendChild(link);
    link.click();
    link.remove();
  };

  const resetFilters = () => {
    setSearchQuery('');
    setRiskFilter('All Risks');
    setClassificationFilter('All');
    setInputTypeFilter('All Types');
    setDateRange({ start: '', end: '' });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-2">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-2">Analysis History</h1>
          <p className="text-text-muted text-base">View and manage all your previous analyses.</p>
        </div>
        <div className="flex flex-wrap items-center gap-3 shrink-0">
          <div className="relative">
            <button onClick={() => setShowDatePicker(!showDatePicker)} className="flex items-center space-x-2 bg-card border border-border-light hover:border-border-main text-text-secondary font-semibold py-2 px-4 rounded-lg shadow-sm transition">
              <Calendar className="w-4 h-4 text-primary" />
              <span>{dateRange.start || dateRange.end ? 'Date Filtered' : 'Date Range'}</span>
            </button>
            {showDatePicker && (
              <div className="absolute right-0 mt-2 bg-card border border-border-light shadow-lg rounded-xl p-4 z-50 w-64">
                <div className="space-y-3">
                  <div>
                    <label className="block text-xs font-bold text-text-muted mb-1">Start Date</label>
                    <input type="date" value={dateRange.start} onChange={e => setDateRange({...dateRange, start: e.target.value})} className="w-full border border-border-light rounded px-2 py-1 bg-background text-sm text-text-main focus:outline-none" />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-text-muted mb-1">End Date</label>
                    <input type="date" value={dateRange.end} onChange={e => setDateRange({...dateRange, end: e.target.value})} className="w-full border border-border-light rounded px-2 py-1 bg-background text-sm text-text-main focus:outline-none" />
                  </div>
                  <button onClick={() => setShowDatePicker(false)} className="w-full bg-primary hover:bg-primary-hover text-white text-sm font-bold py-1.5 rounded transition">Apply</button>
                </div>
              </div>
            )}
          </div>
          <button onClick={handleExport} className="flex items-center space-x-2 bg-primary hover:bg-primary-hover text-white font-semibold py-2 px-4 rounded-lg shadow-sm transition">
            <Download className="w-4 h-4" />
            <span>Export CSV</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-primary/10 text-primary rounded-full flex items-center justify-center shrink-0">
            <FileText className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Total Analyses</div>
            <div className="text-2xl font-bold text-text-main leading-none mb-1">{loading ? '-' : stats?.total_analyses || 0}</div>
            <div className="text-[11px] text-text-muted">All time</div>
          </div>
        </div>

        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-danger/10 text-danger rounded-full flex items-center justify-center shrink-0">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Scams Detected</div>
            <div className="text-2xl font-bold text-text-main leading-none mb-1">{loading ? '-' : stats?.scams_detected || 0}</div>
            <div className="text-[11px] text-text-muted">
              {stats?.total_analyses ? Math.round((stats.scams_detected / stats.total_analyses) * 100) : 0}% of total
            </div>
          </div>
        </div>

        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-success/10 text-success rounded-full flex items-center justify-center shrink-0">
            <CheckCircle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Safe Messages</div>
            <div className="text-2xl font-bold text-text-main leading-none mb-1">{loading ? '-' : stats?.safe_messages || 0}</div>
            <div className="text-[11px] text-text-muted">
              {stats?.total_analyses ? Math.round((stats.safe_messages / stats.total_analyses) * 100) : 0}% of total
            </div>
          </div>
        </div>

        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-warning/10 text-warning rounded-full flex items-center justify-center shrink-0">
            <ShieldAlert className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Average Risk Score</div>
            <div className="text-2xl font-bold text-text-main leading-none mb-1">{loading ? '-' : avgRiskScore}</div>
            <div className="text-[11px] text-text-muted">Across all analyses</div>
          </div>
        </div>
      </div>

      {/* Filters & Table container */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden flex flex-col">
        {/* Filter Bar */}
        <div className="p-4 border-b border-border-light flex flex-col lg:flex-row items-center gap-4 bg-background/50">
          <div className="relative w-full lg:max-w-md">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search className="h-4 w-4 text-text-muted" />
            </div>
            <input
              type="text"
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              placeholder="Search by keywords, content, or category..."
              className="block w-full pl-10 pr-3 py-2.5 border border-border-light rounded-xl leading-5 bg-card placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary sm:text-base transition-colors text-text-main"
            />
          </div>
          
          <div className="flex-1 flex flex-wrap lg:flex-nowrap items-center gap-3 w-full lg:w-auto">
            <div className="flex-1 min-w-[120px]">
              <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1 ml-1">Risk Level</div>
              <div className="relative">
                <select value={riskFilter} onChange={e => setRiskFilter(e.target.value)} className="block w-full pl-3 pr-8 py-2 text-base border border-border-light rounded-lg appearance-none bg-card focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary font-semibold text-text-secondary">
                  <option>All Risks</option>
                  <option>High</option>
                  <option>Medium</option>
                  <option>Low</option>
                </select>
                <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-text-muted">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                </div>
              </div>
            </div>
            
            <div className="flex-1 min-w-[120px]">
              <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1 ml-1">Classification</div>
              <div className="relative">
                <select value={classificationFilter} onChange={e => setClassificationFilter(e.target.value)} className="block w-full pl-3 pr-8 py-2 text-base border border-border-light rounded-lg appearance-none bg-card focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary font-semibold text-text-secondary">
                  <option>All</option>
                  <option>Scam</option>
                  <option>Genuine</option>
                </select>
                <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-text-muted">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                </div>
              </div>
            </div>

            <div className="flex-1 min-w-[120px]">
              <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1 ml-1">Input Type</div>
              <div className="relative">
                <select value={inputTypeFilter} onChange={e => setInputTypeFilter(e.target.value)} className="block w-full pl-3 pr-8 py-2 text-base border border-border-light rounded-lg appearance-none bg-card focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary font-semibold text-text-secondary">
                  <option>All Types</option>
                  <option>Text</option>
                  <option>Image</option>
                  <option>Audio</option>
                  <option>PDF</option>
                </select>
                <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-text-muted">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                </div>
              </div>
            </div>
            
            <div className="mt-5 ml-auto">
              <button onClick={resetFilters} className="flex items-center space-x-1.5 text-primary hover:text-blue-700 font-bold text-base px-3 py-2 bg-primary/10 hover:bg-primary/20 rounded-lg transition-colors">
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
                 <div className="w-6 h-6 bg-background rounded"></div>
                 <div className="flex-1 h-6 bg-background rounded"></div>
               </div>
             ))}
          </div>
        ) : error ? (
          <div className="p-8">
            <ErrorState message={error} onRetry={fetchData} />
          </div>
        ) : filteredHistory.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="w-full text-left whitespace-nowrap">
              <thead className="bg-card border-b border-border-light">
                <tr>
                  <th className="px-6 py-4 text-[10px] font-bold text-text-muted uppercase tracking-wider w-10">
                    <input type="checkbox" className="rounded border-border-main text-primary focus:ring-primary" />
                  </th>
                  <th className="px-4 py-4 text-[10px] font-bold text-text-muted uppercase tracking-wider">
                    Date & Time
                  </th>
                  <th className="px-4 py-4 text-[10px] font-bold text-text-muted uppercase tracking-wider">Content Preview</th>
                  <th className="px-4 py-4 text-[10px] font-bold text-text-muted uppercase tracking-wider">Input Type</th>
                  <th className="px-4 py-4 text-[10px] font-bold text-text-muted uppercase tracking-wider">Category</th>
                  <th className="px-4 py-4 text-[10px] font-bold text-text-muted uppercase tracking-wider">Classification</th>
                  <th className="px-4 py-4 text-[10px] font-bold text-text-muted uppercase tracking-wider">Risk Score</th>
                  <th className="px-4 py-4 text-[10px] font-bold text-text-muted uppercase tracking-wider">Risk Level</th>
                  <th className="px-6 py-4 text-[10px] font-bold text-text-muted uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-light bg-background">
                {filteredHistory.map((item) => {
                  
                  let badge = 'bg-success/20 text-success';
                  let status = 'LOW';
                  let scoreColor = 'text-success';
                  
                  if (item.risk_level === 'HIGH' || item.risk_level === 'CRITICAL') {
                    badge = 'bg-danger/20 text-red-700';
                    status = 'HIGH';
                    scoreColor = 'text-danger';
                  } else if (item.risk_level === 'MEDIUM') {
                    badge = 'bg-orange-100 text-orange-700';
                    status = 'MEDIUM';
                    scoreColor = 'text-orange-500';
                  }

                  let typeIcon = <FileText className="w-3.5 h-3.5" />;
                  if (item.input_type === 'image') typeIcon = <ImageIcon className="w-3.5 h-3.5" />;
                  if (item.input_type === 'audio') typeIcon = <Mic className="w-3.5 h-3.5" />;
                  if (item.input_type === 'pdf') typeIcon = <File className="w-3.5 h-3.5" />;
                  if (item.input_type === 'email') typeIcon = <MessageSquare className="w-3.5 h-3.5" />;

                  return (
                    <tr key={item.id} className="hover:bg-card transition group">
                      <td className="px-6 py-4">
                        <input type="checkbox" className="rounded border-border-main text-primary focus:ring-primary" />
                      </td>
                      <td className="px-4 py-4 text-sm text-text-muted font-semibold">
                        {new Date(item.created_at).toLocaleString()}
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center space-x-3">
                          <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 bg-primary/10 text-primary`}>
                            {typeIcon}
                          </div>
                          <div>
                            <div className="text-sm font-bold text-text-main max-w-[200px] truncate">
                              {item.content}
                            </div>
                            <div className="text-xs text-text-muted mt-0.5 max-w-[200px] truncate">
                              {item.original_filename || 'Direct Input'}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-sm font-bold text-text-secondary capitalize">
                        {item.input_type || 'Text'}
                      </td>
                      <td className="px-4 py-4">
                        <span className="text-xs font-bold text-blue-700 bg-primary/10 px-2.5 py-1 rounded">
                          {item.category || 'General'}
                        </span>
                      </td>
                      <td className="px-4 py-4">
                        <span className={`text-xs font-bold px-2.5 py-1 rounded uppercase tracking-wider ${item.classification === 'SCAM' ? 'bg-danger/20 text-red-700' : 'bg-success/20 text-success'}`}>
                          {item.classification}
                        </span>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center space-x-2">
                          <div className="w-16 h-2 bg-background rounded-full overflow-hidden border border-border-light">
                            <div className={`h-full ${status === 'HIGH' ? 'bg-danger' : status === 'MEDIUM' ? 'bg-warning' : 'bg-success'}`} style={{ width: `${item.risk_score}%` }}></div>
                          </div>
                          <span className={`text-sm font-bold ${scoreColor}`}>{item.risk_score}</span>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full uppercase tracking-wider ${badge}`}>
                          {status} RISK
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right flex items-center justify-end space-x-3">
                        <button onClick={() => navigate(`/results/${item.id}`, { state: { result: item, from: '/history' } })} className="flex items-center space-x-1 text-sm font-bold text-primary hover:text-blue-700">
                          <span>View</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="p-12 text-center flex flex-col items-center">
            <Search className="w-10 h-10 text-text-muted/30 mb-4" />
            <h3 className="text-lg font-bold text-text-main mb-1">No results found</h3>
            <p className="text-text-muted text-sm">Try adjusting your search or filters.</p>
          </div>
        )}
      </div>
    </div>
  );
}

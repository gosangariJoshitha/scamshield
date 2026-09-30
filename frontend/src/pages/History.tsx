import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { ArrowRight, ShieldAlert } from 'lucide-react';
import { analysisService, type AnalysisResult } from '../services/analysis';
import { EmptyState } from '../components/common/EmptyState';
import { ErrorState } from '../components/common/ErrorState';

export default function History() {
  const navigate = useNavigate();
  const [history, setHistory] = useState<AnalysisResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchHistory = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await analysisService.getHistory();
      setHistory(res);
    } catch (err) {
      console.error("Failed to load history", err);
      setError("Failed to load analysis history. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHistory();
  }, []);

  return (
    <div className="max-w-5xl">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-800 mb-1">Analysis History</h1>
        <p className="text-slate-500 text-sm">View all your previous analyses.</p>
      </div>
      
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 min-h-[400px] flex flex-col">
        {loading ? (
          <div className="flex-1 flex flex-col p-6 space-y-4">
             {[1, 2, 3, 4, 5].map(i => (
               <div key={i} className="animate-pulse flex items-start space-x-3 border-b border-slate-100 pb-4 w-full">
                 <div className="flex-1 space-y-3">
                   <div className="flex gap-2">
                     <div className="h-4 bg-slate-100 rounded w-16"></div>
                     <div className="h-4 bg-slate-100 rounded w-32"></div>
                   </div>
                   <div className="h-3 bg-slate-100 rounded w-full"></div>
                   <div className="h-3 bg-slate-100 rounded w-2/3"></div>
                 </div>
               </div>
             ))}
          </div>
        ) : error ? (
          <div className="p-8 flex-1 flex flex-col justify-center">
            <ErrorState message={error} onRetry={fetchHistory} />
          </div>
        ) : history.length > 0 ? (
          <div className="divide-y divide-slate-100">
            {history.map((item) => (
              <div key={item.id} className="p-6 hover:bg-slate-50 transition cursor-pointer flex items-center justify-between" onClick={() => navigate('/results', { state: { result: item, from: '/history' } })}>
                <div className="flex-1 pr-4">
                  <div className="flex items-center space-x-3 mb-2">
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded uppercase tracking-wider ${
                      item.risk_level === 'HIGH' || item.risk_level === 'CRITICAL' ? 'bg-red-100 text-red-600' : 
                      item.risk_level === 'MEDIUM' ? 'bg-amber-100 text-amber-600' : 
                      'bg-green-100 text-green-600'
                    }`}>
                      {item.risk_level} RISK
                    </span>
                    <span className="text-sm font-bold text-slate-800">{item.category}</span>
                    <span className="text-xs text-slate-400">
                      {new Date(item.created_at).toLocaleString()}
                    </span>
                  </div>
                  <p className="text-sm text-slate-600 line-clamp-2">{item.content}</p>
                </div>
                <div className="flex items-center justify-center w-10 h-10 bg-white border border-slate-200 rounded-full shadow-sm text-slate-400 group-hover:text-blue-500 group-hover:border-blue-200 transition-colors">
                  <ArrowRight className="w-4 h-4" />
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="p-8 flex-1 flex flex-col justify-center">
            <EmptyState 
              title="No analyses yet" 
              description="Start your first analysis to see your history here."
              icon={<ShieldAlert className="w-8 h-8" />}
              action={
                <Link to="/analyze" className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2.5 px-8 rounded-lg shadow-lg shadow-blue-500/30 transition-all inline-block text-sm">
                  Start Analysis
                </Link>
              }
            />
          </div>
        )}
      </div>
    </div>
  );
}

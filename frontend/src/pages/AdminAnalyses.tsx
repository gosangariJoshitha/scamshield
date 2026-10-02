import React, { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Search, ChevronLeft, ChevronRight, Eye } from 'lucide-react';
import { Link } from 'react-router-dom';
import { api } from '../services/api';

interface AnalysisItem {
  id: number;
  created_at: string;
  input_type: string;
  classification: string;
  category: string;
  risk_score: number;
  risk_level: string;
  status: string;
  user: string;
}

export default function AdminAnalyses() {
  const [searchParams] = useSearchParams();
  const [analyses, setAnalyses] = useState<AnalysisItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Pagination & Filtering
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  
  const [classificationFilter, setClassificationFilter] = useState('');
  const [riskFilter, setRiskFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [search, setSearch] = useState(searchParams.get('search') ?? '');

  const fetchAnalyses = useCallback(async () => {
    try {
      setLoading(true);
      const skip = (page - 1) * pageSize;
      const params = new URLSearchParams({
        skip: String(skip),
        limit: String(pageSize),
      });
      if (classificationFilter) params.set('classification', classificationFilter);
      if (riskFilter) params.set('risk_level', riskFilter);
      if (statusFilter) params.set('status', statusFilter);
      if (search.trim()) params.set('search', search.trim());

      const response = await api.get(`/admin/analyses?${params.toString()}`);
      setAnalyses(response.data.items ?? []);
      setTotal(response.data.total ?? 0);
      setTotalPages(Math.max(1, response.data.total_pages ?? 1));
      setError(null);
    } catch (err) {
      setError('Failed to load analyses');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, classificationFilter, riskFilter, statusFilter, search]);

  useEffect(() => {
    void fetchAnalyses();
  }, [fetchAnalyses]);

  const handlePageChange = (newPage: number) => {
    if (newPage >= 1 && newPage <= totalPages) {
      setPage(newPage);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-1">Analysis Management</h1>
          <p className="text-text-muted">View and search through all system analyses.</p>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-card rounded-xl shadow-sm border border-border-light p-4 flex flex-col sm:flex-row gap-4 items-center justify-between">
        <div className="flex items-center gap-4 w-full sm:w-auto">
          <div className="relative flex-1 sm:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
            <input 
              type="text" 
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              placeholder="Search ID, user, or category..." 
              aria-label="Search analyses"
              className="w-full pl-9 pr-4 py-2 bg-background border border-border-light rounded-lg text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
            />
          </div>
        </div>
        
        <div className="flex items-center gap-3 w-full sm:w-auto">
          <select 
            value={classificationFilter} 
            onChange={(e) => { setClassificationFilter(e.target.value); setPage(1); }}
            className="px-3 py-2 bg-background border border-border-light rounded-lg text-sm text-text-main focus:outline-none focus:border-primary w-full sm:w-auto"
          >
            <option value="">All Classifications</option>
            <option value="SCAM">Scam</option>
            <option value="SUSPICIOUS">Suspicious</option>
            <option value="GENUINE">Genuine</option>
          </select>
          <select 
            value={riskFilter} 
            onChange={(e) => { setRiskFilter(e.target.value); setPage(1); }}
            className="px-3 py-2 bg-background border border-border-light rounded-lg text-sm text-text-main focus:outline-none focus:border-primary w-full sm:w-auto"
          >
            <option value="">All Risks</option>
            <option value="CRITICAL">Critical</option>
            <option value="HIGH">High</option>
            <option value="MEDIUM">Medium</option>
            <option value="LOW">Low</option>
          </select>
          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
            aria-label="Filter by processing status"
            className="px-3 py-2 bg-background border border-border-light rounded-lg text-sm text-text-main focus:outline-none focus:border-primary w-full sm:w-auto"
          >
            <option value="">All Statuses</option>
            <option value="COMPLETED">Completed</option>
            <option value="PROCESSING">Processing</option>
            <option value="FAILED">Failed</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
        {loading && analyses.length === 0 ? (
          <div className="p-12 flex justify-center">
            <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : error ? (
          <div className="p-12 text-center text-danger font-medium">{error}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm whitespace-nowrap">
              <thead className="bg-background text-text-muted text-[11px] uppercase tracking-wider border-b border-border-light">
                <tr>
                  <th className="px-6 py-4 font-bold">ID</th>
                  <th className="px-6 py-4 font-bold">Date</th>
                  <th className="px-6 py-4 font-bold">Type</th>
                  <th className="px-6 py-4 font-bold">Classification</th>
                  <th className="px-6 py-4 font-bold">Risk</th>
                  <th className="px-6 py-4 font-bold">User</th>
                  <th className="px-6 py-4 font-bold">Status</th>
                  <th className="px-6 py-4 font-bold text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-light">
                {analyses.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="px-6 py-12 text-center text-text-muted">
                      No analyses found matching your criteria.
                    </td>
                  </tr>
                ) : (
                  analyses.map((item) => (
                    <tr key={item.id} className="hover:bg-background/50 transition-colors">
                      <td className="px-6 py-4 font-mono font-medium">
                        <Link to={`/admin/analyses/${item.id}`} className="text-primary hover:underline">
                          #ANL_{item.id}
                        </Link>
                      </td>
                      <td className="px-6 py-4 text-text-secondary">{new Date(item.created_at).toLocaleString()}</td>
                      <td className="px-6 py-4">
                        <span className="text-[11px] font-bold uppercase tracking-wider bg-background border border-border-light px-2 py-1 rounded">
                          {item.input_type}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider ${
                          item.classification === 'SCAM' ? 'bg-danger/10 text-danger' : 
                          item.classification === 'SUSPICIOUS' ? 'bg-warning/10 text-warning' : 
                          'bg-success/10 text-success'
                        }`}>
                          {item.classification}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider ${
                          ['HIGH', 'CRITICAL'].includes(item.risk_level) ? 'bg-danger/10 text-danger' : 
                          item.risk_level === 'MEDIUM' ? 'bg-warning/10 text-warning' : 
                          'bg-success/10 text-success'
                        }`}>
                          {item.risk_level} ({item.risk_score})
                        </span>
                      </td>
                      <td className="px-6 py-4 text-text-secondary truncate max-w-[150px]">{item.user}</td>
                      <td className="px-6 py-4">
                        <span className="text-text-secondary text-xs font-semibold">{item.status}</span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <Link 
                          to={`/admin/analyses/${item.id}`}
                          className="inline-flex items-center justify-center p-2 text-text-muted hover:text-primary hover:bg-primary/10 rounded-lg transition-colors"
                          title="View Details"
                        >
                          <Eye className="w-4 h-4" />
                        </Link>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
        
        {/* Pagination */}
        {!loading && totalPages > 1 && (
          <div className="p-4 border-t border-border-light flex items-center justify-between bg-background/50">
            <div className="text-sm text-text-muted font-medium">
              Showing <span className="text-text-main font-bold">{(page - 1) * pageSize + 1}</span> to <span className="text-text-main font-bold">{Math.min(page * pageSize, total)}</span> of <span className="text-text-main font-bold">{total}</span> results
            </div>
            <div className="flex items-center space-x-2">
              <button 
                onClick={() => handlePageChange(page - 1)}
                disabled={page === 1}
                className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
              <div className="text-sm font-semibold text-text-main px-3 py-1 bg-card border border-border-light rounded-lg">
                Page {page} of {totalPages}
              </div>
              <button 
                onClick={() => handlePageChange(page + 1)}
                disabled={page === totalPages}
                className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        )}
      </div>

    </div>
  );
}

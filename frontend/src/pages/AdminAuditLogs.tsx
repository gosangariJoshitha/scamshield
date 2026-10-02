import React, { useCallback, useEffect, useState } from 'react';
import { 
  Search, ChevronLeft, ChevronRight, CheckCircle, XCircle
} from 'lucide-react';
import { api } from '../services/api';

interface AuditLog {
  id: number;
  actor: string;
  action: string;
  resource_type: string;
  resource_id: string;
  result: string;
  created_at: string;
}

export default function AdminAuditLogs() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [actionFilter, setActionFilter] = useState('');

  const fetchLogs = useCallback(async () => {
    try {
      setLoading(true);
      const skip = (page - 1) * pageSize;
      let url = `/admin/audit?skip=${skip}&limit=${pageSize}`;
      if (actionFilter) url += `&action=${encodeURIComponent(actionFilter)}`;
      
      const response = await api.get(url);
      setLogs(response.data.items);
      setTotal(response.data.total);
      setTotalPages(response.data.total_pages);
      setError(null);
    } catch (err) {
      setError('Failed to load audit logs');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, actionFilter]);

  useEffect(() => {
    void fetchLogs();
  }, [fetchLogs]);

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-1">Audit Logs</h1>
          <p className="text-text-muted">Track administrative and system actions for security compliance.</p>
        </div>
      </div>

      <div className="bg-card rounded-xl shadow-sm border border-border-light p-4 flex flex-col sm:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-4 w-full sm:w-auto">
          <div className="relative flex-1 sm:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
            <input 
              type="text" 
              value={actionFilter}
              onChange={e => { setActionFilter(e.target.value); setPage(1); }}
              placeholder="Search by Action (e.g. LOGIN)..." 
              className="w-full pl-9 pr-4 py-2 bg-background border border-border-light rounded-lg text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
            />
          </div>
        </div>
      </div>

      <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
        {loading && logs.length === 0 ? (
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
                  <th className="px-6 py-4 font-bold">Time</th>
                  <th className="px-6 py-4 font-bold">Actor</th>
                  <th className="px-6 py-4 font-bold">Action</th>
                  <th className="px-6 py-4 font-bold">Resource Type</th>
                  <th className="px-6 py-4 font-bold">Resource ID</th>
                  <th className="px-6 py-4 font-bold">Result</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-light">
                {logs.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-text-muted">No audit logs found.</td>
                  </tr>
                ) : (
                  logs.map((item) => (
                    <tr key={item.id} className="hover:bg-background/50 transition-colors">
                      <td className="px-6 py-4 text-text-secondary font-mono text-xs">
                        {new Date(item.created_at).toLocaleString()}
                      </td>
                      <td className="px-6 py-4">
                        <span className="font-semibold text-text-main">{item.actor}</span>
                      </td>
                      <td className="px-6 py-4">
                        <span className="bg-background border border-border-light px-2 py-1 rounded text-xs font-bold text-text-secondary">
                          {item.action}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-text-secondary text-xs font-semibold">
                        {item.resource_type}
                      </td>
                      <td className="px-6 py-4 font-mono text-xs text-text-secondary">
                        {item.resource_id || '-'}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider flex items-center w-max gap-1 ${
                          item.result === 'SUCCESS' ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'
                        }`}>
                          {item.result === 'SUCCESS' ? <CheckCircle className="w-3 h-3" /> : <XCircle className="w-3 h-3" />}
                          {item.result}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
        
        {!loading && totalPages > 1 && (
          <div className="p-4 border-t border-border-light flex items-center justify-between bg-background/50">
            <div className="text-sm text-text-muted font-medium">
              Showing <span className="text-text-main font-bold">{(page - 1) * pageSize + 1}</span> to <span className="text-text-main font-bold">{Math.min(page * pageSize, total)}</span> of <span className="text-text-main font-bold">{total}</span> logs
            </div>
            <div className="flex items-center space-x-2">
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50 transition-colors">
                <ChevronLeft className="w-5 h-5" />
              </button>
              <div className="text-sm font-semibold text-text-main px-3 py-1 bg-card border border-border-light rounded-lg">
                Page {page} of {totalPages}
              </div>
              <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages} className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50 transition-colors">
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        )}
      </div>

    </div>
  );
}

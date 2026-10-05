import React, { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  Users, ChevronLeft, ChevronRight, CheckCircle
} from 'lucide-react';
import { api } from '../services/api';
import AdminBackButton from '../components/AdminBackButton';

interface CommunityReport {
  id: number;
  category: string;
  content: string;
  description: string;
  evidence: string;
  status: string;
  created_at: string;
  reporter: string;
}

export default function AdminCommunity() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [reports, setReports] = useState<CommunityReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const search = searchParams.get('search') ?? '';
  const [categoryFilter, setCategoryFilter] = useState('');
  
  const [selectedReport, setSelectedReport] = useState<CommunityReport | null>(null);
  const [actionNotes, setActionNotes] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const fetchReports = useCallback(async () => {
    try {
      setLoading(true);
      const skip = (page - 1) * pageSize;
      const params = new URLSearchParams({ skip: String(skip), limit: String(pageSize) });
      const reportId = searchParams.get('report');
      if (reportId) params.set('report_id', reportId);
      if (statusFilter) params.set('status', statusFilter);
      if (categoryFilter.trim()) params.set('category', categoryFilter.trim());
      if (search.trim()) params.set('search', search.trim());
      const response = await api.get(`/admin/community/reports?${params.toString()}`);
      setReports(response.data.items);
      if (reportId) {
        const selected = response.data.items.find((report: CommunityReport) => String(report.id) === reportId);
        if (selected) setSelectedReport(selected);
      }
      setTotal(response.data.total);
      setTotalPages(response.data.total_pages);
      setError(null);
    } catch (err) {
      setError('Failed to load community reports');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, statusFilter, search, categoryFilter, searchParams]);

  useEffect(() => {
    void fetchReports();
  }, [fetchReports]);

  const handleAction = async (action: string) => {
    if (!selectedReport) return;
    
    try {
      setActionLoading(true);
      await api.post(`/admin/community/reports/${selectedReport.id}/action`, {
        action,
        notes: actionNotes
      });
      setSelectedReport(null);
      setActionNotes('');
      if (searchParams.has('report')) {
        const nextParams = new URLSearchParams(searchParams);
        nextParams.delete('report');
        setSearchParams(nextParams, { replace: true });
      } else {
        await fetchReports();
      }
    } catch (err) {
      console.error("Action failed:", err);
      alert("Failed to process action");
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      <div className="flex flex-col @content-sm:flex-row @content-sm:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-1">Community Moderation</h1>
          <p className="text-text-muted">Review, verify or reject user-submitted scam reports.</p>
        </div>
        <AdminBackButton to="/admin" label="Back to Dashboard" />
      </div>

      <div className="bg-card rounded-xl shadow-sm border border-border-light p-4 flex flex-col @content-sm:flex-row justify-between items-center gap-4">
        <div className="flex w-full flex-col gap-3 @content-sm:w-auto @content-sm:flex-row">
          <input value={categoryFilter} onChange={(event) => { setCategoryFilter(event.target.value); setPage(1); }} placeholder="Category" aria-label="Filter reports by category" className="w-full rounded-lg border border-border-light bg-background px-3 py-2 text-sm text-text-main outline-none focus:border-primary @content-sm:w-40" />
          <select 
            value={statusFilter} 
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
            className="px-3 py-2 bg-background border border-border-light rounded-lg text-sm text-text-main focus:outline-none focus:border-primary w-full @content-sm:w-auto"
          >
            <option value="">All Statuses</option>
            <option value="Pending">Pending</option>
            <option value="NEEDS_INFORMATION">Needs Info</option>
            <option value="VERIFIED">Verified</option>
            <option value="REJECTED">Rejected</option>
          </select>
        </div>
        <span className="text-sm text-text-muted">{total} reports</span>
      </div>

      <div className="grid grid-cols-1 @content-lg:grid-cols-3 gap-6">
        
        {/* Table Area */}
        <div className={`bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden ${selectedReport ? 'hidden @content-lg:block @content-lg:col-span-2' : '@content-lg:col-span-3'}`}>
          {loading && reports.length === 0 ? (
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
                    <th className="px-6 py-4 font-bold">Category</th>
                    <th className="px-6 py-4 font-bold">Reported by</th>
                    <th className="px-6 py-4 font-bold">Status</th>
                    <th className="px-6 py-4 font-bold">Date</th>
                    <th className="px-6 py-4 font-bold">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-light">
                  {reports.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center text-text-muted">No reports found.</td>
                    </tr>
                  ) : (
                    reports.map(r => (
                      <tr 
                        key={r.id} 
                        role="button"
                        tabIndex={0}
                        aria-label={`Open report ${r.id} submitted by ${r.reporter || 'unknown user'}`}
                        className={`hover:bg-background/50 cursor-pointer transition-colors ${selectedReport?.id === r.id ? 'bg-primary/5' : ''}`}
                        onClick={() => setSelectedReport(r)}
                        onKeyDown={(event) => {
                          if (event.key === 'Enter' || event.key === ' ') {
                            event.preventDefault();
                            setSelectedReport(r);
                          }
                        }}
                      >
                        <td className="px-6 py-4 font-mono font-medium">#REP_{r.id}</td>
                        <td className="px-6 py-4">
                          <span className="bg-primary/10 text-primary px-2 py-1 rounded text-xs font-bold">{r.category}</span>
                        </td>
                        <td className="px-6 py-4 text-text-secondary">{r.reporter || 'Unknown user'}</td>
                        <td className="px-6 py-4">
                          <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider ${
                            r.status === 'VERIFIED' ? 'bg-success/10 text-success' : 
                            r.status === 'REJECTED' ? 'bg-danger/10 text-danger' : 
                            r.status === 'NEEDS_INFORMATION' ? 'bg-warning/10 text-warning' : 
                            'bg-gray-500/10 text-gray-500'
                          }`}>
                            {r.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-text-secondary">{new Date(r.created_at).toLocaleDateString()}</td>
                        <td className="px-6 py-4 text-primary font-semibold text-xs">Review</td>
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
              <div className="flex items-center space-x-2 ml-auto">
                <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50 transition-colors">
                  <ChevronLeft className="w-5 h-5" />
                </button>
                <div className="text-sm font-semibold text-text-main px-3 py-1 bg-card border border-border-light rounded-lg">
                  {page} / {totalPages}
                </div>
                <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages} className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50 transition-colors">
                  <ChevronRight className="w-5 h-5" />
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Detail Panel */}
        {selectedReport && (
          <div className="bg-card rounded-2xl shadow-sm border border-border-light flex flex-col h-fit @content-lg:col-span-1">
            <div className="p-4 border-b border-border-light flex items-center justify-between bg-background/50 rounded-t-2xl">
              <h3 className="font-bold text-text-main">Review Report #{selectedReport.id}</h3>
              <button onClick={() => setSelectedReport(null)} className="text-text-muted hover:text-text-main @content-lg:hidden">Close</button>
            </div>
            <div className="p-4 space-y-4 max-h-[60vh] overflow-y-auto custom-scrollbar">
              
              <div>
                <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider mb-1">Reporter</p>
                <div className="text-sm font-medium text-text-main flex items-center gap-2">
                  <Users className="w-4 h-4 text-primary" />
                  {selectedReport.reporter}
                </div>
              </div>

              <div>
                <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider mb-1">Reported Content</p>
                <div className="bg-background rounded-xl p-3 border border-border-light text-sm text-text-secondary font-mono break-all max-h-32 overflow-y-auto custom-scrollbar">
                  {selectedReport.content}
                </div>
              </div>

              <div>
                <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider mb-1">Description & Evidence</p>
                <p className="text-sm text-text-main bg-background p-3 rounded-lg border border-border-light mb-2">{selectedReport.description || "No description provided."}</p>
                {selectedReport.evidence && (
                  <p className="text-sm text-text-secondary italic bg-background p-3 rounded-lg border border-border-light">"{selectedReport.evidence}"</p>
                )}
              </div>

              {['PENDING', 'NEEDS_INFORMATION'].includes(selectedReport.status.toUpperCase()) ? (
                <div className="border-t border-border-light pt-4 mt-4 space-y-3">
                  <div>
                    <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider mb-1 block">Moderator Notes (Optional)</label>
                    <textarea 
                      value={actionNotes}
                      onChange={e => setActionNotes(e.target.value)}
                      className="w-full bg-background border border-border-light rounded-lg p-2 text-sm focus:outline-none focus:border-primary"
                      rows={2}
                      placeholder="Add reason for verification or rejection..."
                    />
                  </div>
                  <div className="flex flex-col gap-2">
                    <button 
                      onClick={() => handleAction('VERIFY')} 
                      disabled={actionLoading}
                      className="flex items-center justify-center gap-2 w-full py-2 bg-success text-white font-bold rounded-lg hover:bg-green-600 disabled:opacity-50 transition-colors"
                    >
                      <CheckCircle className="w-4 h-4" />
                      Verify report
                    </button>
                    <div className="flex gap-2">
                      <button 
                        onClick={() => handleAction('NEEDS_INFORMATION')} 
                        disabled={actionLoading}
                        className="flex-1 py-2 bg-warning/10 text-warning font-bold rounded-lg hover:bg-warning/20 disabled:opacity-50 transition-colors"
                      >
                        Request Info
                      </button>
                      <button 
                        onClick={() => handleAction('REJECT')} 
                        disabled={actionLoading}
                        className="flex-1 py-2 bg-danger/10 text-danger font-bold rounded-lg hover:bg-danger/20 disabled:opacity-50 transition-colors"
                      >
                        Reject
                      </button>
                    </div>
                  </div>
                </div>
              ) : selectedReport.status.toUpperCase() === 'VERIFIED' ? (
                <div className="border-t border-border-light pt-4 mt-4 space-y-3">
                  <p className="text-sm text-text-secondary">This report is verified. You may separately add its pattern to the trusted knowledge base.</p>
                  <button
                    onClick={() => handleAction('CONVERT_TO_KNOWLEDGE')}
                    disabled={actionLoading}
                    className="w-full rounded-lg border border-primary/20 bg-primary/10 py-2 text-sm font-bold text-primary hover:bg-primary/20 disabled:opacity-50"
                  >
                    {actionLoading ? 'Adding…' : 'Add verified pattern to Knowledge Base'}
                  </button>
                </div>
              ) : (
                <div className="border-t border-border-light pt-4 mt-4">
                  <div className="bg-background rounded-xl p-4 text-center border border-border-light">
                    <p className="text-sm text-text-muted mb-1">This report is already processed</p>
                    <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${
                      selectedReport.status === 'VERIFIED' ? 'bg-success/20 text-success' : 'bg-danger/20 text-danger'
                    }`}>
                      {selectedReport.status}
                    </span>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>

    </div>
  );
}

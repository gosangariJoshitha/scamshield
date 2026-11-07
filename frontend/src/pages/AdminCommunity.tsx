import React, { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  Users, ChevronLeft, ChevronRight, CheckCircle,
  FileWarning, Search, RefreshCw, X, BookOpen, ShieldCheck
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

  // Filters
  const [statusFilter, setStatusFilter] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [searchInput, setSearchInput] = useState(() => searchParams.get('search') ?? '');

  const [selectedReport, setSelectedReport] = useState<CommunityReport | null>(null);
  const [actionNotes, setActionNotes] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [actionNotice, setActionNotice] = useState<string | null>(null);

  const fetchReports = useCallback(async () => {
    try {
      setLoading(true);
      const skip = (page - 1) * pageSize;
      const params = new URLSearchParams({ skip: String(skip), limit: String(pageSize) });
      const reportId = searchParams.get('report');
      if (reportId) params.set('report_id', reportId);
      if (statusFilter) params.set('status', statusFilter);
      if (categoryFilter.trim()) params.set('category', categoryFilter.trim());
      if (searchInput.trim()) params.set('search', searchInput.trim());

      const response = await api.get(`/admin/community/reports?${params.toString()}`);
      setReports(response.data.items ?? []);
      if (reportId) {
        const selected = (response.data.items ?? []).find((report: CommunityReport) => String(report.id) === reportId);
        if (selected) setSelectedReport(selected);
      }
      setTotal(response.data.total ?? 0);
      setTotalPages(Math.max(1, response.data.total_pages ?? 1));
      setError(null);
    } catch (err) {
      setError('Failed to load community reports. Check connection and retry.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, statusFilter, categoryFilter, searchInput, searchParams]);

  useEffect(() => {
    void fetchReports();
  }, [fetchReports]);

  const handleAction = async (action: string) => {
    if (!selectedReport) return;

    try {
      setActionLoading(true);
      setActionError(null);
      await api.post(`/admin/community/reports/${selectedReport.id}/action`, {
        action,
        notes: actionNotes,
      });
      setActionNotice(
        action === 'CONVERT_TO_KNOWLEDGE'
          ? 'Knowledge base draft created. Approve it in the Knowledge Base to index into ChromaDB.'
          : `Report marked as ${action.toLowerCase().replaceAll('_', ' ')}.`
      );
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
      console.error('Action failed:', err);
      setActionError('Unable to process this moderation action. Please retry.');
    } finally {
      setActionLoading(false);
    }
  };

  const statusPills = [
    { label: 'All Reports', value: '' },
    { label: 'Pending', value: 'Pending' },
    { label: 'Needs Info', value: 'NEEDS_INFORMATION' },
    { label: 'Verified', value: 'VERIFIED' },
    { label: 'Rejected', value: 'REJECTED' },
  ];

  const getStatusBadge = (status: string) => {
    const s = (status || '').toUpperCase();
    if (s === 'VERIFIED') return 'bg-success/10 text-success border-success/20';
    if (s === 'REJECTED') return 'bg-danger/10 text-danger border-danger/20';
    if (s === 'NEEDS_INFORMATION') return 'bg-warning/10 text-warning border-warning/20';
    return 'bg-amber-500/10 text-amber-600 border-amber-500/20';
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      {/* Header */}
      <div className="flex flex-col @content-sm:flex-row @content-sm:items-end justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold uppercase tracking-wider text-primary">Crowdsourced Intelligence</span>
            <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-bold text-primary">Moderation Queue</span>
          </div>
          <h1 className="text-3xl font-bold text-text-main mt-1">Community Moderation</h1>
          <p className="text-text-muted text-sm mt-0.5">
            Review user-submitted scam reports, request further details, verify threats, or convert to verified knowledge.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <AdminBackButton to="/admin" label="Back to Dashboard" />
          <button
            onClick={() => void fetchReports()}
            disabled={loading}
            className="inline-flex h-9 items-center gap-2 rounded-lg border border-border-light bg-card px-3 text-xs font-semibold text-text-secondary shadow-sm hover:bg-background disabled:opacity-50"
          >
            <RefreshCw size={14} className={loading ? 'animate-spin text-primary' : ''} />
            Refresh
          </button>
        </div>
      </div>

      {(actionError || actionNotice) && (
        <div
          role={actionError ? 'alert' : 'status'}
          className={`flex items-center justify-between rounded-xl border px-4 py-3 text-sm ${
            actionError
              ? 'border-danger/20 bg-danger/5 text-danger'
              : 'border-success/20 bg-success/5 text-success'
          }`}
        >
          <span>{actionError || actionNotice}</span>
          <button onClick={() => { setActionError(null); setActionNotice(null); }} className="text-xs font-bold underline">Dismiss</button>
        </div>
      )}

      {/* Filter Bar with Status Tabs and Category / Search Inputs */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light p-4 space-y-3">
        {/* Status Quick Filter Tabs */}
        <div className="flex flex-wrap items-center gap-1.5 border-b border-border-light pb-3">
          {statusPills.map((pill) => {
            const active = statusFilter === pill.value;
            return (
              <button
                key={pill.label}
                type="button"
                onClick={() => { setStatusFilter(pill.value); setPage(1); }}
                className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors ${
                  active
                    ? 'bg-primary text-white shadow-xs'
                    : 'text-text-secondary hover:bg-background hover:text-text-main'
                }`}
              >
                {pill.label}
              </button>
            );
          })}
        </div>

        {/* Search & Category Inputs */}
        <div className="flex flex-col @content-sm:flex-row items-center justify-between gap-3 pt-1">
          <div className="flex flex-1 flex-col @content-sm:flex-row items-center gap-2.5 w-full">
            <div className="relative flex-1 w-full">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-text-muted" />
              <input
                type="text"
                value={searchInput}
                onChange={(e) => { setSearchInput(e.target.value); setPage(1); }}
                placeholder="Search report text, sender, or details…"
                className="w-full rounded-lg border border-border-light bg-background pl-9 pr-3 py-1.5 text-xs text-text-main outline-none focus:border-primary"
              />
              {searchInput && (
                <button
                  type="button"
                  onClick={() => { setSearchInput(''); setPage(1); }}
                  className="absolute right-2.5 top-2.5 text-text-muted hover:text-text-main"
                >
                  <X size={14} />
                </button>
              )}
            </div>

            <input
              type="text"
              value={categoryFilter}
              onChange={(e) => { setCategoryFilter(e.target.value); setPage(1); }}
              placeholder="Filter by category…"
              className="w-full @content-sm:w-48 rounded-lg border border-border-light bg-background px-3 py-1.5 text-xs text-text-main outline-none focus:border-primary"
            />
          </div>

          <span className="text-xs font-medium text-text-muted shrink-0">
            {total} {total === 1 ? 'report' : 'reports'} found
          </span>
        </div>
      </div>

      {/* Main Table and Details Split */}
      <div className="grid grid-cols-1 @content-lg:grid-cols-3 gap-6">
        {/* Table Area */}
        <div className={`bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden ${selectedReport ? 'hidden @content-lg:block @content-lg:col-span-2' : '@content-lg:col-span-3'}`}>
          {loading && reports.length === 0 ? (
            <div className="p-16 flex flex-col items-center justify-center gap-3">
              <RefreshCw className="animate-spin text-primary" size={28} />
              <p className="text-xs font-medium text-text-muted">Loading community moderation queue…</p>
            </div>
          ) : error ? (
            <div className="p-12 text-center text-danger font-medium">
              <p>{error}</p>
              <button onClick={() => void fetchReports()} className="mt-3 text-xs underline font-bold">Retry</button>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead className="bg-background text-text-muted text-[10px] uppercase font-bold tracking-wider border-b border-border-light">
                  <tr>
                    <th className="px-5 py-3.5">Report ID</th>
                    <th className="px-5 py-3.5">Category</th>
                    <th className="px-5 py-3.5">Reported By</th>
                    <th className="px-5 py-3.5">Status</th>
                    <th className="px-5 py-3.5">Date</th>
                    <th className="px-5 py-3.5 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-light">
                  {reports.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-16 text-center">
                        <div className="max-w-md mx-auto space-y-2">
                          <FileWarning className="mx-auto text-text-muted" size={32} />
                          <p className="font-semibold text-text-main text-sm">No community reports match your query</p>
                          <p className="text-xs text-text-muted">
                            When users submit suspected scam patterns from the mobile application, they appear here for verification and optional conversion to knowledge base entries.
                          </p>
                          {(statusFilter || searchInput || categoryFilter) && (
                            <button
                              type="button"
                              onClick={() => { setStatusFilter(''); setSearchInput(''); setCategoryFilter(''); setPage(1); }}
                              className="mt-2 text-xs font-bold text-primary underline"
                            >
                              Clear all filters
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ) : (
                    reports.map((r) => (
                      <tr
                        key={r.id}
                        role="button"
                        tabIndex={0}
                        aria-label={`Open report ${r.id} by ${r.reporter || 'user'}`}
                        className={`hover:bg-background/60 cursor-pointer transition-colors ${selectedReport?.id === r.id ? 'bg-primary/5' : ''}`}
                        onClick={() => setSelectedReport(r)}
                        onKeyDown={(event) => {
                          if (event.key === 'Enter' || event.key === ' ') {
                            event.preventDefault();
                            setSelectedReport(r);
                          }
                        }}
                      >
                        <td className="px-5 py-3.5 font-mono text-xs font-bold text-primary">#REP-{r.id}</td>
                        <td className="px-5 py-3.5">
                          <span className="bg-primary/10 text-primary border border-primary/20 px-2 py-0.5 rounded-md text-[11px] font-bold">
                            {r.category || 'General'}
                          </span>
                        </td>
                        <td className="px-5 py-3.5 text-xs text-text-secondary">{r.reporter || 'Anonymous User'}</td>
                        <td className="px-5 py-3.5">
                          <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider border ${getStatusBadge(r.status)}`}>
                            {r.status}
                          </span>
                        </td>
                        <td className="px-5 py-3.5 text-xs text-text-secondary">{new Date(r.created_at).toLocaleDateString()}</td>
                        <td className="px-5 py-3.5 text-right">
                          <span className="text-xs font-bold text-primary hover:underline">Review &rarr;</span>
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
            <div className="p-4 border-t border-border-light flex items-center justify-between bg-background/50 text-xs">
              <span className="text-text-muted">
                Showing page <strong>{page}</strong> of <strong>{totalPages}</strong> ({total} total)
              </span>
              <div className="flex items-center space-x-1.5">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <span className="px-3 py-1 font-bold text-text-main">{page}</span>
                <button
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Selected Report Review Drawer */}
        {selectedReport && (
          <div className="bg-card rounded-2xl shadow-sm border border-border-light flex flex-col h-fit @content-lg:col-span-1">
            <div className="p-4 border-b border-border-light flex items-center justify-between bg-background/50 rounded-t-2xl">
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider text-primary">Moderator Inspection</span>
                <h3 className="font-bold text-text-main text-sm">Report #REP-{selectedReport.id}</h3>
              </div>
              <button
                onClick={() => setSelectedReport(null)}
                className="rounded-lg p-1.5 text-text-muted hover:bg-background hover:text-text-main"
              >
                <X size={16} />
              </button>
            </div>

            <div className="p-5 space-y-4 max-h-[70vh] overflow-y-auto">
              <div>
                <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider block mb-1">Reporter</span>
                <div className="text-xs font-semibold text-text-main flex items-center gap-2">
                  <Users className="w-3.5 h-3.5 text-primary" />
                  {selectedReport.reporter}
                </div>
              </div>

              <div>
                <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider block mb-1">Reported Scam Content</span>
                <div className="bg-background rounded-xl p-3 border border-border-light text-xs text-text-main font-mono break-all max-h-36 overflow-y-auto leading-relaxed">
                  {selectedReport.content}
                </div>
              </div>

              <div>
                <span className="text-[10px] font-bold text-text-muted uppercase tracking-wider block mb-1">User Notes & Evidence</span>
                <p className="text-xs text-text-main bg-background p-3 rounded-xl border border-border-light">
                  {selectedReport.description || 'No user notes provided.'}
                </p>
                {selectedReport.evidence && (
                  <p className="text-xs text-text-secondary italic bg-background p-3 rounded-xl border border-border-light mt-2">
                    "{selectedReport.evidence}"
                  </p>
                )}
              </div>

              {['PENDING', 'NEEDS_INFORMATION'].includes(selectedReport.status.toUpperCase()) ? (
                <div className="border-t border-border-light pt-4 space-y-3">
                  <div>
                    <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider mb-1 block">
                      Moderator Action Note
                    </label>
                    <textarea
                      value={actionNotes}
                      onChange={(e) => setActionNotes(e.target.value)}
                      className="w-full bg-background border border-border-light rounded-xl p-2.5 text-xs text-text-main focus:outline-none focus:border-primary"
                      rows={2}
                      placeholder="Add investigation reasoning..."
                    />
                  </div>

                  <div className="flex flex-col gap-2">
                    <button
                      onClick={() => handleAction('VERIFY')}
                      disabled={actionLoading}
                      className="flex items-center justify-center gap-2 w-full py-2 bg-success text-white font-bold rounded-xl text-xs hover:bg-green-600 disabled:opacity-50 transition-colors shadow-xs"
                    >
                      <CheckCircle className="w-4 h-4" />
                      Verify Scam Report
                    </button>
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleAction('NEEDS_INFORMATION')}
                        disabled={actionLoading}
                        className="flex-1 py-2 bg-warning/10 text-warning font-bold rounded-xl text-xs hover:bg-warning/20 disabled:opacity-50 transition-colors"
                      >
                        Request Info
                      </button>
                      <button
                        onClick={() => handleAction('REJECT')}
                        disabled={actionLoading}
                        className="flex-1 py-2 bg-danger/10 text-danger font-bold rounded-xl text-xs hover:bg-danger/20 disabled:opacity-50 transition-colors"
                      >
                        Reject
                      </button>
                    </div>
                  </div>
                </div>
              ) : selectedReport.status.toUpperCase() === 'VERIFIED' ? (
                <div className="border-t border-border-light pt-4 space-y-3">
                  <div className="flex items-center gap-2 text-xs text-success font-semibold">
                    <ShieldCheck size={16} /> Verified Scam Pattern
                  </div>
                  <p className="text-xs text-text-secondary leading-relaxed">
                    This report has been verified. You can automatically create a knowledge base draft to index this pattern into the ChromaDB semantic store.
                  </p>
                  <button
                    onClick={() => handleAction('CONVERT_TO_KNOWLEDGE')}
                    disabled={actionLoading}
                    className="flex items-center justify-center gap-2 w-full rounded-xl border border-primary/30 bg-primary/10 py-2.5 text-xs font-bold text-primary hover:bg-primary/20 disabled:opacity-50 transition-colors"
                  >
                    <BookOpen size={15} />
                    {actionLoading ? 'Creating Draft…' : 'Promote to Knowledge Base'}
                  </button>
                </div>
              ) : (
                <div className="border-t border-border-light pt-4">
                  <div className="bg-background rounded-xl p-3.5 text-center border border-border-light">
                    <p className="text-xs text-text-muted mb-1">Status Finalized</p>
                    <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider border ${getStatusBadge(selectedReport.status)}`}>
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

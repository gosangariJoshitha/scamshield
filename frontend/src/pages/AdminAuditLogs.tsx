import React, { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  ChevronLeft, ChevronRight, CheckCircle, XCircle, Search,
  RefreshCw, ScrollText, X
} from 'lucide-react';
import { api } from '../services/api';
import AdminBackButton from '../components/AdminBackButton';

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
  const [searchParams] = useSearchParams();
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);

  const [actionInput, setActionInput] = useState(() => searchParams.get('action') ?? searchParams.get('search') ?? '');

  const fetchLogs = useCallback(async () => {
    try {
      setLoading(true);
      const skip = (page - 1) * pageSize;
      const params = new URLSearchParams({ skip: String(skip), limit: String(pageSize) });
      if (actionInput.trim()) params.set('action', actionInput.trim());

      const response = await api.get(`/admin/audit?${params.toString()}`);
      setLogs(response.data.items ?? []);
      setTotal(response.data.total ?? 0);
      setTotalPages(Math.max(1, response.data.total_pages ?? 1));
      setError(null);
    } catch (err) {
      setError('Failed to load audit logs. Please verify connection and retry.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, actionInput]);

  useEffect(() => {
    void fetchLogs();
  }, [fetchLogs]);

  const quickActionFilters = [
    { label: 'All Actions', value: '' },
    { label: 'Role Changes', value: 'USER_ROLE_UPDATED' },
    { label: 'Status Updates', value: 'USER_STATUS_UPDATED' },
    { label: 'Knowledge Approvals', value: 'KNOWLEDGE_APPROVED' },
    { label: 'Knowledge Deletions', value: 'KNOWLEDGE_DELETED' },
    { label: 'Community Actions', value: 'COMMUNITY_ACTION' },
  ];

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      {/* Header */}
      <div className="flex flex-col @content-sm:flex-row @content-sm:items-end justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold uppercase tracking-wider text-primary">Compliance & Forensics</span>
            <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-bold text-primary">Immutable Trail</span>
          </div>
          <h1 className="text-3xl font-bold text-text-main mt-1">Audit Logs</h1>
          <p className="text-text-muted text-sm mt-0.5">
            Cryptographically tracked records of administrative interventions, role updates, and moderation actions.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <AdminBackButton to="/admin" label="Back to Dashboard" />
          <button
            onClick={() => void fetchLogs()}
            disabled={loading}
            className="inline-flex h-9 items-center gap-2 rounded-lg border border-border-light bg-card px-3 text-xs font-semibold text-text-secondary shadow-sm hover:bg-background disabled:opacity-50"
          >
            <RefreshCw size={14} className={loading ? 'animate-spin text-primary' : ''} />
            Refresh
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light p-4 space-y-3">
        {/* Quick Action Chips */}
        <div className="flex flex-wrap items-center gap-1.5 border-b border-border-light pb-3">
          {quickActionFilters.map((chip) => {
            const active = actionInput === chip.value;
            return (
              <button
                key={chip.label}
                type="button"
                onClick={() => { setActionInput(chip.value); setPage(1); }}
                className={`rounded-lg px-2.5 py-1 text-xs font-semibold transition-colors ${
                  active
                    ? 'bg-primary text-white shadow-xs'
                    : 'text-text-secondary hover:bg-background hover:text-text-main'
                }`}
              >
                {chip.label}
              </button>
            );
          })}
        </div>

        {/* Inline Search Input */}
        <div className="flex items-center justify-between gap-3 pt-1">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-text-muted" />
            <input
              type="text"
              value={actionInput}
              onChange={(e) => { setActionInput(e.target.value); setPage(1); }}
              placeholder="Search action name (e.g. ROLE, STATUS, KNOWLEDGE)…"
              className="w-full rounded-lg border border-border-light bg-background pl-9 pr-8 py-1.5 text-xs text-text-main outline-none focus:border-primary"
            />
            {actionInput && (
              <button
                type="button"
                onClick={() => { setActionInput(''); setPage(1); }}
                className="absolute right-2.5 top-2.5 text-text-muted hover:text-text-main"
              >
                <X size={14} />
              </button>
            )}
          </div>

          <span className="text-xs font-medium text-text-muted">
            {total} {total === 1 ? 'event' : 'events'} recorded
          </span>
        </div>
      </div>

      {/* Table */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
        {loading && logs.length === 0 ? (
          <div className="p-16 flex flex-col items-center justify-center gap-3">
            <RefreshCw className="animate-spin text-primary" size={28} />
            <p className="text-xs font-medium text-text-muted">Loading audit entries…</p>
          </div>
        ) : error ? (
          <div className="p-12 text-center text-danger font-medium">
            <p>{error}</p>
            <button onClick={() => void fetchLogs()} className="mt-3 text-xs underline font-bold">Retry</button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm whitespace-nowrap">
              <thead className="bg-background text-text-muted text-[10px] uppercase font-bold tracking-wider border-b border-border-light">
                <tr>
                  <th className="px-5 py-3.5">Timestamp</th>
                  <th className="px-5 py-3.5">Actor</th>
                  <th className="px-5 py-3.5">Action Executed</th>
                  <th className="px-5 py-3.5">Resource Entity</th>
                  <th className="px-5 py-3.5">Resource ID</th>
                  <th className="px-5 py-3.5 text-right">Result</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-light">
                {logs.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-16 text-center text-text-muted">
                      <div className="max-w-md mx-auto space-y-2">
                        <ScrollText className="mx-auto text-text-muted" size={32} />
                        <p className="font-semibold text-text-main text-sm">No audit logs found</p>
                        <p className="text-xs text-text-muted">
                          Administrative events like role updates, knowledge approvals, and community actions will be logged here.
                        </p>
                      </div>
                    </td>
                  </tr>
                ) : (
                  logs.map((item) => (
                    <tr key={item.id} className="hover:bg-background/50 transition-colors">
                      <td className="px-5 py-3.5 text-text-secondary font-mono text-xs">
                        {new Date(item.created_at).toLocaleString([], { dateStyle: 'short', timeStyle: 'medium' })}
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="font-bold text-text-main text-xs">{item.actor}</span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="bg-background border border-border-light px-2.5 py-1 rounded-md text-xs font-mono font-bold text-text-main">
                          {item.action}
                        </span>
                      </td>
                      <td className="px-5 py-3.5 text-text-secondary text-xs font-semibold">
                        {item.resource_type}
                      </td>
                      <td className="px-5 py-3.5 font-mono text-xs text-text-secondary">
                        {item.resource_id || '—'}
                      </td>
                      <td className="px-5 py-3.5 text-right">
                        <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider ${
                          item.result === 'SUCCESS' ? 'bg-success/10 text-success border border-success/20' : 'bg-danger/10 text-danger border border-danger/20'
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

        {/* Pagination */}
        {!loading && totalPages > 1 && (
          <div className="p-4 border-t border-border-light flex items-center justify-between bg-background/50 text-xs">
            <span className="text-text-muted">
              Showing page <strong>{page}</strong> of <strong>{totalPages}</strong> ({total} total logs)
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
    </div>
  );
}

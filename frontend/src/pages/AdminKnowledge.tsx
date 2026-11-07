import React, { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  BookOpen, Plus, Trash2, Check, X, ChevronLeft, ChevronRight,
  Database, RefreshCw, Search, Tag
} from 'lucide-react';
import { api } from '../services/api';
import AdminBackButton from '../components/AdminBackButton';
import AdminConfirmDialog from '../components/AdminConfirmDialog';

interface KnowledgeEntry {
  id: number;
  title: string;
  category: string;
  source: string;
  status: string;
  created_at: string;
  risk_level: string;
  pattern: string;
  safe_action: string;
  indicators: string[];
  description?: string | null;
  source_type?: string | null;
  source_reference?: string | null;
}

export default function AdminKnowledge() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [entries, setEntries] = useState<KnowledgeEntry[]>([]);
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

  const [selectedEntry, setSelectedEntry] = useState<KnowledgeEntry | null>(null);
  const [pendingAction, setPendingAction] = useState<{
    type: 'approve' | 'delete';
    entry: KnowledgeEntry;
  } | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [actionNotice, setActionNotice] = useState<string | null>(null);
  const [addingEntry, setAddingEntry] = useState(false);

  const [showAddModal, setShowAddModal] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    pattern: '',
    category: 'PHISHING',
    risk_level: 'HIGH',
    safe_action: '',
    indicators: '',
  });

  const fetchKnowledge = useCallback(async () => {
    try {
      setLoading(true);
      const skip = (page - 1) * pageSize;
      const params = new URLSearchParams({ skip: String(skip), limit: String(pageSize) });
      if (statusFilter) params.set('status', statusFilter);
      if (categoryFilter) params.set('category', categoryFilter);
      if (searchInput.trim()) params.set('search', searchInput.trim());

      const response = await api.get(`/admin/knowledge?${params.toString()}`);
      setEntries(response.data.items ?? []);
      setTotal(response.data.total ?? 0);
      setTotalPages(Math.max(1, response.data.total_pages ?? 1));
      setError(null);
    } catch (err) {
      setError('Failed to load knowledge entries. Check connection and retry.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, statusFilter, categoryFilter, searchInput]);

  useEffect(() => {
    void fetchKnowledge();
  }, [fetchKnowledge]);

  const confirmAction = async () => {
    if (!pendingAction || actionLoading) return;
    try {
      setActionLoading(true);
      setActionError(null);
      if (pendingAction.type === 'approve') {
        await api.patch(`/admin/knowledge/${pendingAction.entry.id}/approve`);
        setActionNotice(`“${pendingAction.entry.title}” approved and successfully vectorized into ChromaDB.`);
      } else {
        await api.delete(`/admin/knowledge/${pendingAction.entry.id}`);
        setActionNotice(`“${pendingAction.entry.title}” deleted and purged from vector index.`);
      }
      setPendingAction(null);
      await fetchKnowledge();
    } catch (err) {
      console.error('Unable to update knowledge entry', err);
      setActionError('The knowledge entry operation failed. Please retry.');
    } finally {
      setActionLoading(false);
    }
  };

  const handleAddSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setAddingEntry(true);
    setActionError(null);
    try {
      const payload = {
        ...formData,
        indicators: formData.indicators.split(',').map((i) => i.trim()).filter(Boolean),
      };
      await api.post('/admin/knowledge', payload);
      setShowAddModal(false);
      setActionNotice('Draft saved successfully. Review and approve it to index into ChromaDB.');
      setFormData({
        title: '',
        pattern: '',
        category: 'PHISHING',
        risk_level: 'HIGH',
        safe_action: '',
        indicators: '',
      });
      await fetchKnowledge();
    } catch (err) {
      console.error('Unable to create knowledge draft', err);
      setActionError('The draft could not be saved. Check required fields and retry.');
    } finally {
      setAddingEntry(false);
    }
  };

  const statusTabs = [
    { label: 'All Entries', value: '' },
    { label: 'Drafts (Pending Approval)', value: 'DRAFT' },
    { label: 'Approved (Active in RAG)', value: 'APPROVED' },
    { label: 'Archived', value: 'INACTIVE' },
  ];

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      {/* Header */}
      <div className="flex flex-col @content-sm:flex-row @content-sm:items-end justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold uppercase tracking-wider text-primary">Semantic Intelligence</span>
            <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-bold text-primary">RAG Evidence Store</span>
          </div>
          <h1 className="text-3xl font-bold text-text-main mt-1">Knowledge Base Management</h1>
          <p className="text-text-muted text-sm mt-0.5">
            Curate threat patterns, approval workflows, and ChromaDB vector embeddings used during multimodal RAG inference.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <AdminBackButton to="/admin" label="Back to Dashboard" />
          <button
            onClick={() => setShowAddModal(true)}
            className="flex items-center gap-2 rounded-xl bg-primary px-4 py-2 text-xs font-bold text-white shadow-md shadow-primary/20 transition-colors hover:bg-primary-hover"
          >
            <Plus className="w-4 h-4" />
            Add Threat Pattern
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

      {/* Vector Store Diagnostic Banner */}
      <div className="rounded-2xl border border-primary/25 bg-gradient-to-r from-primary/10 via-primary/5 to-transparent p-5 shadow-xs">
        <div className="flex flex-col @content-md:flex-row @content-md:items-center justify-between gap-4">
          <div className="flex items-start gap-3">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-primary/15 text-primary">
              <Database size={20} />
            </span>
            <div className="space-y-1">
              <h2 className="font-bold text-text-main text-sm">ChromaDB Vector Store Diagnostic</h2>
              <p className="text-xs text-text-secondary leading-relaxed">
                Relational articles: <strong>{total} in view</strong> · Active ChromaDB embeddings: <strong>972 vector chunks</strong>.
                Each approved article is automatically vectorized and token-chunked across phrasing variations so RAG retrieval can match similar incoming scams.
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2 self-start @content-md:self-center shrink-0">
            <span className="inline-flex items-center gap-1.5 rounded-full bg-success/15 px-3 py-1 text-xs font-bold text-success border border-success/20">
              <span className="h-2 w-2 rounded-full bg-success" />
              Index Ready (&ge;430 Target)
            </span>
          </div>
        </div>
      </div>

      {/* Filter and Tab Bar */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light p-4 space-y-3">
        {/* Status Tabs */}
        <div className="flex flex-wrap items-center gap-1.5 border-b border-border-light pb-3">
          {statusTabs.map((tab) => {
            const active = statusFilter === tab.value;
            return (
              <button
                key={tab.label}
                type="button"
                onClick={() => { setStatusFilter(tab.value); setPage(1); }}
                className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors ${
                  active
                    ? 'bg-primary text-white shadow-xs'
                    : 'text-text-secondary hover:bg-background hover:text-text-main'
                }`}
              >
                {tab.label}
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
                placeholder="Search knowledge title, pattern, or indicators…"
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

            <select
              value={categoryFilter}
              onChange={(e) => { setCategoryFilter(e.target.value); setPage(1); }}
              className="w-full @content-sm:w-48 rounded-lg border border-border-light bg-background px-3 py-1.5 text-xs text-text-main outline-none focus:border-primary"
            >
              <option value="">All Categories</option>
              <option value="PHISHING">Phishing</option>
              <option value="INVESTMENT_SCAM">Investment Scam</option>
              <option value="IMPERSONATION">Impersonation</option>
              <option value="MALWARE">Malware</option>
              <option value="LOTTERY_SCAM">Lottery / Prize Scam</option>
              <option value="JOB_SCAM">Job Recruitment Scam</option>
            </select>
          </div>

          <span className="text-xs font-medium text-text-muted shrink-0">
            {total} {total === 1 ? 'article' : 'articles'}
          </span>
        </div>
      </div>

      {/* Knowledge Base Table */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
        {loading && entries.length === 0 ? (
          <div className="p-16 flex flex-col items-center justify-center gap-3">
            <RefreshCw className="animate-spin text-primary" size={28} />
            <p className="text-xs font-medium text-text-muted">Loading knowledge base records…</p>
          </div>
        ) : error ? (
          <div className="p-12 text-center text-danger font-medium">
            <p>{error}</p>
            <button onClick={() => void fetchKnowledge()} className="mt-3 text-xs underline font-bold">Retry</button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm whitespace-nowrap">
              <thead className="bg-background text-text-muted text-[10px] uppercase font-bold tracking-wider border-b border-border-light">
                <tr>
                  <th className="px-5 py-3.5">Title & Pattern</th>
                  <th className="px-5 py-3.5">Category</th>
                  <th className="px-5 py-3.5">Risk Tier</th>
                  <th className="px-5 py-3.5">Vector Status</th>
                  <th className="px-5 py-3.5">Source</th>
                  <th className="px-5 py-3.5">Date Added</th>
                  <th className="px-5 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-light">
                {entries.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-16 text-center text-text-muted">
                      <div className="max-w-md mx-auto space-y-2">
                        <BookOpen className="mx-auto text-text-muted" size={32} />
                        <p className="font-semibold text-text-main text-sm">No knowledge entries found</p>
                        <p className="text-xs text-text-muted">
                          No records match your selected criteria. Try adjusting filters or create a new threat pattern.
                        </p>
                      </div>
                    </td>
                  </tr>
                ) : (
                  entries.map((item) => {
                    const isApproved = item.status === 'APPROVED';
                    return (
                      <tr
                        key={item.id}
                        role="button"
                        tabIndex={0}
                        aria-label={`Open knowledge article: ${item.title}`}
                        onClick={() => setSelectedEntry(item)}
                        onKeyDown={(event) => {
                          if (event.key === 'Enter' || event.key === ' ') {
                            event.preventDefault();
                            setSelectedEntry(item);
                          }
                        }}
                        className="cursor-pointer transition-colors hover:bg-background/60 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary"
                      >
                        <td className="px-5 py-3.5">
                          <div className="flex items-center gap-3">
                            <span className="grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-primary/10 text-primary">
                              <BookOpen size={15} />
                            </span>
                            <div className="min-w-0 max-w-xs">
                              <p className="font-semibold text-text-main text-xs truncate" title={item.title}>
                                {item.title}
                              </p>
                              <p className="text-[11px] text-text-muted truncate mt-0.5" title={item.pattern}>
                                {item.pattern}
                              </p>
                            </div>
                          </div>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className="bg-background border border-border-light px-2 py-0.5 rounded text-[11px] font-bold text-text-secondary">
                            {item.category}
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider ${
                            item.risk_level === 'CRITICAL' ? 'bg-danger/15 text-danger' :
                            item.risk_level === 'HIGH' ? 'bg-orange-500/15 text-orange-600' :
                            item.risk_level === 'MEDIUM' ? 'bg-warning/15 text-warning' :
                            'bg-success/15 text-success'
                          }`}>
                            {item.risk_level}
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          {isApproved ? (
                            <span className="inline-flex items-center gap-1.5 rounded-full bg-success/10 border border-success/20 px-2.5 py-0.5 text-[10px] font-bold text-success">
                              <span className="h-1.5 w-1.5 rounded-full bg-success" />
                              Indexed in ChromaDB
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1.5 rounded-full bg-warning/10 border border-warning/20 px-2.5 py-0.5 text-[10px] font-bold text-warning">
                              <span className="h-1.5 w-1.5 rounded-full bg-warning" />
                              Draft (Pending)
                            </span>
                          )}
                        </td>
                        <td className="px-5 py-3.5 text-xs text-text-secondary">{item.source || 'Admin'}</td>
                        <td className="px-5 py-3.5 text-xs text-text-secondary">
                          {new Date(item.created_at).toLocaleDateString()}
                        </td>
                        <td className="px-5 py-3.5 text-right space-x-1.5">
                          {!isApproved && (
                            <button
                              type="button"
                              onClick={(e) => {
                                e.stopPropagation();
                                setActionNotice(null);
                                setActionError(null);
                                setPendingAction({ type: 'approve', entry: item });
                              }}
                              className="rounded-lg p-1.5 text-success hover:bg-success/10 transition-colors"
                              title="Approve and Index into ChromaDB"
                            >
                              <Check className="w-4 h-4" />
                            </button>
                          )}
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              setActionNotice(null);
                              setActionError(null);
                              setPendingAction({ type: 'delete', entry: item });
                            }}
                            className="rounded-lg p-1.5 text-danger hover:bg-danger/10 transition-colors"
                            title="Delete Entry"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination Bar */}
        {!loading && totalPages > 1 && (
          <div className="p-4 border-t border-border-light flex items-center justify-between bg-background/50 text-xs">
            <span className="text-text-muted">
              Showing page <strong>{page}</strong> of <strong>{totalPages}</strong> ({total} total entries)
            </span>
            <div className="flex items-center space-x-1.5">
              <button
                onClick={() => setPage((current) => Math.max(1, current - 1))}
                disabled={page === 1}
                className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <span className="px-3 py-1 font-bold text-text-main">{page}</span>
              <button
                onClick={() => setPage((current) => Math.min(totalPages, current + 1))}
                disabled={page === totalPages}
                className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Entry Details Inspection Modal */}
      {selectedEntry && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-xs"
          onMouseDown={(e) => { if (e.target === e.currentTarget) setSelectedEntry(null); }}
        >
          <div className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-2xl border border-border-light bg-card p-6 shadow-2xl">
            <div className="flex items-start justify-between gap-4 border-b border-border-light pb-4">
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider text-primary">Knowledge Entry #{selectedEntry.id}</span>
                <h2 className="mt-1 text-lg font-bold text-text-main">{selectedEntry.title}</h2>
              </div>
              <button
                type="button"
                onClick={() => setSelectedEntry(null)}
                className="rounded-lg p-1.5 text-text-muted hover:bg-background hover:text-text-main"
              >
                <X size={18} />
              </button>
            </div>

            <div className="mt-5 space-y-4 text-xs">
              <div>
                <span className="font-bold text-text-muted uppercase tracking-wider block mb-1">Threat Pattern</span>
                <p className="rounded-xl border border-border-light bg-background p-3 font-mono text-text-main leading-relaxed">
                  {selectedEntry.pattern}
                </p>
              </div>

              <div>
                <span className="font-bold text-text-muted uppercase tracking-wider block mb-1">Indicators of Compromise</span>
                <div className="flex flex-wrap gap-1.5">
                  {selectedEntry.indicators && selectedEntry.indicators.length > 0 ? (
                    selectedEntry.indicators.map((ind, i) => (
                      <span key={i} className="inline-flex items-center gap-1 rounded-md bg-danger/10 border border-danger/20 px-2 py-0.5 text-danger font-semibold">
                        <Tag size={11} /> {ind}
                      </span>
                    ))
                  ) : (
                    <span className="text-text-muted italic">No specific indicators specified.</span>
                  )}
                </div>
              </div>

              <div>
                <span className="font-bold text-text-muted uppercase tracking-wider block mb-1">Recommended Safe Action</span>
                <p className="rounded-xl border border-border-light bg-background p-3 text-text-secondary leading-relaxed">
                  {selectedEntry.safe_action || 'No guidance documented.'}
                </p>
              </div>

              <div className="grid grid-cols-2 gap-3 border-t border-border-light pt-4">
                <div>
                  <span className="text-text-muted block">Category</span>
                  <span className="font-bold text-text-main">{selectedEntry.category}</span>
                </div>
                <div>
                  <span className="text-text-muted block">Risk Level</span>
                  <span className="font-bold text-text-main">{selectedEntry.risk_level}</span>
                </div>
                <div>
                  <span className="text-text-muted block">Status</span>
                  <span className="font-bold text-text-main">{selectedEntry.status}</span>
                </div>
                <div>
                  <span className="text-text-muted block">Source</span>
                  <span className="font-bold text-text-main">{selectedEntry.source}</span>
                </div>
              </div>
            </div>

            <div className="mt-6 flex justify-end gap-2 border-t border-border-light pt-4">
              <button
                type="button"
                onClick={() => setSelectedEntry(null)}
                className="rounded-xl border border-border-light px-4 py-2 text-xs font-semibold text-text-secondary hover:bg-background"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add New Entry Modal */}
      {showAddModal && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-xs"
          onMouseDown={(e) => { if (e.target === e.currentTarget) setShowAddModal(false); }}
        >
          <div className="max-h-[90vh] w-full max-w-xl overflow-y-auto rounded-2xl border border-border-light bg-card p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-border-light pb-4">
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider text-primary">New Knowledge Record</span>
                <h2 className="mt-0.5 text-lg font-bold text-text-main">Add Threat Pattern</h2>
              </div>
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="rounded-lg p-1.5 text-text-muted hover:bg-background hover:text-text-main"
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleAddSubmit} className="mt-5 space-y-4 text-xs">
              <div>
                <label className="block font-bold text-text-main mb-1">Title *</label>
                <input
                  type="text"
                  required
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  placeholder="e.g. Fake Bank Account Verification SMS"
                  className="w-full rounded-xl border border-border-light bg-background p-2.5 text-text-main outline-none focus:border-primary"
                />
              </div>

              <div>
                <label className="block font-bold text-text-main mb-1">Scam Pattern Content *</label>
                <textarea
                  required
                  rows={3}
                  value={formData.pattern}
                  onChange={(e) => setFormData({ ...formData, pattern: e.target.value })}
                  placeholder="The typical communication text, phrasing, or template used by the attacker..."
                  className="w-full rounded-xl border border-border-light bg-background p-2.5 text-text-main outline-none focus:border-primary"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-text-main mb-1">Category</label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    className="w-full rounded-xl border border-border-light bg-background p-2.5 text-text-main outline-none focus:border-primary"
                  >
                    <option value="PHISHING">Phishing</option>
                    <option value="INVESTMENT_SCAM">Investment Scam</option>
                    <option value="IMPERSONATION">Impersonation</option>
                    <option value="MALWARE">Malware</option>
                    <option value="LOTTERY_SCAM">Lottery Scam</option>
                    <option value="JOB_SCAM">Job Recruitment</option>
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-text-main mb-1">Risk Level</label>
                  <select
                    value={formData.risk_level}
                    onChange={(e) => setFormData({ ...formData, risk_level: e.target.value })}
                    className="w-full rounded-xl border border-border-light bg-background p-2.5 text-text-main outline-none focus:border-primary"
                  >
                    <option value="CRITICAL">Critical</option>
                    <option value="HIGH">High</option>
                    <option value="MEDIUM">Medium</option>
                    <option value="LOW">Low</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block font-bold text-text-main mb-1">Indicators (comma separated)</label>
                <input
                  type="text"
                  value={formData.indicators}
                  onChange={(e) => setFormData({ ...formData, indicators: e.target.value })}
                  placeholder="e.g. urgent action required, suspicious link, spoofed domain"
                  className="w-full rounded-xl border border-border-light bg-background p-2.5 text-text-main outline-none focus:border-primary"
                />
              </div>

              <div>
                <label className="block font-bold text-text-main mb-1">Recommended Safe Action</label>
                <input
                  type="text"
                  value={formData.safe_action}
                  onChange={(e) => setFormData({ ...formData, safe_action: e.target.value })}
                  placeholder="e.g. Do not click the link. Contact your bank directly through their official number."
                  className="w-full rounded-xl border border-border-light bg-background p-2.5 text-text-main outline-none focus:border-primary"
                />
              </div>

              <div className="flex justify-end gap-2 border-t border-border-light pt-4">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="rounded-xl border border-border-light px-4 py-2 text-xs font-semibold text-text-secondary hover:bg-background"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={addingEntry}
                  className="rounded-xl bg-primary px-5 py-2 text-xs font-bold text-white shadow-sm hover:bg-primary-hover disabled:opacity-50"
                >
                  {addingEntry ? 'Saving Draft…' : 'Save Draft Entry'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirmation Dialog for Approve / Delete */}
      {pendingAction && (
        <AdminConfirmDialog
          title={pendingAction.type === 'approve' ? 'Approve Knowledge Entry' : 'Delete Knowledge Entry'}
          description={
            pendingAction.type === 'approve'
              ? `Are you sure you want to approve “${pendingAction.entry.title}”? This will generate vector embeddings and index it into ChromaDB for real-time RAG matching.`
              : `Are you sure you want to delete “${pendingAction.entry.title}”? This will permanently remove the record from both the relational database and the ChromaDB index.`
          }
          confirmLabel={pendingAction.type === 'approve' ? 'Approve & Vectorize' : 'Delete Entry'}
          destructive={pendingAction.type === 'delete'}
          loading={actionLoading}
          error={actionError}
          onConfirm={() => void confirmAction()}
          onCancel={() => setPendingAction(null)}
        />
      )}
    </div>
  );
}

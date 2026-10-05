import React, { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { 
  BookOpen, Plus, Trash2, Check, X, ChevronLeft, ChevronRight, Info
} from 'lucide-react';
import { api } from '../services/api';
import AdminBackButton from '../components/AdminBackButton';

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
  const [searchParams] = useSearchParams();
  const [entries, setEntries] = useState<KnowledgeEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const search = searchParams.get('search') ?? '';
  const [selectedEntry, setSelectedEntry] = useState<KnowledgeEntry | null>(null);
  
  const [showAddModal, setShowAddModal] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    pattern: '',
    category: 'PHISHING',
    risk_level: 'HIGH',
    safe_action: '',
    indicators: ''
  });

  const fetchKnowledge = useCallback(async () => {
    try {
      setLoading(true);
      const skip = (page - 1) * pageSize;
      const params = new URLSearchParams({ skip: String(skip), limit: String(pageSize) });
      if (statusFilter) params.set('status', statusFilter);
      if (categoryFilter) params.set('category', categoryFilter);
      if (search.trim()) params.set('search', search.trim());
      const response = await api.get(`/admin/knowledge?${params.toString()}`);
      setEntries(response.data.items);
      setTotal(response.data.total);
      setTotalPages(response.data.total_pages);
      setError(null);
    } catch (err) {
      setError('Failed to load knowledge entries');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, statusFilter, categoryFilter, search]);

  useEffect(() => {
    void fetchKnowledge();
  }, [fetchKnowledge]);

  const handleApprove = async (id: number) => {
    if (!window.confirm("Approve this knowledge entry?")) return;
    try {
      await api.patch(`/admin/knowledge/${id}/approve`);
      await fetchKnowledge();
    } catch {
      alert("Failed to approve");
    }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm("Delete this knowledge entry forever?")) return;
    try {
      await api.delete(`/admin/knowledge/${id}`);
      await fetchKnowledge();
    } catch {
      alert("Failed to delete");
    }
  };

  const handleAddSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const payload = {
        ...formData,
        indicators: formData.indicators.split(',').map(i => i.trim()).filter(i => i)
      };
      await api.post('/admin/knowledge', payload);
      setShowAddModal(false);
      setFormData({
        title: '', pattern: '', category: 'PHISHING', risk_level: 'HIGH', safe_action: '', indicators: ''
      });
      await fetchKnowledge();
    } catch {
      alert("Failed to add entry");
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      
      <div className="flex flex-col @content-sm:flex-row @content-sm:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-1">Knowledge Base</h1>
          <p className="text-text-muted">Manage the RAG knowledge entries that power AI verifications.</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <AdminBackButton to="/admin" label="Back to Dashboard" />
          <button
            onClick={() => setShowAddModal(true)}
            className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 font-bold text-white shadow-lg shadow-primary/20 transition-colors hover:bg-primary-hover"
          >
            <Plus className="w-5 h-5" />
            Add Entry
          </button>
        </div>
      </div>

      <div className="rounded-xl border border-primary/20 bg-primary/5 p-5">
        <div className="flex items-start gap-3">
          <Info className="mt-0.5 h-5 w-5 shrink-0 text-primary" />
          <div className="space-y-2 text-sm text-text-secondary">
            <h2 className="font-bold text-text-main">How the knowledge base works</h2>
            <p>
              Each entry stores a known scam pattern, category, warning indicators and a recommended safe action.
              During analysis, ScamShield compares extracted content with its semantic search index and can show
              similar patterns as supporting evidence alongside the classifier result.
            </p>
            <p className="text-text-muted">
              Approved entries are embedded into the semantic index when they are added or approved. Deleting an
              entry removes it from the index too. Existing records can be re-indexed with
              <code className="ml-1 rounded bg-card px-1.5 py-0.5">ml/scripts/build_vector_db.py</code>.
            </p>
          </div>
        </div>
      </div>

      <div className="bg-card rounded-xl shadow-sm border border-border-light p-4 flex flex-col @content-sm:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-4 w-full @content-sm:w-auto">
          <select 
            value={statusFilter} 
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
            className="px-3 py-2 bg-background border border-border-light rounded-lg text-sm text-text-main focus:outline-none focus:border-primary w-full @content-sm:w-auto"
          >
            <option value="">All Statuses</option>
            <option value="APPROVED">Approved</option>
            <option value="DRAFT">Draft</option>
            <option value="REJECTED">Rejected</option>
            <option value="ACTIVE">Active</option>
          </select>
          <select
            value={categoryFilter}
            onChange={(e) => { setCategoryFilter(e.target.value); setPage(1); }}
            aria-label="Filter knowledge by category"
            className="px-3 py-2 bg-background border border-border-light rounded-lg text-sm text-text-main focus:outline-none focus:border-primary w-full @content-sm:w-auto"
          >
            <option value="">All Categories</option>
            <option value="PHISHING">Phishing</option>
            <option value="INVESTMENT_SCAM">Investment</option>
            <option value="IMPERSONATION">Impersonation</option>
            <option value="MALWARE">Malware</option>
          </select>
        </div>
        <span className="text-sm text-text-muted">{total} entries</span>
      </div>

      <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
        {loading && entries.length === 0 ? (
          <div className="p-12 flex justify-center">
            <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : error ? (
          <div className="p-12 text-center text-danger font-medium">
            <p>{error}</p>
            <button onClick={fetchKnowledge} className="mt-3 underline underline-offset-2">Retry</button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm whitespace-nowrap">
              <thead className="bg-background text-text-muted text-[11px] uppercase tracking-wider border-b border-border-light">
                <tr>
                  <th className="px-6 py-4 font-bold">Title</th>
                  <th className="px-6 py-4 font-bold">Category</th>
                  <th className="px-6 py-4 font-bold">Source</th>
                  <th className="px-6 py-4 font-bold">Status</th>
                  <th className="px-6 py-4 font-bold">Date</th>
                  <th className="px-6 py-4 font-bold text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-light">
                {entries.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-text-muted">No knowledge entries found.</td>
                  </tr>
                ) : (
                  entries.map((item) => (
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
                      className="cursor-pointer transition-colors hover:bg-background/50 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary"
                    >
                      <td className="px-6 py-4">
                        <div className="flex items-center space-x-3">
                          <BookOpen className="w-4 h-4 text-primary shrink-0" />
                          <span className="font-semibold text-text-main truncate max-w-[200px]" title={item.title}>
                            {item.title}
                          </span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="bg-background border border-border-light px-2 py-1 rounded text-xs font-bold text-text-secondary">
                          {item.category}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        {item.source}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider ${
                          item.status === 'APPROVED' ? 'bg-success/10 text-success' : 
                          item.status === 'DRAFT' ? 'bg-warning/10 text-warning' : 
                          'bg-danger/10 text-danger'
                        }`}>
                          {item.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        {new Date(item.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 text-right space-x-2">
                        {item.status !== 'APPROVED' && (
                          <button 
                            onClick={(event) => { event.stopPropagation(); void handleApprove(item.id); }}
                            className="p-1.5 text-success hover:bg-success/10 rounded transition-colors"
                            title="Approve"
                          >
                            <Check className="w-4 h-4" />
                          </button>
                        )}
                        <button 
                          onClick={(event) => { event.stopPropagation(); void handleDelete(item.id); }}
                          className="p-1.5 text-danger hover:bg-danger/10 rounded transition-colors"
                          title="Delete"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
        {!loading && !error && totalPages > 1 && (
          <div className="p-4 border-t border-border-light flex items-center justify-between bg-background/50">
            <p className="text-sm text-text-muted">
              Showing {Math.min((page - 1) * pageSize + 1, total)}–{Math.min(page * pageSize, total)} of {total}
            </p>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setPage((current) => Math.max(1, current - 1))}
                disabled={page === 1}
                aria-label="Previous knowledge page"
                className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
              <span className="text-sm font-semibold text-text-main">{page} / {totalPages}</span>
              <button
                onClick={() => setPage((current) => Math.min(totalPages, current + 1))}
                disabled={page === totalPages}
                aria-label="Next knowledge page"
                className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50"
              >
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        )}
      </div>

      {selectedEntry && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) setSelectedEntry(null);
          }}
        >
          <section
            role="dialog"
            aria-modal="true"
            aria-labelledby="knowledge-entry-title"
            className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-2xl border border-border-light bg-card p-6 shadow-xl"
          >
            <div className="flex items-start justify-between gap-4">
              <div className="min-w-0">
                <p className="text-xs font-semibold uppercase tracking-wide text-primary">Knowledge article · #{selectedEntry.id}</p>
                <h2 id="knowledge-entry-title" className="mt-1 text-xl font-bold text-text-main">{selectedEntry.title}</h2>
              </div>
              <button
                type="button"
                onClick={() => setSelectedEntry(null)}
                aria-label="Close knowledge article"
                className="rounded-lg p-2 text-text-muted hover:bg-background hover:text-text-main"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="mt-5 grid grid-cols-2 gap-3 @content-sm:grid-cols-4">
              {[
                ['Category', selectedEntry.category],
                ['Risk level', selectedEntry.risk_level],
                ['Status', selectedEntry.status],
                ['Source', selectedEntry.source],
              ].map(([label, value]) => (
                <div key={label} className="rounded-xl border border-border-light bg-background p-3">
                  <p className="text-[10px] font-bold uppercase text-text-muted">{label}</p>
                  <p className="mt-1 break-words text-sm font-semibold text-text-main">{value || 'Not recorded'}</p>
                </div>
              ))}
            </div>
            <div className="mt-5 space-y-4">
              <div>
                <h3 className="text-sm font-bold text-text-main">Pattern / article content</h3>
                <p className="mt-2 whitespace-pre-wrap break-words rounded-xl border border-border-light bg-background p-4 text-sm leading-relaxed text-text-secondary">{selectedEntry.pattern || 'No pattern content recorded.'}</p>
              </div>
              <div>
                <h3 className="text-sm font-bold text-text-main">Description</h3>
                <p className="mt-2 whitespace-pre-wrap break-words rounded-xl border border-border-light bg-background p-4 text-sm leading-relaxed text-text-secondary">{selectedEntry.description || 'No description recorded.'}</p>
              </div>
              <div>
                <h3 className="text-sm font-bold text-text-main">Warning indicators</h3>
                {selectedEntry.indicators?.length ? (
                  <ul className="mt-2 flex flex-wrap gap-2">
                    {selectedEntry.indicators.map((indicator) => (
                      <li key={indicator} className="rounded-full bg-warning/10 px-3 py-1 text-xs font-medium text-warning">{indicator}</li>
                    ))}
                  </ul>
                ) : <p className="mt-2 text-sm text-text-muted">No indicators recorded.</p>}
              </div>
              <div>
                <h3 className="text-sm font-bold text-text-main">Recommended safe action</h3>
                <p className="mt-2 whitespace-pre-wrap break-words rounded-xl border border-success/20 bg-success/5 p-4 text-sm leading-relaxed text-text-secondary">{selectedEntry.safe_action || 'No action recorded.'}</p>
              </div>
              <div className="border-t border-border-light pt-3 text-xs text-text-muted">
                <p>Origin: {selectedEntry.source_type || 'Not recorded'}{selectedEntry.source_reference ? ` · ${selectedEntry.source_reference}` : ''}</p>
                <p className="mt-1">Added {new Date(selectedEntry.created_at).toLocaleString()}</p>
              </div>
            </div>
          </section>
        </div>
      )}

      {/* Add Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-background/80 backdrop-blur-sm">
          <div className="bg-card rounded-2xl shadow-xl border border-border-light w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="p-4 border-b border-border-light flex items-center justify-between">
              <h2 className="text-lg font-bold text-text-main">Add Knowledge Entry</h2>
              <button onClick={() => setShowAddModal(false)} className="text-text-muted hover:text-text-main">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6 overflow-y-auto custom-scrollbar flex-1">
              <form id="add-form" onSubmit={handleAddSubmit} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-1">Title</label>
                  <input required type="text" value={formData.title} onChange={e => setFormData({...formData, title: e.target.value})} className="w-full bg-background border border-border-light rounded-lg px-3 py-2 text-sm focus:border-primary focus:outline-none" />
                </div>
                <div>
                  <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-1">Pattern / Content</label>
                  <textarea required value={formData.pattern} onChange={e => setFormData({...formData, pattern: e.target.value})} rows={3} className="w-full bg-background border border-border-light rounded-lg px-3 py-2 text-sm focus:border-primary focus:outline-none" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-1">Category</label>
                    <select required value={formData.category} onChange={e => setFormData({...formData, category: e.target.value})} className="w-full bg-background border border-border-light rounded-lg px-3 py-2 text-sm focus:border-primary focus:outline-none">
                      <option value="PHISHING">Phishing</option>
                      <option value="INVESTMENT_SCAM">Investment</option>
                      <option value="IMPERSONATION">Impersonation</option>
                      <option value="MALWARE">Malware</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-1">Risk Level</label>
                    <select required value={formData.risk_level} onChange={e => setFormData({...formData, risk_level: e.target.value})} className="w-full bg-background border border-border-light rounded-lg px-3 py-2 text-sm focus:border-primary focus:outline-none">
                      <option value="CRITICAL">Critical</option>
                      <option value="HIGH">High</option>
                      <option value="MEDIUM">Medium</option>
                      <option value="LOW">Low</option>
                    </select>
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-1">Safe Action Recommendation</label>
                  <input required type="text" value={formData.safe_action} onChange={e => setFormData({...formData, safe_action: e.target.value})} className="w-full bg-background border border-border-light rounded-lg px-3 py-2 text-sm focus:border-primary focus:outline-none" />
                </div>
                <div>
                  <label className="block text-xs font-bold text-text-muted uppercase tracking-wider mb-1">Indicators (comma separated)</label>
                  <input type="text" value={formData.indicators} onChange={e => setFormData({...formData, indicators: e.target.value})} placeholder="e.g. urgent language, fake domain" className="w-full bg-background border border-border-light rounded-lg px-3 py-2 text-sm focus:border-primary focus:outline-none" />
                </div>
              </form>
            </div>
            <div className="p-4 border-t border-border-light flex justify-end gap-3 bg-background/50">
              <button type="button" onClick={() => setShowAddModal(false)} className="px-4 py-2 font-bold text-text-secondary hover:text-text-main">Cancel</button>
              <button type="submit" form="add-form" className="px-6 py-2 bg-primary text-white font-bold rounded-lg hover:bg-primary-hover shadow-lg shadow-primary/20">Add Entry</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

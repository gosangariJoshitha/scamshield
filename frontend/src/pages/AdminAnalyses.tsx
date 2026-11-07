import React, { useCallback, useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  ChevronLeft, ChevronRight, Eye, RefreshCw,
  Search, ShieldAlert, X
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { api } from '../services/api';
import AdminBackButton from '../components/AdminBackButton';

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
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();

  const [analyses, setAnalyses] = useState<AnalysisItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Pagination & Filtering
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);

  // Filters initialized from URL query params
  const [classificationFilter, setClassificationFilter] = useState(() => searchParams.get('classification') ?? '');
  const [riskFilter, setRiskFilter] = useState(() => searchParams.get('risk_level') ?? '');
  const [statusFilter, setStatusFilter] = useState(() => searchParams.get('status') ?? '');
  const [channelFilter, setChannelFilter] = useState(() => searchParams.get('input_type') ?? '');
  const [searchInput, setSearchInput] = useState(() => searchParams.get('search') ?? '');

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
      if (channelFilter) params.set('input_type', channelFilter);
      if (searchInput.trim()) params.set('search', searchInput.trim());

      const response = await api.get(`/admin/analyses?${params.toString()}`);
      setAnalyses(response.data.items ?? []);
      setTotal(response.data.total ?? 0);
      setTotalPages(Math.max(1, response.data.total_pages ?? 1));
      setError(null);
    } catch (err) {
      setError('Failed to load analyses. Verify connection and retry.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, classificationFilter, riskFilter, statusFilter, channelFilter, searchInput]);

  useEffect(() => {
    void fetchAnalyses();
  }, [fetchAnalyses]);

  // Synchronize state when URL query params change (e.g. from Dashboard click)
  useEffect(() => {
    const urlRisk = searchParams.get('risk_level');
    if (urlRisk !== null && urlRisk !== riskFilter) {
      setRiskFilter(urlRisk);
      setPage(1);
    }
  }, [searchParams]);

  const handlePageChange = (newPage: number) => {
    if (newPage >= 1 && newPage <= totalPages) {
      setPage(newPage);
    }
  };

  const handleClearFilters = () => {
    setClassificationFilter('');
    setRiskFilter('');
    setStatusFilter('');
    setChannelFilter('');
    setSearchInput('');
    setPage(1);
    setSearchParams({});
  };

  const getRiskBadge = (level: string) => {
    const l = (level || '').toUpperCase();
    if (l === 'CRITICAL') return 'bg-danger/15 text-danger border-danger/30 font-extrabold';
    if (l === 'HIGH') return 'bg-orange-500/15 text-orange-600 border-orange-500/30 font-bold';
    if (l === 'MEDIUM') return 'bg-warning/15 text-warning border-warning/30 font-semibold';
    return 'bg-success/15 text-success border-success/30 font-semibold';
  };

  const getClassificationBadge = (cls: string) => {
    const c = (cls || '').toUpperCase();
    if (c === 'SCAM') return 'bg-danger/10 text-danger border-danger/20 font-bold';
    if (c === 'SUSPICIOUS') return 'bg-warning/10 text-warning border-warning/20 font-semibold';
    return 'bg-success/10 text-success border-success/20 font-semibold';
  };

  const hasActiveFilters = Boolean(classificationFilter || riskFilter || statusFilter || channelFilter || searchInput);

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      {/* Header */}
      <div className="flex flex-col @content-sm:flex-row @content-sm:items-end justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold uppercase tracking-wider text-primary">Content Scans</span>
            <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-bold text-primary">Inspection Hub</span>
          </div>
          <h1 className="text-3xl font-bold text-text-main mt-1">Analysis Management</h1>
          <p className="text-text-muted text-sm mt-0.5">
            Audit multimodal scans, inspection latency, extracted threat indicators, and RAG retrieval evidence.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <AdminBackButton to="/admin" label="Back to Dashboard" />
          <button
            onClick={() => void fetchAnalyses()}
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
        {/* Risk Level Quick Buttons */}
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-border-light pb-3">
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-xs font-semibold text-text-muted mr-1">Risk Tier:</span>
            {[
              { label: 'All Risks', value: '' },
              { label: 'Critical', value: 'CRITICAL', color: 'hover:text-danger' },
              { label: 'High', value: 'HIGH', color: 'hover:text-orange-600' },
              { label: 'Medium', value: 'MEDIUM', color: 'hover:text-warning' },
              { label: 'Low', value: 'LOW', color: 'hover:text-success' },
            ].map((tier) => {
              const active = riskFilter === tier.value;
              return (
                <button
                  key={tier.label}
                  type="button"
                  onClick={() => { setRiskFilter(tier.value); setPage(1); }}
                  className={`rounded-lg px-2.5 py-1 text-xs font-semibold transition-colors ${
                    active
                      ? 'bg-primary text-white shadow-xs'
                      : `text-text-secondary hover:bg-background ${tier.color || ''}`
                  }`}
                >
                  {tier.label}
                </button>
              );
            })}
          </div>

          {hasActiveFilters && (
            <button
              type="button"
              onClick={handleClearFilters}
              className="text-xs font-semibold text-danger hover:underline flex items-center gap-1"
            >
              <X size={13} /> Reset Filters
            </button>
          )}
        </div>

        {/* Search input + Dropdown Selectors */}
        <div className="grid grid-cols-1 gap-2.5 @content-sm:grid-cols-2 @content-lg:grid-cols-5">
          <div className="relative @content-lg:col-span-2">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-text-muted" />
            <input
              type="text"
              value={searchInput}
              onChange={(e) => { setSearchInput(e.target.value); setPage(1); }}
              placeholder="Search by keywords, URLs, phone numbers, or email…"
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
            value={classificationFilter}
            onChange={(e) => { setClassificationFilter(e.target.value); setPage(1); }}
            className="rounded-lg border border-border-light bg-background px-3 py-1.5 text-xs text-text-main outline-none focus:border-primary"
          >
            <option value="">All Classifications</option>
            <option value="SCAM">Scam</option>
            <option value="SUSPICIOUS">Suspicious</option>
            <option value="GENUINE">Genuine</option>
          </select>

          <select
            value={channelFilter}
            onChange={(e) => { setChannelFilter(e.target.value); setPage(1); }}
            className="rounded-lg border border-border-light bg-background px-3 py-1.5 text-xs text-text-main outline-none focus:border-primary"
          >
            <option value="">All Channels / Modalities</option>
            <option value="TEXT">Text Message / SMS</option>
            <option value="URL">URL / Web Domain</option>
            <option value="IMAGE">Image / Screenshot</option>
            <option value="PDF">PDF Document</option>
            <option value="AUDIO">Audio Voice Call</option>
          </select>

          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
            className="rounded-lg border border-border-light bg-background px-3 py-1.5 text-xs text-text-main outline-none focus:border-primary"
          >
            <option value="">All Processing Statuses</option>
            <option value="COMPLETED">Completed</option>
            <option value="PROCESSING">Processing</option>
            <option value="FAILED">Failed</option>
          </select>
        </div>
      </div>

      {/* Analyses Table */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
        {loading && analyses.length === 0 ? (
          <div className="p-16 flex flex-col items-center justify-center gap-3">
            <RefreshCw className="animate-spin text-primary" size={28} />
            <p className="text-xs font-medium text-text-muted">Loading scan telemetry…</p>
          </div>
        ) : error ? (
          <div className="p-12 text-center text-danger font-medium">
            <p>{error}</p>
            <button onClick={() => void fetchAnalyses()} className="mt-3 text-xs underline font-bold">Retry</button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm whitespace-nowrap">
              <thead className="bg-background text-text-muted text-[10px] uppercase font-bold tracking-wider border-b border-border-light">
                <tr>
                  <th className="px-5 py-3.5">Analysis ID</th>
                  <th className="px-5 py-3.5">Timestamp</th>
                  <th className="px-5 py-3.5">Channel</th>
                  <th className="px-5 py-3.5">Category</th>
                  <th className="px-5 py-3.5">Classification</th>
                  <th className="px-5 py-3.5">Risk Score</th>
                  <th className="px-5 py-3.5">User</th>
                  <th className="px-5 py-3.5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-light">
                {analyses.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="px-6 py-16 text-center text-text-muted">
                      <div className="max-w-md mx-auto space-y-2">
                        <ShieldAlert className="mx-auto text-text-muted" size={32} />
                        <p className="font-semibold text-text-main text-sm">No analyses found</p>
                        <p className="text-xs text-text-muted">
                          No scans matched the selected criteria. Try adjusting filters or searching for different keywords.
                        </p>
                        {hasActiveFilters && (
                          <button
                            type="button"
                            onClick={handleClearFilters}
                            className="mt-2 text-xs font-bold text-primary underline"
                          >
                            Reset all filters
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ) : (
                  analyses.map((a) => (
                    <tr
                      key={a.id}
                      role="link"
                      tabIndex={0}
                      aria-label={`Open details for analysis ${a.id}`}
                      onClick={() => navigate(`/admin/analyses/${a.id}`)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                          e.preventDefault();
                          navigate(`/admin/analyses/${a.id}`);
                        }
                      }}
                      className="cursor-pointer transition-colors hover:bg-background/60 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary"
                    >
                      <td className="px-5 py-3.5 font-mono text-xs font-bold text-primary">
                        <Link to={`/admin/analyses/${a.id}`} className="hover:underline">
                          #{a.id}
                        </Link>
                      </td>
                      <td className="px-5 py-3.5 text-xs text-text-secondary">
                        {new Date(a.created_at).toLocaleString([], { dateStyle: 'short', timeStyle: 'short' })}
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="rounded-md bg-background border border-border-light px-2 py-0.5 text-[11px] font-bold text-text-secondary">
                          {a.input_type || 'TEXT'}
                        </span>
                      </td>
                      <td className="px-5 py-3.5 text-xs font-medium text-text-main">
                        {a.category || 'General'}
                      </td>
                      <td className="px-5 py-3.5">
                        <span className={`rounded-full px-2.5 py-0.5 text-[10px] border ${getClassificationBadge(a.classification)}`}>
                          {a.classification}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-2">
                          <span className={`rounded-full px-2 py-0.5 text-[10px] border ${getRiskBadge(a.risk_level)}`}>
                            {a.risk_level}
                          </span>
                          <span className="font-mono text-xs text-text-muted">
                            {(a.risk_score * 100).toFixed(0)}%
                          </span>
                        </div>
                      </td>
                      <td className="px-5 py-3.5 text-xs text-text-secondary max-w-32 truncate" title={a.user}>
                        {a.user || 'Anonymous'}
                      </td>
                      <td className="px-5 py-3.5 text-right">
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline">
                          <Eye size={13} /> View
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination Bar */}
        {!loading && totalPages > 1 && (
          <div className="p-4 border-t border-border-light flex items-center justify-between bg-background/50 text-xs">
            <span className="text-text-muted">
              Showing page <strong>{page}</strong> of <strong>{totalPages}</strong> ({total} total analyses)
            </span>
            <div className="flex items-center space-x-1.5">
              <button
                onClick={() => handlePageChange(page - 1)}
                disabled={page === 1}
                className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <span className="px-3 py-1 font-bold text-text-main">{page}</span>
              <button
                onClick={() => handlePageChange(page + 1)}
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

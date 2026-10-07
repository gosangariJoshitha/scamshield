import { useCallback, useEffect, useState } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { AlertTriangle, CheckCircle, ChevronLeft, ChevronRight, Clock, Play, RefreshCw } from 'lucide-react';
import { reviewService, type ReviewListResponse } from '../services/reviewService';
import AdminBackButton from '../components/AdminBackButton';

const statusChoices = ['PENDING', 'ASSIGNED', 'IN_REVIEW', 'NEEDS_INFORMATION', 'VERIFIED', 'REJECTED'];
const priorityChoices = ['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
const riskChoices = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
const inputTypeChoices = ['text', 'email', 'image', 'pdf', 'audio'];

function statusClass(status: string) {
  switch (status) {
    case 'PENDING': return 'bg-slate-500/10 text-slate-500';
    case 'ASSIGNED': return 'bg-blue-500/10 text-blue-600';
    case 'IN_REVIEW': return 'bg-cyan-500/10 text-cyan-600';
    case 'NEEDS_INFORMATION': return 'bg-amber-500/10 text-amber-600';
    case 'VERIFIED': return 'bg-green-500/10 text-green-600';
    case 'REJECTED': return 'bg-red-500/10 text-red-600';
    default: return 'bg-slate-500/10 text-slate-500';
  }
}

export default function AdminReviewCenter() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [reviews, setReviews] = useState<ReviewListResponse['items']>([]);
  const [summary, setSummary] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const search = searchParams.get('search') ?? '';
  const [statusFilter, setStatusFilter] = useState('');
  const [priorityFilter, setPriorityFilter] = useState('');
  const [riskFilter, setRiskFilter] = useState('');
  const [inputTypeFilter, setInputTypeFilter] = useState('');
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const pageSize = 20;

  const fetchReviews = useCallback(async () => {
    setLoading(true);
    try {
      const result = await reviewService.getAllReviews({
        skip: (page - 1) * pageSize,
        limit: pageSize,
        search: search.trim() || undefined,
        review_status: statusFilter || undefined,
        priority: priorityFilter || undefined,
        risk_level: riskFilter || undefined,
        input_type: inputTypeFilter || undefined,
      });
      setReviews(result.items);
      setSummary(result.summary);
      setTotal(result.total);
      setTotalPages(Math.max(1, result.total_pages));
      setError(null);
    } catch (requestError) {
      console.error('Unable to load review cases', requestError);
      setError('Unable to load review cases. Please try again.');
    } finally {
      setLoading(false);
    }
  }, [page, search, statusFilter, priorityFilter, riskFilter, inputTypeFilter]);

  useEffect(() => {
    void fetchReviews();
  }, [fetchReviews]);

  const summaryCards = [
    { name: 'Pending', count: summary.PENDING ?? 0, icon: Clock, tone: 'text-warning bg-warning/10' },
    { name: 'In progress', count: (summary.ASSIGNED ?? 0) + (summary.IN_REVIEW ?? 0), icon: Play, tone: 'text-primary bg-primary/10' },
    { name: 'Needs information', count: summary.NEEDS_INFORMATION ?? 0, icon: AlertTriangle, tone: 'text-warning bg-warning/10' },
    { name: 'Verified', count: summary.VERIFIED ?? 0, icon: CheckCircle, tone: 'text-success bg-success/10' },
  ];

  return (
    <div className="space-y-5">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-primary">Trust & safety</p>
          <h2 className="mt-1 text-2xl font-bold tracking-tight text-text-main @content-sm:text-3xl">Human Review</h2>
          <p className="mt-1 text-sm text-text-muted">Investigate escalated and user-submitted analysis cases.</p>
        </div>
        <div className="flex items-center gap-2">
          <AdminBackButton to="/admin" label="Back to Dashboard" />
          <button
            type="button"
            onClick={() => void fetchReviews()}
            disabled={loading}
            className="inline-flex h-9 items-center gap-2 rounded-lg border border-border-light bg-card px-3 text-sm font-semibold text-text-secondary hover:bg-background disabled:opacity-50"
          >
            <RefreshCw size={15} className={loading ? 'animate-spin' : ''} /> Refresh
          </button>
        </div>
      </header>

      {error && <div role="alert" className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-danger/20 bg-danger/5 px-4 py-3 text-sm text-danger">{error}<button className="font-semibold underline" onClick={() => void fetchReviews()}>Retry</button></div>}

      <section aria-label="Review case summary" className="grid grid-cols-2 gap-3 @content-xl:grid-cols-4">
        {summaryCards.map(({ name, count, icon: Icon, tone }) => (
          <article key={name} className="flex items-center gap-3 rounded-xl border border-border-light bg-card p-4 shadow-sm">
            <span className={`grid h-10 w-10 place-items-center rounded-lg ${tone}`}><Icon size={19} /></span>
            <div><p className="text-xs text-text-muted">{name}</p><p className="text-xl font-bold tabular-nums text-text-main">{count.toLocaleString()}</p></div>
          </article>
        ))}
      </section>

      <section className="overflow-hidden rounded-xl border border-border-light bg-card shadow-sm">
        <div className="flex flex-col gap-3 border-b border-border-light bg-background/50 p-4 @content-sm:flex-row @content-sm:items-center @content-sm:justify-between">
          <div>
            <h3 className="font-semibold text-text-main">Review queue</h3>
            <p className="mt-0.5 text-xs text-text-muted">{total.toLocaleString()} matching cases · {summary.TOTAL?.toLocaleString() ?? 0} total</p>
          </div>
          <div className="grid grid-cols-2 gap-2 @content-sm:flex">
            <select
              value={statusFilter}
              onChange={(event) => { setStatusFilter(event.target.value); setPage(1); }}
              aria-label="Filter cases by status"
              className="h-10 rounded-lg border border-border-light bg-card px-3 text-sm text-text-main outline-none focus:border-primary"
            >
              <option value="">All statuses</option>
              {statusChoices.map((status) => <option key={status} value={status}>{status.replaceAll('_', ' ')}</option>)}
            </select>
            <select
              value={priorityFilter}
              onChange={(event) => { setPriorityFilter(event.target.value); setPage(1); }}
              aria-label="Filter cases by priority"
              className="h-10 rounded-lg border border-border-light bg-card px-3 text-sm text-text-main outline-none focus:border-primary"
            >
              <option value="">All priorities</option>
              {priorityChoices.map((priority) => <option key={priority} value={priority}>{priority}</option>)}
            </select>
            <select
              value={riskFilter}
              onChange={(event) => { setRiskFilter(event.target.value); setPage(1); }}
              aria-label="Filter cases by risk level"
              className="h-10 rounded-lg border border-border-light bg-card px-3 text-sm text-text-main outline-none focus:border-primary"
            >
              <option value="">All risk levels</option>
              {riskChoices.map((risk) => <option key={risk} value={risk}>{risk}</option>)}
            </select>
            <select
              value={inputTypeFilter}
              onChange={(event) => { setInputTypeFilter(event.target.value); setPage(1); }}
              aria-label="Filter cases by input type"
              className="h-10 rounded-lg border border-border-light bg-card px-3 text-sm text-text-main outline-none focus:border-primary"
            >
              <option value="">All channels</option>
              {inputTypeChoices.map((inputType) => <option key={inputType} value={inputType}>{inputType.toUpperCase()}</option>)}
            </select>
          </div>
        </div>

        {loading && reviews.length === 0 ? (
          <div className="grid min-h-48 place-items-center"><RefreshCw className="animate-spin text-primary" size={24} /></div>
        ) : reviews.length === 0 ? (
          <div className="p-12 text-center text-sm text-text-muted">{search || statusFilter ? 'No cases match the current search and filters.' : 'No human-review cases yet.'}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[780px] text-left text-sm">
              <thead className="bg-background text-[10px] uppercase tracking-wide text-text-muted">
                <tr><th className="px-4 py-3 font-semibold">Case</th><th className="px-4 py-3 font-semibold">Risk / priority</th><th className="px-4 py-3 font-semibold">Reported content</th><th className="px-4 py-3 font-semibold">Status</th><th className="px-4 py-3 font-semibold">Reporter</th><th className="px-4 py-3 text-right font-semibold">Action</th></tr>
              </thead>
              <tbody className="divide-y divide-border-light">
                {reviews.map((review) => (
                  <tr
                    key={review.id}
                    role="link"
                    tabIndex={0}
                    aria-label={`Open review case ${review.id}`}
                    onClick={() => navigate(`/admin/reviews/${review.id}`)}
                    onKeyDown={(event) => {
                      if (event.key === 'Enter' || event.key === ' ') {
                        event.preventDefault();
                        navigate(`/admin/reviews/${review.id}`);
                      }
                    }}
                    className="cursor-pointer hover:bg-background/60 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary"
                  >
                    <td className="whitespace-nowrap px-4 py-3">
                      <p className="font-semibold text-text-main">RV-{review.id}</p>
                      <p className="text-xs text-text-muted">Analysis #{review.analysis_id}</p>
                    </td>
                    <td className="whitespace-nowrap px-4 py-3">
                      <p className="text-xs font-semibold text-text-main">{review.risk_level || 'Unrated'} · {review.priority}</p>
                      <p className="mt-1 text-xs text-text-muted">{review.category || review.input_type || 'General'}</p>
                    </td>
                    <td className="max-w-xs px-4 py-3 text-xs text-text-secondary"><p className="line-clamp-2">{review.content_preview || review.escalation_reason || '—'}</p></td>
                    <td className="whitespace-nowrap px-4 py-3"><span className={`rounded-full px-2 py-1 text-[10px] font-semibold ${statusClass(review.status)}`}>{review.status.replaceAll('_', ' ')}</span></td>
                    <td className="max-w-40 truncate px-4 py-3 text-xs text-text-secondary" title={review.reporter}>{review.reporter}</td>
                    <td className="px-4 py-3 text-right"><button onClick={(event) => { event.stopPropagation(); navigate(`/admin/reviews/${review.id}`); }} className="rounded-lg bg-primary/10 px-3 py-1.5 text-xs font-semibold text-primary hover:bg-primary/20">View case</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <div className="flex items-center justify-between border-t border-border-light px-4 py-3 text-xs text-text-muted">
          <span>Page {page} of {totalPages}</span>
          <div className="flex gap-2">
            <button onClick={() => setPage((current) => Math.max(1, current - 1))} disabled={page <= 1 || loading} aria-label="Previous page" className="rounded-lg border border-border-light p-2 text-text-secondary hover:bg-background disabled:opacity-40"><ChevronLeft size={16} /></button>
            <button onClick={() => setPage((current) => Math.min(totalPages, current + 1))} disabled={page >= totalPages || loading} aria-label="Next page" className="rounded-lg border border-border-light p-2 text-text-secondary hover:bg-background disabled:opacity-40"><ChevronRight size={16} /></button>
          </div>
        </div>
      </section>
    </div>
  );
}

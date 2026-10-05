import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Activity, AlertTriangle, ArrowUpRight, ClipboardCheck, FileWarning,
  RefreshCw, Search, ShieldAlert, Users
} from 'lucide-react';
import {
  Area, AreaChart, Cell, Pie, PieChart, ResponsiveContainer,
  Tooltip, XAxis, YAxis
} from 'recharts';
import { api } from '../services/api';
import { useNavigate } from 'react-router-dom';

type ActivityPoint = { date: string; count: number };
type CountItem = { name: string; value: number };
type ReviewItem = {
  id: number;
  analysis_id: number;
  status: string;
  priority: string;
  created_at: string;
  risk_level?: string | null;
  input_type?: string | null;
  reporter: string;
};
type ReportItem = {
  id: number;
  category?: string | null;
  content: string;
  status: string;
  created_at: string;
  reporter: string;
};
type OverviewStats = {
  totalAnalyses: number;
  highRisk: number;
  pendingReviews: number;
  communityReports: number;
  riskDistribution: CountItem[];
  analysisActivity: ActivityPoint[];
  recentReviews: ReviewItem[];
  recentCommunityReports: ReportItem[];
  reportStatusCounts: Record<string, number>;
  reviewStatusCounts: Record<string, number>;
};

const riskColors: Record<string, string> = {
  LOW: '#16A34A', MEDIUM: '#F59E0B', HIGH: '#EA580C', CRITICAL: '#DC2626',
};

function countLabel(value: number | undefined) {
  return (value ?? 0).toLocaleString();
}

function statusStyle(status: string) {
  if (['VERIFIED', 'APPROVED', 'CLOSED'].includes(status)) return 'bg-success/10 text-success';
  if (['REJECTED'].includes(status)) return 'bg-danger/10 text-danger';
  if (['IN_REVIEW', 'ASSIGNED'].includes(status)) return 'bg-info/10 text-info';
  return 'bg-warning/10 text-warning';
}

function EmptyPanel({ children }: { children: string }) {
  return <div className="flex min-h-36 items-center justify-center text-sm text-text-muted">{children}</div>;
}

export default function AdminOverview() {
  const navigate = useNavigate();
  const [days, setDays] = useState(30);
  const [stats, setStats] = useState<OverviewStats | null>(null);
  const [health, setHealth] = useState<Record<string, string> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchOverview = useCallback(async () => {
    setLoading(true);
    try {
      const [overview, serviceHealth] = await Promise.all([
        api.get(`/admin/overview?days=${days}`),
        api.get('/admin/monitoring/health'),
      ]);
      setStats(overview.data);
      setHealth(serviceHealth.data);
      setError(null);
    } catch (requestError) {
      console.error('Unable to load admin overview', requestError);
      setError('Unable to load the dashboard. Check the connection and try again.');
    } finally {
      setLoading(false);
    }
  }, [days]);

  useEffect(() => {
    void fetchOverview();
  }, [fetchOverview]);

  if (loading && !stats) {
    return (
      <div className="grid min-h-80 place-items-center rounded-2xl border border-border-light bg-card">
        <RefreshCw className="animate-spin text-primary" size={28} />
      </div>
    );
  }

  if (error && !stats) {
    return (
      <div role="alert" className="rounded-2xl border border-danger/20 bg-card p-8 text-center">
        <AlertTriangle className="mx-auto mb-3 text-danger" size={28} />
        <p className="font-semibold text-text-main">{error}</p>
        <button onClick={() => void fetchOverview()} className="mt-4 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white">
          Retry
        </button>
      </div>
    );
  }

  if (!stats) return null;
  const reviewTotal = Object.values(stats.reviewStatusCounts ?? {}).reduce((total, count) => total + count, 0);
  const cards = [
    { label: `Analyses · ${days} days`, value: stats.totalAnalyses, icon: Search, tone: 'text-info bg-info/10' },
    { label: 'High / Critical Risk', value: stats.highRisk, icon: ShieldAlert, tone: 'text-danger bg-danger/10' },
    { label: 'Pending Reviews', value: stats.pendingReviews, icon: ClipboardCheck, tone: 'text-warning bg-warning/10' },
    { label: `Community Reports · ${days} days`, value: stats.communityReports, icon: Users, tone: 'text-primary bg-primary/10' },
  ];

  return (
    <div className="space-y-5">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-primary">ScamShield administration</p>
          <h2 className="mt-1 text-2xl font-bold tracking-tight text-text-main @content-sm:text-3xl">Dashboard</h2>
          <p className="mt-1 text-sm text-text-muted">Overview of current analysis and moderation activity.</p>
        </div>
        <div className="flex items-center gap-2">
          <label htmlFor="overview-days" className="sr-only">Dashboard date range</label>
          <select
            id="overview-days"
            value={days}
            onChange={(event) => setDays(Number(event.target.value))}
            className="h-10 rounded-lg border border-border-light bg-card px-3 text-sm text-text-secondary outline-none focus:border-primary focus:ring-2 focus:ring-primary/15"
          >
            <option value={7}>Last 7 days</option>
            <option value={30}>Last 30 days</option>
            <option value={90}>Last 90 days</option>
          </select>
          <button
            type="button"
            onClick={() => void fetchOverview()}
            disabled={loading}
            aria-label="Refresh dashboard"
            className="rounded-lg border border-border-light bg-card p-2.5 text-text-secondary hover:bg-background disabled:opacity-50"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          </button>
        </div>
      </header>

      {error && <p role="alert" className="rounded-lg border border-danger/20 bg-danger/5 px-4 py-3 text-sm text-danger">{error}</p>}

      <section aria-label="Platform summary" className="grid grid-cols-1 gap-3 @content-sm:grid-cols-2 @content-xl:grid-cols-4">
        {cards.map(({ label, value, icon: Icon, tone }) => (
          <article key={label} className="flex min-h-28 items-center gap-4 rounded-xl border border-border-light bg-card p-4 shadow-sm">
            <span className={`-translate-y-1 grid h-11 w-11 shrink-0 place-items-center rounded-xl ${tone}`}><Icon size={20} /></span>
            <div className="min-w-0">
              <p className="text-xs font-medium text-text-muted">{label}</p>
              <p className="mt-1 text-2xl font-bold tabular-nums text-text-main">{loading ? '…' : countLabel(value)}</p>
            </div>
          </article>
        ))}
      </section>

      <section className="grid grid-cols-1 gap-4 @content-xl:grid-cols-3">
        <article className="rounded-xl border border-border-light bg-card p-4 shadow-sm @content-xl:col-span-2 @content-sm:p-5">
          <div className="mb-3 flex items-start justify-between gap-3">
            <div>
              <h3 className="font-semibold text-text-main">Analysis activity</h3>
              <p className="mt-0.5 text-xs text-text-muted">Completed analyses by creation date</p>
            </div>
            <Activity className="text-primary" size={18} />
          </div>
          {stats.analysisActivity?.some((point) => point.count > 0) ? (
            <div className="h-56">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={stats.analysisActivity} margin={{ top: 8, right: 10, bottom: 0, left: -20 }}>
                  <defs>
                    <linearGradient id="analysisActivityFill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#06B6D4" stopOpacity={0.25} />
                      <stop offset="100%" stopColor="#06B6D4" stopOpacity={0.01} />
                    </linearGradient>
                  </defs>
                  <XAxis dataKey="date" tickFormatter={(date: string) => new Date(`${date}T00:00:00`).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })} tick={{ fill: 'var(--color-text-muted)', fontSize: 11 }} axisLine={false} tickLine={false} />
                  <YAxis allowDecimals={false} tick={{ fill: 'var(--color-text-muted)', fontSize: 11 }} axisLine={false} tickLine={false} />
                  <Tooltip labelFormatter={(date) => String(date)} contentStyle={{ background: 'var(--color-card)', borderColor: 'var(--color-border-light)', borderRadius: 10, color: 'var(--color-text)' }} />
                  <Area type="monotone" dataKey="count" name="Analyses" stroke="#0891B2" strokeWidth={2.5} fill="url(#analysisActivityFill)" activeDot={{ r: 4 }} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          ) : <EmptyPanel>No analysis activity in this period.</EmptyPanel>}
        </article>

        <article className="rounded-xl border border-border-light bg-card p-4 shadow-sm @content-sm:p-5">
          <div className="mb-3 flex items-start justify-between gap-3">
            <div>
              <h3 className="font-semibold text-text-main">Risk distribution</h3>
              <p className="mt-0.5 text-xs text-text-muted">Analyses in selected period</p>
            </div>
            <AlertTriangle className="text-warning" size={18} />
          </div>
          {stats.riskDistribution.length ? (
            <>
              <div className="h-40">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={stats.riskDistribution} dataKey="value" nameKey="name" innerRadius={43} outerRadius={67} paddingAngle={3}>
                      {stats.riskDistribution.map((risk) => <Cell key={risk.name} fill={riskColors[risk.name] ?? '#64748B'} />)}
                    </Pie>
                    <Tooltip contentStyle={{ background: 'var(--color-card)', borderColor: 'var(--color-border-light)', borderRadius: 10, color: 'var(--color-text)' }} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="flex flex-wrap justify-center gap-x-4 gap-y-2">
                {stats.riskDistribution.map((risk) => (
                  <span key={risk.name} className="inline-flex items-center gap-1.5 text-xs text-text-secondary">
                    <span className="h-2 w-2 rounded-full" style={{ backgroundColor: riskColors[risk.name] ?? '#64748B' }} />
                    {risk.name} <b className="font-semibold text-text-main">{countLabel(risk.value)}</b>
                  </span>
                ))}
              </div>
            </>
          ) : <EmptyPanel>No risk data available.</EmptyPanel>}
        </article>
      </section>

      <section className="grid grid-cols-1 gap-4 @content-xl:grid-cols-5">
        <article className="overflow-hidden rounded-xl border border-border-light bg-card shadow-sm @content-xl:col-span-3">
          <div className="flex items-center justify-between border-b border-border-light px-4 py-4 @content-sm:px-5">
            <div>
              <h3 className="font-semibold text-text-main">Recent human reviews</h3>
              <p className="mt-0.5 text-xs text-text-muted">{countLabel(reviewTotal)} cases total</p>
            </div>
            <Link to="/admin/reviews" className="inline-flex items-center gap-1 text-xs font-semibold text-primary hover:text-primary-hover">
              View queue <ArrowUpRight size={14} />
            </Link>
          </div>
          {stats.recentReviews.length ? (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[540px] text-left text-sm">
                <thead className="bg-background text-[10px] uppercase tracking-wide text-text-muted">
                  <tr><th className="px-4 py-3 font-semibold">Case</th><th className="px-4 py-3 font-semibold">Type / Risk</th><th className="px-4 py-3 font-semibold">Status</th><th className="px-4 py-3 font-semibold">Reported by</th></tr>
                </thead>
                <tbody className="divide-y divide-border-light">
                  {stats.recentReviews.map((item) => (
                    <tr
                      key={item.id}
                      role="link"
                      tabIndex={0}
                      aria-label={`Open review case ${item.id}`}
                      onClick={() => navigate(`/admin/reviews/${item.id}`)}
                      onKeyDown={(event) => {
                        if (event.key === 'Enter' || event.key === ' ') {
                          event.preventDefault();
                          navigate(`/admin/reviews/${item.id}`);
                        }
                      }}
                      className="cursor-pointer hover:bg-background/60 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary"
                    >
                      <td className="px-4 py-3"><Link to={`/admin/reviews/${item.id}`} className="font-semibold text-primary hover:underline">RV-{item.id}</Link><p className="text-xs text-text-muted">Analysis #{item.analysis_id}</p></td>
                      <td className="px-4 py-3 text-xs text-text-secondary">{item.input_type || 'Unknown'}<p className="mt-1 font-semibold">{item.risk_level || 'Unrated'}</p></td>
                      <td className="px-4 py-3"><span className={`rounded-full px-2 py-1 text-[10px] font-semibold ${statusStyle(item.status)}`}>{item.status.replaceAll('_', ' ')}</span></td>
                      <td className="max-w-32 truncate px-4 py-3 text-xs text-text-secondary" title={item.reporter}>{item.reporter}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : <EmptyPanel>No human-review cases yet.</EmptyPanel>}
        </article>

        <article className="overflow-hidden rounded-xl border border-border-light bg-card shadow-sm @content-xl:col-span-2">
          <div className="flex items-center justify-between border-b border-border-light px-4 py-4 @content-sm:px-5">
            <div>
              <h3 className="font-semibold text-text-main">Community reports</h3>
              <p className="mt-0.5 text-xs text-text-muted">{countLabel(stats.communityReports)} in selected period</p>
            </div>
            <Link to="/admin/community" className="inline-flex items-center gap-1 text-xs font-semibold text-primary hover:text-primary-hover">
              View reports <ArrowUpRight size={14} />
            </Link>
          </div>
          {stats.recentCommunityReports.length ? (
            <ul className="divide-y divide-border-light">
              {stats.recentCommunityReports.map((report) => (
                <li key={report.id}>
                  <Link
                    to={`/admin/community?report=${report.id}`}
                    className="flex items-start gap-3 px-4 py-3 transition-colors hover:bg-background/60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary @content-sm:px-5"
                  >
                  <span className="mt-0.5 grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-primary/10 text-primary"><FileWarning size={16} /></span>
                  <div className="min-w-0 flex-1">
                    <p className="line-clamp-2 text-sm font-medium text-text-main">{report.content}</p>
                    <p className="mt-1 truncate text-xs text-text-muted">{report.category || 'Uncategorized'} · {report.reporter}</p>
                  </div>
                  <span className={`shrink-0 rounded-full px-2 py-1 text-[10px] font-semibold ${statusStyle(report.status.toUpperCase())}`}>{report.status.replaceAll('_', ' ')}</span>
                  </Link>
                </li>
              ))}
            </ul>
          ) : <EmptyPanel>No community reports yet.</EmptyPanel>}
        </article>
      </section>

      <section className="rounded-xl border border-border-light bg-card p-4 shadow-sm @content-sm:p-5">
        <div className="mb-3 flex items-center gap-2">
          <Activity className="text-primary" size={17} />
          <h3 className="font-semibold text-text-main">Service status</h3>
        </div>
        {health ? (
          <div className="flex flex-wrap gap-2">
            {Object.entries(health).map(([service, status]) => {
              const healthy = status.toLowerCase() === 'healthy' || status.toLowerCase() === 'configured';
              return (
                <span key={service} className={`inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-medium ${
                  healthy ? 'border-success/20 bg-success/5 text-success' : 'border-warning/20 bg-warning/5 text-warning'
                }`}>
                  <span className={`h-1.5 w-1.5 rounded-full ${healthy ? 'bg-success' : 'bg-warning'}`} />
                  {service.replaceAll('_', ' ')} · {status}
                </span>
              );
            })}
          </div>
        ) : (
          <p className="text-sm text-text-muted">Service health is unavailable.</p>
        )}
      </section>
    </div>
  );
}

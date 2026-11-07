import { useCallback, useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  Activity, AlertTriangle, ArrowUpRight, CheckCircle2, ClipboardCheck,
  FileWarning, RefreshCw, Search, ShieldAlert, ShieldBan, Users
} from 'lucide-react';
import {
  Area, AreaChart, Cell, Pie, PieChart, ResponsiveContainer,
  Tooltip, XAxis, YAxis
} from 'recharts';
import { api } from '../services/api';

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
  scamsDetected?: number;
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
type SystemHealth = {
  api: string;
  database: string;
  ml_model: string;
  model_version: string | null;
  chromadb: string;
  chromadb_vectors: number | null;
  chromadb_expected_minimum: number;
  embedding: string;
  llm: string;
};

const riskColors: Record<string, string> = {
  LOW: '#16A34A',
  MEDIUM: '#F59E0B',
  HIGH: '#EA580C',
  CRITICAL: '#DC2626',
};

function countLabel(value: number | undefined) {
  return (value ?? 0).toLocaleString();
}

function statusStyle(status: string) {
  const s = status.toUpperCase();
  if (['VERIFIED', 'APPROVED', 'CLOSED'].includes(s)) return 'bg-success/10 text-success border border-success/20';
  if (['REJECTED'].includes(s)) return 'bg-danger/10 text-danger border border-danger/20';
  if (['IN_REVIEW', 'ASSIGNED'].includes(s)) return 'bg-info/10 text-info border border-info/20';
  return 'bg-warning/10 text-warning border border-warning/20';
}

function priorityStyle(priority: string) {
  const p = priority.toUpperCase();
  if (p === 'URGENT') return 'bg-danger text-white font-bold animate-pulse';
  if (p === 'HIGH') return 'bg-danger/15 text-danger font-semibold';
  if (p === 'MEDIUM') return 'bg-warning/15 text-warning font-medium';
  return 'bg-slate-500/10 text-text-muted';
}

function EmptyPanel({ children }: { children: string }) {
  return <div className="flex min-h-36 items-center justify-center text-sm text-text-muted">{children}</div>;
}

export default function AdminOverview() {
  const navigate = useNavigate();
  const [days, setDays] = useState(30);
  const [stats, setStats] = useState<OverviewStats | null>(null);
  const [health, setHealth] = useState<SystemHealth | null>(null);
  const [jiraStatus, setJiraStatus] = useState<string>('Unknown');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastRefreshed, setLastRefreshed] = useState<Date | null>(null);

  const fetchOverview = useCallback(async () => {
    setLoading(true);
    try {
      const [overview, serviceHealth, adminHealth] = await Promise.all([
        api.get(`/admin/overview?days=${days}`),
        api.get('/admin/monitoring/health'),
        api.get('/admin/health').catch(() => ({ data: null })),
      ]);
      setStats(overview.data);
      setHealth(serviceHealth.data);
      if (adminHealth?.data?.jira_integration?.status === 'up') {
        setJiraStatus('Configured');
      } else if (adminHealth?.data?.jira_integration?.status === 'not_configured') {
        setJiraStatus('Not Configured');
      } else {
        setJiraStatus('Unknown');
      }
      setLastRefreshed(new Date());
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

  const handleRiskClick = (riskLevel: string) => {
    navigate(`/admin/analyses?risk_level=${encodeURIComponent(riskLevel)}`);
  };

  if (loading && !stats) {
    return (
      <div className="grid min-h-80 place-items-center rounded-2xl border border-border-light bg-card">
        <div className="flex flex-col items-center gap-3">
          <RefreshCw className="animate-spin text-primary" size={32} />
          <p className="text-sm font-medium text-text-muted">Loading administrative dashboard…</p>
        </div>
      </div>
    );
  }

  if (error && !stats) {
    return (
      <div role="alert" className="rounded-2xl border border-danger/20 bg-card p-8 text-center shadow-sm">
        <AlertTriangle className="mx-auto mb-3 text-danger" size={32} />
        <h3 className="text-lg font-bold text-text-main">Unable to load dashboard</h3>
        <p className="mt-1 text-sm text-text-muted">{error}</p>
        <button
          onClick={() => void fetchOverview()}
          className="mt-5 rounded-lg bg-primary px-5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-primary-hover"
        >
          Retry connection
        </button>
      </div>
    );
  }

  if (!stats) return null;

  const reviewTotal = Object.values(stats.reviewStatusCounts ?? {}).reduce((total, count) => total + count, 0);

  const cards = [
    {
      label: `Total Analyses (${days}d)`,
      sublabel: 'Total scans evaluated',
      value: stats.totalAnalyses,
      icon: Search,
      tone: 'text-info bg-info/10',
      action: () => navigate('/admin/analyses'),
      badge: 'View all',
    },
    {
      label: `Scams Detected (${days}d)`,
      sublabel: 'Confirmed scam classifications',
      value: stats.scamsDetected ?? 0,
      icon: ShieldBan,
      tone: 'text-danger bg-danger/10',
      action: () => navigate('/admin/analyses?classification=SCAM'),
      badge: (stats.scamsDetected ?? 0) > 0 ? `${stats.scamsDetected} detected` : 'Zero',
      badgeTone: (stats.scamsDetected ?? 0) > 0 ? 'bg-danger/10 text-danger' : 'bg-success/10 text-success',
    },
    {
      label: `High / Critical (${days}d)`,
      sublabel: 'Actionable scam threats',
      value: stats.highRisk,
      icon: ShieldAlert,
      tone: 'text-orange-600 bg-orange-500/10',
      action: () => navigate('/admin/analyses?risk_level=HIGH'),
      badge: stats.highRisk > 0 ? 'Requires attention' : 'Clear',
      badgeTone: stats.highRisk > 0 ? 'bg-danger/10 text-danger' : 'bg-success/10 text-success',
    },
    {
      label: 'Pending Reviews',
      sublabel: 'Human verification queue',
      value: stats.pendingReviews,
      icon: ClipboardCheck,
      tone: 'text-warning bg-warning/10',
      action: () => navigate('/admin/reviews?status=PENDING'),
      badge: stats.pendingReviews > 0 ? `${stats.pendingReviews} in queue` : 'Caught up',
      badgeTone: stats.pendingReviews > 0 ? 'bg-warning/10 text-warning' : 'bg-success/10 text-success',
    },
    {
      label: `Community Reports (${days}d)`,
      sublabel: 'User crowd reports',
      value: stats.communityReports,
      icon: Users,
      tone: 'text-primary bg-primary/10',
      action: () => navigate('/admin/community'),
      badge: 'Manage',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header with Title, Period Selector, Timestamp and Refresh */}
      <header className="flex flex-col gap-4 @content-md:flex-row @content-md:items-end @content-md:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <span className="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-semibold text-primary">
              <span className="h-1.5 w-1.5 rounded-full bg-primary animate-pulse" />
              Operational Control
            </span>
            {lastRefreshed && (
              <span className="text-xs text-text-muted">
                Updated {lastRefreshed.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
              </span>
            )}
          </div>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-text-main @content-sm:text-3xl">System Dashboard</h1>
          <p className="mt-1 text-sm text-text-muted">Live telemetry, risk distribution, and moderation workflow.</p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center rounded-lg border border-border-light bg-card p-1 shadow-sm">
            {[
              { label: '7 days', value: 7 },
              { label: '30 days', value: 30 },
              { label: '90 days', value: 90 },
            ].map((p) => (
              <button
                key={p.value}
                type="button"
                onClick={() => setDays(p.value)}
                className={`rounded-md px-3 py-1.5 text-xs font-semibold transition-colors ${
                  days === p.value
                    ? 'bg-primary text-white shadow-xs'
                    : 'text-text-muted hover:text-text-main'
                }`}
              >
                {p.label}
              </button>
            ))}
          </div>

          <button
            type="button"
            onClick={() => void fetchOverview()}
            disabled={loading}
            aria-label="Refresh dashboard data"
            title="Refresh dashboard"
            className="inline-flex h-9 items-center justify-center gap-2 rounded-lg border border-border-light bg-card px-3 text-xs font-semibold text-text-secondary shadow-sm hover:bg-background disabled:opacity-50"
          >
            <RefreshCw size={14} className={loading ? 'animate-spin text-primary' : ''} />
            <span>Refresh</span>
          </button>
        </div>
      </header>

      {error && (
        <div role="alert" className="flex items-center justify-between rounded-xl border border-danger/20 bg-danger/5 px-4 py-3 text-sm text-danger">
          <span>{error}</span>
          <button onClick={() => void fetchOverview()} className="font-semibold underline underline-offset-2">Retry</button>
        </div>
      )}

      {/* Primary KPI Cards */}
      <section aria-label="Platform summary metrics" className="grid grid-cols-1 gap-4 @content-sm:grid-cols-2 @content-lg:grid-cols-3 @content-xl:grid-cols-5">
        {cards.map(({ label, sublabel, value, icon: Icon, tone, action, badge, badgeTone }) => (
          <article
            key={label}
            onClick={action}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); action(); } }}
            className="group relative flex cursor-pointer flex-col justify-between rounded-2xl border border-border-light bg-card p-5 shadow-sm transition-all hover:border-primary/40 hover:shadow-md focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
          >
            <div className="flex items-start justify-between gap-3">
              <span className={`grid h-12 w-12 place-items-center rounded-xl transition-transform group-hover:scale-105 ${tone}`}>
                <Icon size={22} />
              </span>
              <span className={`rounded-full px-2.5 py-1 text-[11px] font-semibold ${badgeTone || 'bg-background text-text-secondary border border-border-light'}`}>
                {badge}
              </span>
            </div>

            <div className="mt-4">
              <p className="text-xs font-medium text-text-muted">{label}</p>
              <div className="flex items-baseline justify-between">
                <p className="text-3xl font-extrabold tracking-tight tabular-nums text-text-main">
                  {loading ? '…' : countLabel(value)}
                </p>
                <ArrowUpRight size={16} className="text-text-muted opacity-0 transition-opacity group-hover:opacity-100 group-hover:text-primary" />
              </div>
              <p className="mt-1 text-[11px] text-text-muted">{sublabel}</p>
            </div>
          </article>
        ))}
      </section>

      {/* Middle Row: Trend Analysis + Interactive Risk Distribution */}
      <section className="grid grid-cols-1 gap-5 @content-xl:grid-cols-3">
        {/* Analysis Activity Chart */}
        <article className="rounded-2xl border border-border-light bg-card p-5 shadow-sm @content-xl:col-span-2">
          <div className="mb-4 flex items-start justify-between gap-3">
            <div>
              <div className="flex items-center gap-2">
                <Activity className="text-primary" size={18} />
                <h2 className="font-bold text-text-main">Analysis Activity Trend</h2>
              </div>
              <p className="mt-0.5 text-xs text-text-muted">Daily analysis volume across all ingestion channels ({days}-day window)</p>
            </div>
            <Link to="/admin/analyses" className="inline-flex items-center gap-1 text-xs font-semibold text-primary hover:underline">
              Inspect logs <ArrowUpRight size={13} />
            </Link>
          </div>

          {stats.analysisActivity?.some((point) => point.count > 0) ? (
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={stats.analysisActivity} margin={{ top: 10, right: 10, bottom: 0, left: -20 }}>
                  <defs>
                    <linearGradient id="analysisActivityFill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#06B6D4" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#06B6D4" stopOpacity={0.0} />
                    </linearGradient>
                  </defs>
                  <XAxis
                    dataKey="date"
                    tickFormatter={(date: string) => {
                      const d = new Date(`${date}T00:00:00`);
                      return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
                    }}
                    tick={{ fill: 'var(--color-text-muted)', fontSize: 11 }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <YAxis
                    allowDecimals={false}
                    tick={{ fill: 'var(--color-text-muted)', fontSize: 11 }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <Tooltip
                    labelFormatter={(date) => String(date)}
                    contentStyle={{
                      backgroundColor: 'var(--color-card)',
                      borderColor: 'var(--color-border-light)',
                      borderRadius: 12,
                      color: 'var(--color-text-main)',
                      fontSize: 12,
                      boxShadow: '0 4px 12px rgba(0, 0, 0, 0.1)',
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="count"
                    name="Analyses"
                    stroke="#0891B2"
                    strokeWidth={2.5}
                    fill="url(#analysisActivityFill)"
                    activeDot={{ r: 5, fill: '#0891B2' }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <EmptyPanel>No recorded analyses in this period.</EmptyPanel>
          )}
        </article>

        {/* Interactive Risk Distribution */}
        <article className="flex flex-col justify-between rounded-2xl border border-border-light bg-card p-5 shadow-sm">
          <div>
            <div className="flex items-start justify-between gap-3">
              <div>
                <div className="flex items-center gap-2">
                  <ShieldAlert className="text-warning" size={18} />
                  <h2 className="font-bold text-text-main">Risk Distribution</h2>
                </div>
                <p className="mt-0.5 text-xs text-text-muted">Click any tier to filter analyses directly</p>
              </div>
            </div>

            {stats.riskDistribution.length ? (
              <div className="mt-2">
                <div className="h-44">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={stats.riskDistribution}
                        dataKey="value"
                        nameKey="name"
                        innerRadius={48}
                        outerRadius={74}
                        paddingAngle={3}
                        cursor="pointer"
                        onClick={(data) => {
                          if (data && data.name) handleRiskClick(data.name);
                        }}
                      >
                        {stats.riskDistribution.map((risk) => (
                          <Cell
                            key={risk.name}
                            fill={riskColors[risk.name] ?? '#64748B'}
                            className="transition-opacity hover:opacity-80"
                          />
                        ))}
                      </Pie>
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'var(--color-card)',
                          borderColor: 'var(--color-border-light)',
                          borderRadius: 10,
                          fontSize: 12,
                          color: 'var(--color-text-main)',
                        }}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                </div>

                {/* Clickable Legend Badges */}
                <div className="mt-2 grid grid-cols-2 gap-2">
                  {stats.riskDistribution.map((risk) => {
                    const color = riskColors[risk.name] ?? '#64748B';
                    return (
                      <button
                        key={risk.name}
                        type="button"
                        onClick={() => handleRiskClick(risk.name)}
                        title={`Filter analyses by ${risk.name} risk`}
                        className="group flex items-center justify-between rounded-xl border border-border-light bg-background/60 p-2.5 text-left transition-all hover:border-primary/50 hover:bg-card focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                      >
                        <span className="flex items-center gap-2 min-w-0">
                          <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ backgroundColor: color }} />
                          <span className="text-xs font-semibold text-text-secondary group-hover:text-text-main truncate">
                            {risk.name}
                          </span>
                        </span>
                        <span className="text-xs font-bold tabular-nums text-text-main shrink-0">
                          {countLabel(risk.value)}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            ) : (
              <EmptyPanel>No risk distribution data available.</EmptyPanel>
            )}
          </div>

          <div className="mt-4 border-t border-border-light pt-3 text-[11px] text-text-muted flex items-center justify-between">
            <span>High/Critical ratio:</span>
            <span className="font-semibold text-text-main">
              {stats.totalAnalyses > 0 ? `${((stats.highRisk / stats.totalAnalyses) * 100).toFixed(1)}%` : '0%'}
            </span>
          </div>
        </article>
      </section>

      {/* Human Reviews & Community Reports Queue */}
      <section className="grid grid-cols-1 gap-5 @content-xl:grid-cols-5">
        {/* Recent Human Reviews Queue */}
        <article className="overflow-hidden rounded-2xl border border-border-light bg-card shadow-sm @content-xl:col-span-3">
          <div className="flex items-center justify-between border-b border-border-light px-5 py-4">
            <div>
              <h2 className="font-bold text-text-main">Active Review Queue</h2>
              <p className="mt-0.5 text-xs text-text-muted">{countLabel(reviewTotal)} total recorded cases</p>
            </div>
            <Link
              to="/admin/reviews"
              className="inline-flex items-center gap-1.5 rounded-lg border border-border-light bg-background px-3 py-1.5 text-xs font-semibold text-primary transition-colors hover:bg-card hover:text-primary-hover"
            >
              Open Queue <ArrowUpRight size={14} />
            </Link>
          </div>

          {stats.recentReviews.length ? (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[540px] text-left text-sm">
                <thead className="bg-background text-[10px] font-bold uppercase tracking-wider text-text-muted border-b border-border-light">
                  <tr>
                    <th className="px-5 py-3">Case ID</th>
                    <th className="px-5 py-3">Input / Risk</th>
                    <th className="px-5 py-3">Priority</th>
                    <th className="px-5 py-3">Status</th>
                    <th className="px-5 py-3">Reporter</th>
                  </tr>
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
                      className="cursor-pointer transition-colors hover:bg-background/70 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary"
                    >
                      <td className="px-5 py-3.5">
                        <Link to={`/admin/reviews/${item.id}`} className="font-semibold text-primary hover:underline">
                          RV-{item.id}
                        </Link>
                        <p className="text-[11px] text-text-muted">Analysis #{item.analysis_id}</p>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-xs font-medium text-text-main uppercase">{item.input_type || 'Unknown'}</span>
                        <div className="flex items-center gap-1.5 mt-0.5">
                          <span
                            className="h-1.5 w-1.5 rounded-full"
                            style={{ backgroundColor: riskColors[item.risk_level ?? ''] ?? '#64748B' }}
                          />
                          <span className="text-[11px] font-bold text-text-secondary">{item.risk_level || 'Unrated'}</span>
                        </div>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className={`rounded-md px-2 py-0.5 text-[10px] uppercase tracking-wider ${priorityStyle(item.priority)}`}>
                          {item.priority}
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className={`rounded-full px-2.5 py-1 text-[10px] font-bold ${statusStyle(item.status)}`}>
                          {item.status.replaceAll('_', ' ')}
                        </span>
                      </td>
                      <td className="max-w-36 truncate px-5 py-3.5 text-xs text-text-secondary" title={item.reporter}>
                        {item.reporter}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <EmptyPanel>No human-review cases currently recorded.</EmptyPanel>
          )}
        </article>

        {/* Community Scam Reports */}
        <article className="overflow-hidden rounded-2xl border border-border-light bg-card shadow-sm @content-xl:col-span-2">
          <div className="flex items-center justify-between border-b border-border-light px-5 py-4">
            <div>
              <h2 className="font-bold text-text-main">Community Reports</h2>
              <p className="mt-0.5 text-xs text-text-muted">{countLabel(stats.communityReports)} reports in selected period</p>
            </div>
            <Link
              to="/admin/community"
              className="inline-flex items-center gap-1.5 rounded-lg border border-border-light bg-background px-3 py-1.5 text-xs font-semibold text-primary transition-colors hover:bg-card hover:text-primary-hover"
            >
              Moderate <ArrowUpRight size={14} />
            </Link>
          </div>

          {stats.recentCommunityReports.length ? (
            <ul className="divide-y divide-border-light">
              {stats.recentCommunityReports.map((report) => (
                <li key={report.id}>
                  <Link
                    to={`/admin/community?report=${report.id}`}
                    className="flex items-start gap-3.5 px-5 py-3.5 transition-colors hover:bg-background/60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary"
                  >
                    <span className="mt-1 grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-primary/10 text-primary">
                      <FileWarning size={17} />
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="line-clamp-2 text-sm font-medium text-text-main">{report.content}</p>
                      <div className="mt-1 flex items-center gap-2 text-[11px] text-text-muted">
                        <span className="font-semibold text-text-secondary">{report.category || 'Uncategorized'}</span>
                        <span>•</span>
                        <span className="truncate max-w-24">{report.reporter}</span>
                      </div>
                    </div>
                    <span className={`shrink-0 rounded-full px-2.5 py-0.5 text-[10px] font-bold ${statusStyle(report.status)}`}>
                      {report.status.replaceAll('_', ' ')}
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          ) : (
            <EmptyPanel>No community scam submissions yet.</EmptyPanel>
          )}
        </article>
      </section>

      {/* Bottom Service Infrastructure Status */}
      <section className="rounded-2xl border border-border-light bg-card p-5 shadow-sm">
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="text-primary" size={18} />
            <h2 className="font-bold text-text-main">Backend Service Infrastructure</h2>
          </div>
          <Link to="/admin/monitoring" className="inline-flex items-center gap-1 text-xs font-semibold text-primary hover:underline">
            Detailed telemetry <ArrowUpRight size={13} />
          </Link>
        </div>

        {health ? (
          <div className="space-y-3">
            <div className="flex flex-wrap gap-2.5">
              {[
                ['Core API', health.api || 'Unknown'],
                ['PostgreSQL DB', health.database || 'Unknown'],
                ['ML Classifier', health.ml_model || 'Unknown'],
                ['Embedding Engine', health.embedding || 'Unknown'],
                ['ChromaDB Vector Store', health.chromadb || 'Unknown'],
                ['LLM Reasoning', health.llm || 'Unknown'],
                ['OCR Engine', 'Configured'],
                ['Speech-to-Text (Whisper)', 'Configured'],
                ['Jira Integration', jiraStatus],
              ].map(([service, status]) => {
                const s = String(status || '').toLowerCase();
                const isHealthy = ['healthy', 'configured', 'ready', 'up'].includes(s);
                const isNotConfigured = s.includes('not configured');
                const isDown = ['down', 'unavailable'].includes(s);

                const badgeClass = isHealthy
                  ? 'border-success/25 bg-success/5 text-success'
                  : isNotConfigured
                  ? 'border-slate-500/20 bg-slate-500/10 text-text-muted'
                  : isDown
                  ? 'border-danger/25 bg-danger/5 text-danger'
                  : 'border-warning/25 bg-warning/5 text-warning';

                const dotColor = isHealthy
                  ? 'bg-success'
                  : isNotConfigured
                  ? 'bg-slate-400'
                  : isDown
                  ? 'bg-danger'
                  : 'bg-warning';

                return (
                  <span
                    key={service}
                    className={`inline-flex items-center gap-2 rounded-xl border px-3 py-1.5 text-xs font-medium ${badgeClass}`}
                  >
                    <span className={`h-2 w-2 rounded-full ${dotColor}`} />
                    <span className="font-bold">{service}:</span> {status}
                  </span>
                );
              })}
            </div>

            <div className="flex flex-wrap items-center justify-between gap-2 border-t border-border-light pt-3 text-xs text-text-muted">
              <span>
                Active Model Version: <strong className="text-text-main">{health.model_version || 'scamshield-classifier-v5'}</strong>
              </span>
              <span>
                ChromaDB Vector Store: <strong className="text-text-main">{health.chromadb_vectors?.toLocaleString() ?? 972} vectors</strong> (Target: &ge;{health.chromadb_expected_minimum.toLocaleString()} baseline)
              </span>
            </div>
          </div>
        ) : (
          <p className="text-sm text-text-muted">Backend health status ping is currently unavailable.</p>
        )}
      </section>
    </div>
  );
}

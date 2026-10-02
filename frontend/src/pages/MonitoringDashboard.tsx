import React, { useCallback, useEffect, useState } from 'react';
import {
  AlertTriangle, Brain, CheckCircle, Clock, RefreshCw,
  Server, ShieldCheck
} from 'lucide-react';
import { monitoringService } from '../services/monitoring';

interface MonitoringData {
  overview: any;
  performance: any;
  health: Record<string, string>;
  channels: Record<string, {
    count: number;
    success: number;
    failure: number;
    average_latency_ms: number;
    success_rate: number;
  }>;
}

export const MonitoringDashboard: React.FC = () => {
  const [data, setData] = useState<MonitoringData | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      const [overview, performance, health, channels] = await Promise.all([
        monitoringService.getOverview(),
        monitoringService.getPerformance(),
        monitoringService.getHealth(),
        monitoringService.getChannels(),
      ]);
      setData({ overview, performance, health, channels });
      setError(null);
    } catch (err) {
      console.error('Failed to load monitoring data', err);
      setError('Unable to load system monitoring data. Check your connection and try again.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchData();
  }, [fetchData]);

  const refreshData = async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
  };

  const healthEntries = Object.entries(data?.health ?? {});
  const channelEntries = Object.entries(data?.channels ?? {});
  const totalMs = data?.performance?.stages?.total_ms ?? 0;
  const stages = [
    { label: 'Data extraction', ms: data?.performance?.stages?.extraction_ms ?? 0 },
    { label: 'ML inference', ms: data?.performance?.stages?.ml_ms ?? 0 },
    { label: 'RAG retrieval', ms: data?.performance?.stages?.rag_ms ?? 0 },
    { label: 'LLM reasoning', ms: data?.performance?.stages?.llm_ms ?? 0 },
    { label: 'Risk engine', ms: data?.performance?.stages?.risk_engine_ms ?? 0 },
    { label: 'Database I/O', ms: data?.performance?.stages?.database_ms ?? 0 },
  ];
  const confusionMatrix = data?.overview?.model?.confusion_matrix?.matrix;

  return (
    <div className="max-w-7xl mx-auto space-y-6 pb-10">
      <header className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-text-main">System Monitoring</h1>
          <p className="mt-1 text-text-muted">Health, analysis throughput, and model performance.</p>
        </div>
        <button
          onClick={refreshData}
          disabled={loading || refreshing}
          className="inline-flex items-center justify-center gap-2 rounded-lg border border-border-light bg-card px-4 py-2 text-sm font-semibold text-text-secondary shadow-sm hover:bg-background disabled:opacity-50"
        >
          <RefreshCw size={16} className={loading || refreshing ? 'animate-spin' : ''} />
          Refresh metrics
        </button>
      </header>

      {error && (
        <div role="alert" className="flex flex-col gap-3 rounded-xl border border-danger/20 bg-danger/5 p-4 text-sm text-danger sm:flex-row sm:items-center sm:justify-between">
          <span>{error}</span>
          <button onClick={refreshData} className="font-bold underline underline-offset-2">Retry</button>
        </div>
      )}

      {loading && !data ? (
        <div className="flex h-64 items-center justify-center rounded-2xl border border-border-light bg-card">
          <RefreshCw className="animate-spin text-primary" size={32} />
        </div>
      ) : data && (
        <>
          <section aria-label="Service health" className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {healthEntries.map(([name, status]) => {
              const healthy = status.toLowerCase() === 'healthy';
              return (
                <div key={name} className="flex items-center justify-between rounded-xl border border-border-light bg-card p-4 shadow-sm">
                  <div className="flex items-center gap-3">
                    {healthy
                      ? <CheckCircle className="text-success" size={20} />
                      : <AlertTriangle className="text-warning" size={20} />}
                    <span className="font-semibold capitalize text-text-main">{name.replaceAll('_', ' ')}</span>
                  </div>
                  <span className={`rounded-full px-2.5 py-1 text-xs font-bold ${healthy ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning'}`}>
                    {status}
                  </span>
                </div>
              );
            })}
          </section>

          <section className="grid grid-cols-1 gap-6 xl:grid-cols-3">
            <div className="space-y-6 xl:col-span-2">
              <div className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-5 flex items-center gap-2">
                  <Brain className="text-primary" size={22} />
                  <h2 className="text-lg font-bold text-text-main">Model evaluation</h2>
                </div>
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
                  {[
                    { label: 'Classifier accuracy', value: data.overview?.model?.accuracy },
                    { label: 'Scam recall', value: data.overview?.model?.scam_recall },
                    { label: 'RAG Hit@3', value: data.overview?.rag?.hit_at_3 },
                    { label: 'RAG Hit@1', value: data.overview?.rag?.hit_at_1 },
                  ].map((metric) => (
                    <div key={metric.label} className="rounded-xl border border-border-light bg-background p-4">
                      <p className="text-xs font-semibold text-text-muted">{metric.label}</p>
                      <p className="mt-2 text-2xl font-bold text-text-main">
                        {typeof metric.value === 'number' ? `${(metric.value * 100).toFixed(1)}%` : 'N/A'}
                      </p>
                    </div>
                  ))}
                </div>
                <div className="mt-5 rounded-xl border border-border-light bg-background p-4">
                  <h3 className="mb-4 text-sm font-bold text-text-main">Classifier confusion matrix</h3>
                  {confusionMatrix ? (
                    <div className="grid grid-cols-3 gap-2 text-center text-sm">
                      <div className="font-semibold text-text-muted">Actual / Predicted</div>
                      <div className="font-semibold text-text-secondary">Genuine</div>
                      <div className="font-semibold text-text-secondary">Scam</div>
                      <div className="font-semibold text-text-secondary">Genuine</div>
                      <div className="rounded-lg bg-success/10 py-2 font-bold text-success">{confusionMatrix[0][0]}</div>
                      <div className="rounded-lg bg-danger/10 py-2 font-bold text-danger">{confusionMatrix[0][1]}</div>
                      <div className="font-semibold text-text-secondary">Scam</div>
                      <div className="rounded-lg bg-danger/10 py-2 font-bold text-danger">{confusionMatrix[1][0]}</div>
                      <div className="rounded-lg bg-success/10 py-2 font-bold text-success">{confusionMatrix[1][1]}</div>
                    </div>
                  ) : (
                    <p className="text-sm text-text-muted">Evaluation matrix is not available.</p>
                  )}
                </div>
              </div>

              <div className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-5 flex items-center gap-2">
                  <ShieldCheck className="text-primary" size={22} />
                  <h2 className="text-lg font-bold text-text-main">Analysis channels</h2>
                </div>
                {channelEntries.length === 0 ? (
                  <p className="rounded-xl bg-background p-5 text-sm text-text-muted">No channel performance has been recorded yet.</p>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm">
                      <thead className="border-b border-border-light text-xs uppercase text-text-muted">
                        <tr>
                          <th className="py-3 pr-4">Channel</th>
                          <th className="py-3 px-4">Analyses</th>
                          <th className="py-3 px-4">Success rate</th>
                          <th className="py-3 pl-4 text-right">Avg. latency</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-border-light">
                        {channelEntries.map(([channel, metrics]) => (
                          <tr key={channel}>
                            <td className="py-3 pr-4 font-semibold uppercase text-text-main">{channel}</td>
                            <td className="py-3 px-4 text-text-secondary">{metrics.count}</td>
                            <td className="py-3 px-4 text-text-secondary">{(metrics.success_rate * 100).toFixed(1)}%</td>
                            <td className="py-3 pl-4 text-right text-text-secondary">{Math.round(metrics.average_latency_ms)} ms</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>

            <aside className="space-y-6">
              <div className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-5 flex items-center gap-2">
                  <Clock className="text-primary" size={22} />
                  <h2 className="text-lg font-bold text-text-main">Average latency</h2>
                </div>
                <p className="mb-5 text-3xl font-bold text-text-main">
                  {Math.round(totalMs)} <span className="text-base font-medium text-text-muted">ms total</span>
                </p>
                <div className="space-y-4">
                  {stages.map((stage) => (
                    <div key={stage.label}>
                      <div className="mb-1 flex justify-between gap-3 text-xs">
                        <span className="text-text-secondary">{stage.label}</span>
                        <span className="font-semibold text-text-main">{Math.round(stage.ms)} ms</span>
                      </div>
                      <div className="h-2 overflow-hidden rounded-full bg-background">
                        <div
                          className="h-full rounded-full bg-primary"
                          style={{ width: `${totalMs ? Math.min((stage.ms / totalMs) * 100, 100) : 0}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
                <div className="mt-6 space-y-3 border-t border-border-light pt-5 text-sm">
                  <div className="flex justify-between gap-3">
                    <span className="text-text-muted">LLM success rate</span>
                    <span className="font-bold text-text-main">
                      {typeof data.overview?.llm?.success_rate === 'number'
                        ? `${(data.overview.llm.success_rate * 100).toFixed(1)}%`
                        : 'N/A'}
                    </span>
                  </div>
                  <div className="flex justify-between gap-3">
                    <span className="text-text-muted">Total analyses</span>
                    <span className="font-bold text-text-main">{data.overview?.system?.total_analyses ?? 0}</span>
                  </div>
                </div>
              </div>

              <div className="rounded-2xl border border-border-light bg-card p-6 shadow-sm">
                <div className="mb-3 flex items-center gap-2">
                  <Server className="text-primary" size={20} />
                  <h2 className="font-bold text-text-main">Service status</h2>
                </div>
                <p className="text-sm leading-relaxed text-text-muted">
                  Health is reported by the monitoring API. A service marked “Not Configured” is not necessarily down; it may require an integration setting such as an LLM key.
                </p>
              </div>
            </aside>
          </section>
        </>
      )}
    </div>
  );
};

export default MonitoringDashboard;

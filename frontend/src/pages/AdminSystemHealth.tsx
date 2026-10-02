import React, { useCallback, useEffect, useState } from 'react';
import { 
  Database, Server, Activity, ArrowUpCircle, XCircle, Clock, RefreshCw
} from 'lucide-react';
import { api } from '../services/api';

export default function AdminSystemHealth() {
  const [health, setHealth] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  const fetchHealth = useCallback(async () => {
    setRefreshing(true);
    try {
      // don't set loading to true on subsequent calls to avoid flicker
      const response = await api.get('/admin/health');
      setHealth(response.data);
      setError(null);
    } catch (err) {
      setError('Failed to load system health');
      console.error(err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    void fetchHealth();
    const interval = setInterval(() => void fetchHealth(), 30000);
    return () => clearInterval(interval);
  }, [fetchHealth]);

  const getStatusIcon = (status: string) => {
    return status === 'up' 
      ? <ArrowUpCircle className="w-6 h-6 text-success" /> 
      : <XCircle className="w-6 h-6 text-danger" />;
  };

  if (loading && !health) {
    return (
      <div className="flex justify-center py-20">
        <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-5xl mx-auto pb-10">
      
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-1">System Health</h1>
          <p className="text-text-muted">Real-time status of ScamShield services and integrations.</p>
        </div>
        <div className="flex items-center gap-3">
          {health && (
            <div className="flex items-center text-xs text-text-muted bg-background border border-border-light px-3 py-1.5 rounded-lg shadow-sm">
              <Clock className="w-3.5 h-3.5 mr-1.5" />
              Last Updated: {new Date(health.system_time).toLocaleTimeString()}
            </div>
          )}
          <button
            onClick={fetchHealth}
            disabled={refreshing}
            className="inline-flex items-center gap-2 rounded-lg border border-border-light bg-card px-3 py-2 text-sm font-semibold text-text-secondary hover:bg-background disabled:opacity-50"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>
      </div>

      {error ? (
        <div className="p-12 text-center bg-danger/10 text-danger border border-danger/20 rounded-2xl font-medium">
          <p>{error}</p>
          <button onClick={fetchHealth} className="mt-3 underline underline-offset-2">Retry</button>
        </div>
      ) : health ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          
          <div className="bg-card rounded-xl shadow-sm border border-border-light p-6 flex flex-col items-center text-center">
            <div className="mb-4 bg-background p-3 rounded-full border border-border-light">
              <Database className="w-6 h-6 text-primary" />
            </div>
            <h3 className="font-bold text-text-main mb-1">PostgreSQL DB</h3>
            <div className="flex items-center gap-2 mb-2">
              {getStatusIcon(health.database.status)}
              <span className="text-sm font-semibold uppercase tracking-wider text-text-secondary">{health.database.status}</span>
            </div>
            <p className="text-xs text-text-muted font-mono">Latency: {health.database.latency}</p>
          </div>

          <div className="bg-card rounded-xl shadow-sm border border-border-light p-6 flex flex-col items-center text-center">
            <div className="mb-4 bg-background p-3 rounded-full border border-border-light">
              <Server className="w-6 h-6 text-primary" />
            </div>
            <h3 className="font-bold text-text-main mb-1">ML Engine</h3>
            <div className="flex items-center gap-2 mb-2">
              {getStatusIcon(health.ml_engine.status)}
              <span className="text-sm font-semibold uppercase tracking-wider text-text-secondary">{health.ml_engine.status}</span>
            </div>
            <p className="text-xs text-text-muted font-mono">Latency: {health.ml_engine.latency}</p>
          </div>

          <div className="bg-card rounded-xl shadow-sm border border-border-light p-6 flex flex-col items-center text-center">
            <div className="mb-4 bg-background p-3 rounded-full border border-border-light">
              <Activity className="w-6 h-6 text-primary" />
            </div>
            <h3 className="font-bold text-text-main mb-1">RAG Service</h3>
            <div className="flex items-center gap-2 mb-2">
              {getStatusIcon(health.rag_service.status)}
              <span className="text-sm font-semibold uppercase tracking-wider text-text-secondary">{health.rag_service.status}</span>
            </div>
            <p className="text-xs text-text-muted font-mono">Latency: {health.rag_service.latency}</p>
          </div>

          <div className="bg-card rounded-xl shadow-sm border border-border-light p-6 flex flex-col items-center text-center">
            <div className="mb-4 bg-background p-3 rounded-full border border-border-light">
              <Server className="w-6 h-6 text-primary" />
            </div>
            <h3 className="font-bold text-text-main mb-1">Jira Integration</h3>
            <div className="flex items-center gap-2 mb-2">
              {getStatusIcon(health.jira_integration.status)}
              <span className="text-sm font-semibold uppercase tracking-wider text-text-secondary">{health.jira_integration.status}</span>
            </div>
            <p className="text-xs text-text-muted font-mono">Status: {health.jira_integration.status === 'up' ? 'Enabled' : 'Not Configured'}</p>
          </div>

        </div>
      ) : null}

    </div>
  );
}

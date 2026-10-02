import React, { useCallback, useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { 
  ArrowLeft, FileText, AlertTriangle, ShieldCheck, 
  Database, BrainCircuit, ActivitySquare
} from 'lucide-react';
import { api } from '../services/api';

export default function AdminAnalysisDetails() {
  const { id } = useParams();
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDetails = useCallback(async () => {
    try {
      setLoading(true);
      const res = await api.get(`/admin/analyses/${id}`);
      setData(res.data);
      setError(null);
    } catch (err) {
      console.error(err);
      setError('Failed to load analysis details');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    void fetchDetails();
  }, [fetchDetails]);

  if (loading) {
    return (
      <div className="flex justify-center py-20">
        <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="text-center py-20 text-danger font-medium">{error}</div>
    );
  }

  const { analysis, user, performance, evidence } = data;

  const getRiskColor = (level: string) => {
    switch (level) {
      case 'CRITICAL': return 'bg-danger/20 text-danger border-danger/30';
      case 'HIGH': return 'bg-danger/10 text-danger border-danger/20';
      case 'MEDIUM': return 'bg-warning/10 text-warning border-warning/20';
      case 'LOW': return 'bg-success/10 text-success border-success/20';
      default: return 'bg-background text-text-muted';
    }
  };

  return (
    <div className="space-y-6 max-w-5xl mx-auto pb-10">
      
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <Link to="/admin/analyses" className="p-2 border border-border-light rounded-lg text-text-secondary hover:bg-background transition-colors">
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-text-main flex items-center space-x-3">
              <span>Analysis #{analysis.id}</span>
              <span className={`text-xs font-bold px-2 py-1 rounded border ${getRiskColor(analysis.risk_level)}`}>
                {analysis.risk_level} RISK
              </span>
            </h1>
            <p className="text-sm text-text-muted">Analyzed on {new Date(analysis.created_at).toLocaleString()}</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Main Content Area */}
        <div className="md:col-span-2 space-y-6">
          
          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
            <div className="flex items-center space-x-2 mb-4">
              <FileText className="w-5 h-5 text-primary" />
              <h2 className="text-lg font-bold text-text-main">Original Content</h2>
              <span className="ml-auto text-[10px] font-bold px-2 py-0.5 uppercase tracking-wider bg-background border border-border-light rounded text-text-muted">
                {analysis.input_type}
              </span>
            </div>
            <div className="bg-background rounded-xl p-4 border border-border-light">
              <p className="text-sm text-text-secondary font-mono whitespace-pre-wrap break-all max-h-64 overflow-y-auto custom-scrollbar">
                {analysis.original_text || 'No source content was retained for this analysis.'}
              </p>
            </div>
          </div>

          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-2">
                <BrainCircuit className="w-5 h-5 text-primary" />
                <h2 className="text-lg font-bold text-text-main">AI Assessment</h2>
              </div>
            </div>
            
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div className="bg-background rounded-xl p-4 border border-border-light">
                <p className="text-[11px] font-bold text-text-muted uppercase tracking-wider mb-1">ML Model</p>
                <div className="text-lg font-bold text-text-main mb-1">{analysis.classification}</div>
                <div className="text-xs text-text-secondary">Confidence: <span className="font-semibold">{typeof analysis.ml_probability === 'number' ? `${(analysis.ml_probability * 100).toFixed(1)}%` : 'N/A'}</span></div>
              </div>
              <div className="bg-background rounded-xl p-4 border border-border-light">
                <p className="text-[11px] font-bold text-text-muted uppercase tracking-wider mb-1">Risk Engine</p>
                <div className="text-lg font-bold text-text-main mb-1">{analysis.category || 'Unknown'}</div>
                <div className="text-xs text-text-secondary">Risk Score: <span className="font-semibold">{analysis.risk_score}/100</span></div>
              </div>
            </div>

            {analysis.indicators && analysis.indicators.length > 0 && (
              <div>
                <p className="text-[11px] font-bold text-text-muted uppercase tracking-wider mb-2">Detected Indicators</p>
                <ul className="space-y-2">
                  {analysis.indicators.map((ind: string, idx: number) => (
                    <li key={idx} className="flex items-start text-sm text-text-secondary bg-danger/5 border border-danger/10 p-2.5 rounded-lg">
                      <AlertTriangle className="w-4 h-4 text-danger mr-2 mt-0.5 shrink-0" />
                      <span>{ind}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
            {analysis.recommended_action && (
              <div className="mt-5 rounded-xl border border-primary/20 bg-primary/5 p-4">
                <p className="mb-1 text-[11px] font-bold uppercase tracking-wider text-primary">Recommended Action</p>
                <p className="text-sm text-text-secondary">{analysis.recommended_action}</p>
              </div>
            )}
          </div>

          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
            <div className="flex items-center space-x-2 mb-4">
              <Database className="w-5 h-5 text-primary" />
              <h2 className="text-lg font-bold text-text-main">RAG Evidence</h2>
            </div>
            
            {evidence && evidence.length > 0 ? (
              <div className="space-y-3">
                {evidence.map((ev: any) => (
                  <div key={ev.id} className="bg-background rounded-xl p-4 border border-border-light">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-[10px] font-bold uppercase tracking-wider text-text-muted">{ev.type}</span>
                      <span className="text-xs font-semibold text-primary">Sim: {(ev.similarity_score * 100).toFixed(1)}%</span>
                    </div>
                    <p className="text-sm text-text-secondary italic">"{ev.content}"</p>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-6 text-text-muted bg-background rounded-xl border border-border-light">
                <ShieldCheck className="w-8 h-8 opacity-20 mx-auto mb-2" />
                <p className="text-sm font-medium">No matching evidence found in knowledge base</p>
              </div>
            )}
          </div>

        </div>

        {/* Sidebar Info Area */}
        <div className="space-y-6">
          
          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
            <h3 className="text-sm font-bold text-text-main uppercase tracking-wider mb-4 border-b border-border-light pb-2">Analysis Info</h3>
            <div className="space-y-4">
              <div>
                <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider mb-1">Status</p>
                <p className="text-sm font-semibold text-success">{analysis.processing_status}</p>
              </div>
              <div>
                <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider mb-1">User</p>
                <div className="text-sm text-text-main">
                  {user ? (
                    <div>
                      <p className="font-semibold">{user.full_name || 'User'}</p>
                      <p className="text-xs text-text-muted">{user.email}</p>
                      <p className="text-xs text-text-muted mt-1">ID: {user.id}</p>
                    </div>
                  ) : (
                    <span className="text-text-muted italic">System / Unknown</span>
                  )}
                </div>
              </div>
              <div>
                <p className="text-[10px] font-bold text-text-muted uppercase tracking-wider mb-1">LLM Confidence</p>
                <p className="text-sm font-semibold text-text-main">
                  {analysis.llm_confidence ? `${(analysis.llm_confidence * 100).toFixed(1)}%` : 'N/A'}
                </p>
              </div>
            </div>
          </div>

          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
            <h3 className="text-sm font-bold text-text-main uppercase tracking-wider mb-4 border-b border-border-light pb-2 flex items-center justify-between">
              Performance
              <ActivitySquare className="w-4 h-4 text-text-muted" />
            </h3>
            {performance ? (
              <div className="space-y-3">
                <div className="flex justify-between items-center text-sm">
                  <span className="text-text-secondary">Extraction</span>
                  <span className="font-mono text-text-main">{Number(performance.extraction_ms ?? 0).toFixed(0)}ms</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-text-secondary">ML Model</span>
                  <span className="font-mono text-text-main">{Number(performance.ml_ms ?? 0).toFixed(0)}ms</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-text-secondary">RAG Retrieval</span>
                  <span className="font-mono text-text-main">{Number(performance.rag_ms ?? 0).toFixed(0)}ms</span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-text-secondary">LLM Engine</span>
                  <span className="font-mono text-text-main">{Number(performance.llm_ms ?? 0).toFixed(0)}ms</span>
                </div>
                <div className="pt-2 mt-2 border-t border-border-light flex justify-between items-center font-bold text-sm">
                  <span className="text-text-main">Total Processing</span>
                  <span className="font-mono text-primary">{Number(performance.total_ms ?? 0).toFixed(0)}ms</span>
                </div>
              </div>
            ) : (
              <p className="text-xs text-text-muted italic">Performance data unavailable.</p>
            )}
          </div>

        </div>

      </div>

    </div>
  );
}

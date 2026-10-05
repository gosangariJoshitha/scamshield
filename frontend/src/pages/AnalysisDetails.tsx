import { useEffect, useState } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import { 
  ArrowLeft, ChevronDown, ChevronUp, Sparkles, Activity, 
  Database, ShieldCheck, Fingerprint, FileText
} from 'lucide-react';
import { analysisService, type AnalysisResult } from '../services/analysis';
import RecommendedActions from '../components/RecommendedActions';

type AnalysisItem = AnalysisResult;

export default function AnalysisDetails() {
  const location = useLocation();
  const navigate = useNavigate();
  const { id } = useParams();
  const routeAnalysisId = Number(id);
  const possibleStateResult = location.state?.result as AnalysisItem | undefined;
  const stateResult = possibleStateResult?.id === routeAnalysisId ? possibleStateResult : undefined;
  const [result, setResult] = useState<AnalysisItem | undefined>(stateResult);
  const [loading, setLoading] = useState(!stateResult);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [expandedSection, setExpandedSection] = useState<string>('');
  const [showFullReasoning, setShowFullReasoning] = useState(false);
  const [showAllEvidence, setShowAllEvidence] = useState(false);

  useEffect(() => {
    if (stateResult) {
      setResult(stateResult);
      setLoadError(null);
      setLoading(false);
      return;
    }

    if (!Number.isInteger(routeAnalysisId) || routeAnalysisId <= 0) {
      setResult(undefined);
      setLoadError('This analysis link is invalid.');
      setLoading(false);
      return;
    }

    let active = true;
    setResult(undefined);
    setLoadError(null);
    setLoading(true);
    analysisService.getAnalysis(routeAnalysisId)
      .then(data => {
        if (active) setResult(data);
      })
      .catch(error => {
        console.error('Failed to load analysis details', error);
        if (active) setLoadError('Unable to load this analysis. It may not exist or may not belong to your account.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => { active = false; };
  }, [id, stateResult, routeAnalysisId]);

  if (loading) {
    return <div className="p-8 text-center text-text-muted" role="status">Loading analysis details…</div>;
  }
  if (!result) {
    return (
      <div className="space-y-4 rounded-2xl border border-border-light bg-card p-8 text-center">
        <p className="font-semibold text-text-main">{loadError || 'Analysis not found.'}</p>
        <button onClick={() => navigate('/history')} className="rounded-lg bg-primary px-4 py-2 font-semibold text-white">
          Back to history
        </button>
      </div>
    );
  }

  const isScam = result.classification === 'SCAM';
  const riskColor = result.risk_level === 'HIGH' || result.risk_level === 'CRITICAL' ? 'red' : 
                   result.risk_level === 'MEDIUM' ? 'orange' : 'green';

  return (
    <div className="space-y-6 max-w-6xl mx-auto pb-10">
      {/* Step Indicator */}
      <div className="flex items-center justify-center space-x-4 mb-4">
        <div className="flex items-center space-x-2 text-text-muted font-bold text-sm">
          <div className="w-6 h-6 rounded-full bg-primary/20 text-primary flex items-center justify-center text-xs">
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <span>Overview</span>
        </div>
        <div className="w-16 h-px bg-border-main hidden @content-sm:block"></div>
        <div className="flex items-center space-x-2 text-primary font-bold text-sm">
          <div className="w-6 h-6 rounded-full bg-primary text-white flex items-center justify-center text-xs">2</div>
          <span>Detailed Analysis</span>
        </div>
      </div>

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <button 
            onClick={() => navigate('/history')}
            className="flex items-center space-x-2 text-text-muted hover:text-text-main transition mb-4 text-sm font-bold"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to History</span>
          </button>
          <h1 className="text-3xl font-bold text-text-main mb-1">Detailed AI Analysis</h1>
          <p className="text-text-muted text-base max-w-2xl">
            Understand the signals, model prediction, retrieved evidence and reasoning behind this result.
          </p>
        </div>
      </div>

      {/* Context Bar */}
      <div className="flex items-center justify-between rounded-xl border border-border-light bg-background p-4 shadow-sm">
        <div className="flex items-center space-x-4">
          <div className={`w-12 h-12 rounded-full flex items-center justify-center shrink-0 border ${riskColor === 'red' ? 'bg-danger/10 border-danger/30 text-danger' : riskColor === 'orange' ? 'bg-warning/10 border-warning/30 text-warning' : 'bg-success/10 border-success/30 text-success'}`}>
            <span className="font-bold text-lg leading-none">{result.risk_score}</span>
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider ${riskColor === 'red' ? 'bg-danger text-white' : riskColor === 'orange' ? 'bg-warning text-white' : 'bg-success text-white'}`}>
                {result.risk_level} RISK
              </span>
              <span className="font-bold text-text-main">{result.classification}</span>
            </div>
            <p className="text-sm text-text-muted mt-0.5">{result.category || 'Unknown Pattern'}</p>
          </div>
        </div>
        <div className="hidden @content-sm:block">
           <button 
            onClick={() => navigate(`/results/${result.id}`, { state: { result } })}
            className="text-sm font-bold text-primary hover:text-primary-hover px-4 py-2 border border-border-light rounded-lg bg-card"
          >
            Overview
          </button>
        </div>
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 gap-8 @content-lg:grid-cols-12">
        
        {/* Left Column */}
        <div className="@content-lg:col-span-7 space-y-6">
          
          {/* AI Analysis & Reasoning */}
          <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
            <div className="bg-gradient-to-r from-primary/10 to-transparent p-6 border-b border-border-light relative overflow-hidden">
              <Sparkles className="absolute -right-4 -bottom-4 w-24 h-24 text-primary/10" />
              <div className="flex items-center space-x-3 mb-2 relative z-10">
                <div className="bg-primary text-white p-1.5 rounded-lg">
                  <Fingerprint className="w-5 h-5" />
                </div>
                <h2 className="text-xl font-bold text-text-main">AI Analysis & Reasoning</h2>
              </div>
              <p className="text-sm text-text-muted relative z-10">Why this content was classified as risky</p>
            </div>
            
            <div className="p-6">
              {result.llm_reasoning || result.explanation ? (
                <>
                  <div className="prose prose-sm dark:prose-invert max-w-none break-words text-text-secondary leading-relaxed mb-4 [overflow-wrap:anywhere]">
                    <p className={`text-[15px] ${showFullReasoning ? '' : 'line-clamp-6'}`}>{result.llm_reasoning || result.explanation}</p>
                  </div>
                  {(result.llm_reasoning || result.explanation).length > 650 && (
                    <button
                      type="button"
                      onClick={() => setShowFullReasoning((expanded) => !expanded)}
                      className="mb-5 text-sm font-semibold text-primary hover:text-primary-hover"
                    >
                      {showFullReasoning ? 'Show less reasoning' : 'Read full reasoning'}
                    </button>
                  )}
                  
                  {result.indicators && result.indicators.length > 0 && (
                    <div className="bg-background border border-border-light rounded-xl p-5">
                      <h4 className="text-sm font-bold text-text-main mb-3 uppercase tracking-wider">Key Reasoning</h4>
                      <ul className="space-y-2">
                        {result.indicators.map((ind, i) => (
                          <li key={i} className="flex items-start space-x-2 text-sm text-text-secondary">
                            <span className="text-primary mt-1">•</span>
                            <span>{ind}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                </>
              ) : (
                <div className="rounded-xl border border-warning/20 bg-warning/10 p-4 text-sm text-text-secondary">
                  <p className="font-semibold text-warning">AI explanation was not generated for this analysis.</p>
                  <p className="mt-1">The ML classification and retrieved evidence are still available. If this keeps happening, ask an administrator to check the OpenRouter configuration and backend logs.</p>
                </div>
              )}
            </div>
          </div>

          {/* ML Prediction (Collapsible) */}
          <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
            <button 
              onClick={() => setExpandedSection(expandedSection === 'ml' ? '' : 'ml')}
              className="w-full flex items-center justify-between p-5 @content-sm:p-6 bg-background hover:bg-card transition text-left group"
            >
              <div className="flex items-center space-x-4">
                <div className="w-10 h-10 rounded-xl bg-background border border-border-light flex items-center justify-center text-text-muted group-hover:text-primary transition-colors">
                  <Activity className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-base text-text-main">ML Prediction</h3>
                  <div className="flex items-center space-x-2 mt-1">
                    <span className="text-xs text-text-muted">Model: {result.model_version || 'scamshield-classifier-v1'}</span>
                  </div>
                </div>
              </div>
              <div className="flex items-center space-x-4">
                <span className={`text-xs font-bold px-2 py-1 rounded bg-background border border-border-light uppercase tracking-wider ${isScam ? 'text-danger' : 'text-success'}`}>
                  {Math.round(result.ml_probability * 100)}% {isScam ? 'scam' : 'genuine'}
                </span>
                {expandedSection === 'ml' ? <ChevronUp className="w-5 h-5 text-text-muted" /> : <ChevronDown className="w-5 h-5 text-text-muted" />}
              </div>
            </button>
            
            {expandedSection === 'ml' && (
              <div className="p-6 border-t border-border-light bg-card">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <div className="text-[10px] uppercase font-bold text-text-muted tracking-wider mb-1">Architecture</div>
                    <div className="text-sm font-semibold text-text-main">TF-IDF + Logistic Regression</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-text-muted tracking-wider mb-1">Prediction</div>
                    <div className={`text-sm font-semibold ${isScam ? 'text-danger' : 'text-success'}`}>{result.classification}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-text-muted tracking-wider mb-1">Scam Probability</div>
                    <div className="text-sm font-semibold text-text-main">{Math.round(result.ml_probability * 100)}%</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-text-muted tracking-wider mb-1">Version</div>
                    <div className="text-sm font-semibold text-text-main">{result.model_version || 'v1.0.0'}</div>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Analysis Details (Collapsible) */}
          <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
            <button 
              onClick={() => setExpandedSection(expandedSection === 'details' ? '' : 'details')}
              className="w-full flex items-center justify-between p-5 @content-sm:p-6 bg-background hover:bg-card transition text-left group"
            >
              <div className="flex items-center space-x-4">
                <div className="w-10 h-10 rounded-xl bg-background border border-border-light flex items-center justify-center text-text-muted group-hover:text-primary transition-colors">
                  <FileText className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-base text-text-main">Analysis Details</h3>
                  <p className="text-xs text-text-muted mt-1">Technical metadata</p>
                </div>
              </div>
              <ChevronDown className={`w-5 h-5 text-text-muted transition-transform ${expandedSection === 'details' ? 'rotate-180' : ''}`} />
            </button>
            
            {expandedSection === 'details' && (
              <div className="p-6 border-t border-border-light bg-card">
                <div className="grid grid-cols-2 @content-sm:grid-cols-3 gap-6">
                  <div>
                    <div className="text-[10px] uppercase font-bold text-text-muted tracking-wider mb-1">Analysis ID</div>
                    <div className="text-sm font-semibold text-text-main">#ANL_{result.id}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-text-muted tracking-wider mb-1">Created At</div>
                    <div className="text-sm font-semibold text-text-main">{new Date(result.created_at).toLocaleString()}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-text-muted tracking-wider mb-1">Input Type</div>
                    <div className="text-sm font-semibold text-text-main capitalize">{result.input_type || 'Text'}</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-text-muted tracking-wider mb-1">Language</div>
                    <div className="text-sm font-semibold text-text-main">English</div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase font-bold text-text-muted tracking-wider mb-1">Status</div>
                    <div className="text-sm font-semibold text-success">{result.processing_status || 'COMPLETED'}</div>
                  </div>
                  {result.llm_confidence != null && (
                    <div>
                      <div className="text-[10px] uppercase font-bold text-text-muted tracking-wider mb-1">LLM Confidence</div>
                      <div className="text-sm font-semibold text-text-main">{Math.round(result.llm_confidence * 100)}%</div>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Right Column */}
        <div className="min-w-0 space-y-6 @content-lg:col-span-5">
          
          {/* Retrieved Evidence */}
          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
            <div className="flex items-center space-x-3 mb-6">
              <div className="w-10 h-10 rounded-xl bg-primary/10 text-primary flex items-center justify-center">
                <Database className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-bold text-lg text-text-main">Retrieved Evidence</h3>
                <p className="text-xs text-text-muted">Similar scam patterns from the ScamShield knowledge base</p>
              </div>
            </div>

            <div className="space-y-4">
              {result.retrieved_evidence_data && result.retrieved_evidence_data.length > 0 ? (
                result.retrieved_evidence_data.slice(
                  0,
                  showAllEvidence ? result.retrieved_evidence_data.length : 2,
                ).map((item, idx) => (
                  <div key={idx} className="min-w-0 border border-border-light rounded-xl p-4 bg-background">
                    <div className="flex min-w-0 items-start justify-between gap-3 mb-2">
                      <h4 className="min-w-0 break-words font-bold text-sm text-text-main [overflow-wrap:anywhere]">{item.title || 'Known Pattern'}</h4>
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-background border border-border-light text-text-secondary shrink-0 whitespace-nowrap">
                        Similarity: {Math.round(item.similarity_score * 100)}%
                      </span>
                    </div>
                    <div className="flex min-w-0 flex-wrap items-center gap-2 break-words text-xs text-text-muted mb-3 [overflow-wrap:anywhere]">
                      <span className="bg-border-light/50 px-2 py-0.5 rounded">{item.category || 'Scam'}</span>
                      <span>•</span>
                      <span>{item.source || 'ScamShield Knowledge Base'}</span>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center p-8 bg-background border border-border-light border-dashed rounded-xl">
                  <Database className="w-8 h-8 text-text-muted/30 mx-auto mb-3" />
                  <p className="text-sm text-text-muted">No sufficiently similar scam patterns were found.</p>
                </div>
              )}
              {result.retrieved_evidence_data && result.retrieved_evidence_data.length > 2 && (
                <button
                  type="button"
                  onClick={() => setShowAllEvidence((expanded) => !expanded)}
                  className="text-sm font-semibold text-primary hover:text-primary-hover"
                >
                  {showAllEvidence ? 'Show fewer matches' : `Show ${result.retrieved_evidence_data.length - 2} more matches`}
                </button>
              )}
            </div>
          </div>

        </div>
      </div>

      <section className="w-full rounded-2xl border border-border-light bg-card p-6 shadow-sm @content-sm:p-8">
        <div className="mb-6 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-success/10 text-success">
            <ShieldCheck className="h-5 w-5" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-text-main">What You Should Do</h3>
            <p className="text-xs text-text-muted">Recommended steps, one action per line</p>
          </div>
        </div>
        <RecommendedActions
          key={result.id}
          recommendedAction={result.recommended_action}
          safeActions={result.safe_actions}
          analyzedText={result.original_text || result.content}
        />
      </section>
    </div>
  );
}

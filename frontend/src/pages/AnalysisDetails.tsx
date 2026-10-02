import { useEffect, useState } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import { 
  ArrowLeft, ChevronDown, ChevronUp, Sparkles, Activity, 
  Database, ShieldCheck, Fingerprint, FileText
} from 'lucide-react';
import { analysisService, type AnalysisResult } from '../services/analysis';

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

  const formatResolutionSteps = (text: string) => {
    // If backend returns numbered steps naturally, or we split by sentences
    const steps = text.split(/(?:\d+\. )|(?:\n)/).filter(s => s.trim().length > 5);
    if (steps.length === 0) return [text];
    return steps;
  };

  const resolutionSteps = formatResolutionSteps(result.recommended_action);

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
        <div className="w-16 h-px bg-border-main hidden sm:block"></div>
        <div className="flex items-center space-x-2 text-primary font-bold text-sm">
          <div className="w-6 h-6 rounded-full bg-primary text-white flex items-center justify-center text-xs">2</div>
          <span>Detailed Analysis</span>
        </div>
      </div>

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <button 
            onClick={() => navigate(`/results/${result.id}`, { state: { result } })}
            className="flex items-center space-x-2 text-text-muted hover:text-text-main transition mb-4 text-sm font-bold"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Overview</span>
          </button>
          <h1 className="text-3xl font-bold text-text-main mb-1">Detailed AI Analysis</h1>
          <p className="text-text-muted text-base max-w-2xl">
            Understand the signals, model prediction, retrieved evidence and reasoning behind this result.
          </p>
        </div>
      </div>

      {/* Context Bar */}
      <div className="sticky top-[73px] z-20 bg-background/95 backdrop-blur-md border border-border-light rounded-xl shadow-sm p-4 flex items-center justify-between mb-8">
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
        <div className="hidden sm:block">
           <button 
            onClick={() => navigate(`/results/${result.id}`, { state: { result } })}
            className="text-sm font-bold text-primary hover:text-primary-hover px-4 py-2 border border-border-light rounded-lg bg-card"
          >
            Overview
          </button>
        </div>
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 relative z-10">
        
        {/* Left Column */}
        <div className="lg:col-span-7 space-y-6">
          
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
                  <div className="prose prose-sm dark:prose-invert max-w-none text-text-secondary leading-relaxed mb-6">
                    <p className="text-[15px]">{result.llm_reasoning || result.explanation}</p>
                  </div>
                  
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
                <div className="text-warning text-sm font-semibold p-4 bg-warning/10 rounded-xl border border-warning/20">
                  AI explanation is temporarily unavailable. The classification and evidence-based assessment are still valid.
                </div>
              )}
            </div>
          </div>

          {/* ML Prediction (Collapsible) */}
          <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
            <button 
              onClick={() => setExpandedSection(expandedSection === 'ml' ? '' : 'ml')}
              className="w-full flex items-center justify-between p-5 sm:p-6 bg-background hover:bg-card transition text-left group"
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
              className="w-full flex items-center justify-between p-5 sm:p-6 bg-background hover:bg-card transition text-left group"
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
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-6">
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
        <div className="lg:col-span-5 space-y-6">
          
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
                result.retrieved_evidence_data.map((item, idx) => (
                  <div key={idx} className="border border-border-light rounded-xl p-4 bg-background">
                    <div className="flex items-start justify-between mb-2">
                      <h4 className="font-bold text-sm text-text-main pr-4">{item.title || 'Known Pattern'}</h4>
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-background border border-border-light text-text-secondary shrink-0 whitespace-nowrap">
                        Similarity: {Math.round(item.similarity_score * 100)}%
                      </span>
                    </div>
                    <div className="text-xs text-text-muted mb-3 flex items-center space-x-2">
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
            </div>
          </div>

          {/* What You Should Do */}
          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
            <div className="flex items-center space-x-3 mb-6">
              <div className="w-10 h-10 rounded-xl bg-success/10 text-success flex items-center justify-center">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-bold text-lg text-text-main">What You Should Do</h3>
                <p className="text-xs text-text-muted">Resolution steps</p>
              </div>
            </div>

            <div className="space-y-4">
              {resolutionSteps.map((step, idx) => (
                <div key={idx} className="flex items-start space-x-4">
                  <div className="w-7 h-7 rounded-full bg-background border border-border-light flex items-center justify-center shrink-0 mt-0.5">
                    <span className="text-xs font-bold text-text-muted">0{idx + 1}</span>
                  </div>
                  <p className="text-sm text-text-secondary pt-1 leading-relaxed">
                    {step.trim()}
                  </p>
                </div>
              ))}
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

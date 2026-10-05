import { useLocation, useNavigate, useParams } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { 
  AlertTriangle, CheckCircle, FileText, Download, Plus, Clock,
  Activity, AlertCircle, MessageSquare, ArrowRight, ShieldAlert,
  ShieldCheck, FileImage, Headphones, File
} from 'lucide-react';
import { PieChart, Pie, Cell } from 'recharts';
import { analysisService, type AnalysisResult } from '../services/analysis';
import { formatRecommendedActions } from '../utils/formatRecommendedActions';
import RecommendedActions from '../components/RecommendedActions';
import { communityService } from '../services/community';

type AnalysisItem = AnalysisResult & {
  original_text?: string | null;
};

export default function AnalysisOverview() {
  const location = useLocation();
  const navigate = useNavigate();
  const { id } = useParams();
  const routeAnalysisId = Number(id);
  const possibleStateResult = location.state?.result as AnalysisItem | undefined;
  const stateResult = possibleStateResult?.id === routeAnalysisId ? possibleStateResult : undefined;
  const analysisCreated = location.state?.analysisCreated === true;
  const [result, setResult] = useState<AnalysisItem | undefined>(stateResult);
  const [loading, setLoading] = useState(!stateResult);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [showAllIndicators, setShowAllIndicators] = useState(false);
  const [reviewRequested, setReviewRequested] = useState(false);
  const [reviewPending, setReviewPending] = useState(false);
  const [communityShareState, setCommunityShareState] = useState<'idle' | 'sending' | 'done'>('idle');
  const [communityShareError, setCommunityShareError] = useState<string | null>(null);
  const [communityPromptDismissed, setCommunityPromptDismissed] = useState(false);

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
        console.error('Failed to load analysis', error);
        if (active) setLoadError('Unable to load this analysis. It may not exist or may not belong to your account.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => { active = false; };
  }, [id, stateResult, routeAnalysisId]);

  useEffect(() => {
    if (!result || (
      result.email_notification_status !== 'PENDING'
      && result.jira_status !== 'PENDING'
    )) {
      return;
    }

    let active = true;
    let attempts = 0;
    let timer: number | undefined;
    const refreshStatuses = async () => {
      if (!active || attempts >= 20) return;
      attempts += 1;
      try {
        const refreshed = await analysisService.getAnalysis(routeAnalysisId);
        if (!active) return;
        setResult((current) => current ? { ...current, ...refreshed } : refreshed);
        if (
          refreshed.email_notification_status === 'PENDING'
          || refreshed.jira_status === 'PENDING'
        ) {
          timer = window.setTimeout(refreshStatuses, 1500);
        }
      } catch (error) {
        console.error('Unable to refresh notification status', error);
        if (active && attempts < 20) timer = window.setTimeout(refreshStatuses, 3000);
      }
    };
    timer = window.setTimeout(refreshStatuses, 1000);
    return () => {
      active = false;
      if (timer !== undefined) window.clearTimeout(timer);
    };
  }, [result?.email_notification_status, result?.jira_status, routeAnalysisId]);

  if (loading) {
    return <div className="p-8 text-center text-text-muted" role="status">Loading analysis…</div>;
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
  const recommendedActions = result.safe_actions?.canonical
    ?? formatRecommendedActions(result.recommended_action);

  const dateStr = new Date(result.created_at).toLocaleString('en-US', {
    month: 'short', day: 'numeric', year: 'numeric', hour: 'numeric', minute: '2-digit'
  });

  const data = [
    { value: result.risk_score },
    { value: 100 - result.risk_score }
  ];
  const COLORS = [
    riskColor === 'red' ? '#DC2626' : riskColor === 'orange' ? '#F59E0B' : '#16A34A',
    '#f1f5f9'
  ];

  const getIconForType = (type: string | undefined) => {
    switch(type) {
      case 'image': return <FileImage className="w-4 h-4" />;
      case 'audio': return <Headphones className="w-4 h-4" />;
      case 'pdf': return <File className="w-4 h-4" />;
      case 'email': return <MessageSquare className="w-4 h-4" />;
      default: return <FileText className="w-4 h-4" />;
    }
  };

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      {analysisCreated && (
        <div
          className="flex items-center gap-2 rounded-xl border border-success/25 bg-success/10 px-4 py-3 text-sm font-semibold text-success"
          role="status"
        >
          <CheckCircle className="h-5 w-5 shrink-0" />
          Analysis created successfully.
        </div>
      )}
      <section className="grid gap-3 rounded-2xl border border-border-light bg-card p-4 shadow-sm @content-sm:grid-cols-2" aria-label="Analysis notifications">
        <div className="rounded-xl bg-background p-4">
          <p className="text-xs font-bold uppercase tracking-wide text-text-muted">Analysis email</p>
          <p className="mt-1 font-semibold text-text-main">
            {result.email_notification_status === 'SENT' ? 'Sent' :
              result.email_notification_status === 'FAILED' ? 'Failed to send' :
                result.email_notification_status === 'PENDING' ? 'Sending…' : 'Not required'}
          </p>
        </div>
        <div className="rounded-xl bg-background p-4">
          <p className="text-xs font-bold uppercase tracking-wide text-text-muted">Jira escalation</p>
          {result.jira_issue_key && result.jira_issue_url ? (
            <a
              href={result.jira_issue_url}
              target="_blank"
              rel="noreferrer"
              className="mt-1 inline-flex font-semibold text-primary hover:text-primary-hover"
            >
              {result.jira_issue_key} · View incident
            </a>
          ) : (
            <p className="mt-1 font-semibold text-text-main">
              {result.jira_status === 'PENDING' ? 'Creating incident…' :
                result.jira_status === 'FAILED' ? 'Incident creation failed' : 'Not required'}
            </p>
          )}
        </div>
      </section>
      {/* Step Indicator */}
      <div className="flex items-center justify-center space-x-4 mb-4">
        <div className="flex items-center space-x-2 text-primary font-bold text-sm">
          <div className="w-6 h-6 rounded-full bg-primary text-white flex items-center justify-center text-xs">1</div>
          <span>Overview</span>
        </div>
        <div className="w-16 h-px bg-border-main hidden @content-sm:block"></div>
        <div className="flex items-center space-x-2 text-text-muted font-bold text-sm">
          <div className="w-6 h-6 rounded-full border-2 border-border-main flex items-center justify-center text-xs">2</div>
          <span>Detailed Analysis</span>
        </div>
      </div>

      {/* Header */}
      <div className="flex flex-col justify-between gap-4 @content-xl:flex-row @content-xl:items-end">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-1">Analysis Result</h1>
          <p className="text-text-muted text-base">Here's what we found and why this content might be risky.</p>
        </div>
        <div className="flex w-full min-w-0 flex-col items-stretch gap-3 @content-xl:w-auto @content-xl:flex-row @content-xl:flex-wrap @content-xl:items-center @content-xl:shrink-0">
          <button 
            onClick={() => {
              const report = `ScamShield Analysis Report\n\nID: ANL_${result.id}\nDate: ${dateStr}\n\nClassification: ${result.classification}\nRisk Score: ${result.risk_score}/100 (${result.risk_level} RISK)\nCategory: ${result.category || 'Unknown'}\nInput Type: ${result.input_type || 'Text'}\n\nAnalyzed Content:\n${result.original_text || result.content}\n\nIndicators:\n${result.indicators.join('\n')}\n\nRecommended Actions:\n${recommendedActions.join('\n')}`;
              const blob = new Blob([report], { type: 'text/plain' });
              const url = URL.createObjectURL(blob);
              const a = document.createElement('a');
              a.href = url;
              a.download = `ScamShield_Report_ANL_${result.id}.txt`;
              document.body.appendChild(a);
              a.click();
              document.body.removeChild(a);
              window.setTimeout(() => URL.revokeObjectURL(url), 1000);
            }}
            className="flex w-full items-center justify-center space-x-2 whitespace-nowrap bg-card border border-border-light hover:border-border-main text-text-secondary font-semibold py-2 px-4 rounded-lg shadow-sm transition @content-xl:w-auto"
          >
            <Download className="w-4 h-4" />
            <span>Download Report</span>
          </button>
          <button 
            disabled={reviewPending || reviewRequested}
            onClick={async () => {
              setReviewPending(true);
              try {
                const { reviewService } = await import('../services/reviewService');
                const res = await reviewService.requestReview(result.id);
                if (!res.success) throw new Error(res.message || 'The review request could not be submitted.');
                setReviewRequested(true);
                alert('Human verification requested successfully. Your request has been sent to the review team.');
              } catch (e) {
                console.error(e);
                alert(e instanceof Error ? e.message : 'Failed to request human verification.');
              } finally {
                setReviewPending(false);
              }
            }}
            className="flex w-full items-center justify-center space-x-2 whitespace-nowrap bg-amber-500 hover:bg-amber-600 disabled:cursor-not-allowed disabled:opacity-60 text-white font-semibold py-2 px-4 rounded-lg shadow-sm transition @content-xl:w-auto"
          >
            {reviewRequested ? <CheckCircle className="w-4 h-4" /> : <ShieldAlert className="w-4 h-4" />}
            <span>{reviewPending ? 'Submitting…' : reviewRequested ? 'Review Requested' : 'Request Human Review'}</span>
          </button>
          <button onClick={() => navigate('/analyze')} className="flex w-full items-center justify-center space-x-2 whitespace-nowrap bg-primary hover:bg-primary-hover text-white font-semibold py-2 px-4 rounded-lg shadow-sm transition @content-xl:w-auto">
            <Plus className="w-4 h-4" />
            <span>Analyze New Content</span>
          </button>
          <button
            type="button"
            onClick={() => navigate('/history')}
            className="flex w-full items-center justify-center gap-2 whitespace-nowrap rounded-lg border border-border-light bg-card px-4 py-2 font-semibold text-text-secondary shadow-sm transition hover:border-primary hover:text-primary @content-xl:w-auto"
          >
            <ArrowRight className="h-4 w-4 rotate-180" />
            <span>Back to History</span>
          </button>
        </div>
      </div>

      {!communityPromptDismissed && communityShareState !== 'done' && (
        <section className="rounded-2xl border border-primary/20 bg-primary/5 p-4 @content-sm:p-5" aria-label="Share analysis with the community">
          <div className="flex flex-col gap-3 @content-sm:flex-row @content-sm:items-center @content-sm:justify-between">
            <div className="min-w-0">
              <h2 className="font-bold text-text-main">Would you like to share this with the community?</h2>
              <p className="mt-1 text-sm text-text-muted">
                Sharing makes the message and its category visible to signed-in ScamShield users. Remove personal details before sharing.
              </p>
            </div>
            <div className="flex shrink-0 gap-2">
              <button
                type="button"
                disabled={communityShareState === 'sending'}
                onClick={async () => {
                  setCommunityShareError(null);
                  setCommunityShareState('sending');
                  try {
                    await communityService.createReport({
                      content: result.original_text || result.content,
                      category: result.category || 'Other',
                      description: `Shared from analysis #${result.id}. Classification: ${result.classification}; risk: ${result.risk_level}.`,
                      evidence: `Analysis #${result.id}; risk score ${result.risk_score}/100.`,
                      analysis_id: result.id,
                    });
                    setCommunityShareState('done');
                  } catch (error) {
                    console.error('Failed to share analysis with the community', error);
                    setCommunityShareState('idle');
                    setCommunityShareError('Could not share this analysis. Please try again.');
                  }
                }}
                className="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white transition hover:bg-primary-hover disabled:cursor-wait disabled:opacity-60"
              >
                {communityShareState === 'sending' ? 'Sharing…' : 'Share with Community'}
              </button>
              <button
                type="button"
                onClick={() => setCommunityPromptDismissed(true)}
                className="rounded-lg border border-border-light bg-card px-4 py-2 text-sm font-semibold text-text-secondary transition hover:text-text-main"
              >
                Not now
              </button>
            </div>
          </div>
          {communityShareError && <p className="mt-3 text-sm font-semibold text-danger" role="alert">{communityShareError}</p>}
        </section>
      )}
      {communityShareState === 'done' && (
        <div className="flex items-center gap-2 rounded-xl border border-success/25 bg-success/10 px-4 py-3 text-sm font-semibold text-success" role="status">
          <CheckCircle className="h-5 w-5 shrink-0" />
          Shared with the community successfully.
          <button type="button" onClick={() => navigate('/community')} className="ml-auto underline underline-offset-2">View community</button>
        </div>
      )}

      {/* Top Card */}
      <div className={`bg-card rounded-2xl shadow-sm border ${riskColor === 'red' ? 'border-red-100 ring-1 ring-red-50' : 'border-border-light'} p-6 @content-sm:p-8`}>
        <div className="flex flex-col items-center justify-between gap-8 @content-xl:flex-row @content-xl:items-stretch">
          
          <div className="flex items-center space-x-6 @content-sm:space-x-8 flex-1 w-full @content-sm:w-auto">
            {/* Gauge */}
            <div className="relative w-28 h-28 @content-sm:w-32 @content-sm:h-32 shrink-0">
              <PieChart width={128} height={128} className="scale-90 @content-sm:scale-100 origin-top-left">
                <Pie
                  data={data}
                  cx={64}
                  cy={64}
                  startAngle={210}
                  endAngle={-30}
                  innerRadius={50}
                  outerRadius={64}
                  paddingAngle={0}
                  dataKey="value"
                  stroke="none"
                >
                  {data.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index]} />
                  ))}
                </Pie>
              </PieChart>
              <div className="absolute inset-0 flex flex-col items-center justify-center -mt-2">
                <span className="text-2xl @content-sm:text-3xl font-bold text-text-main leading-none">{result.risk_score}</span>
                <span className="text-[10px] text-text-muted font-bold">/100</span>
              </div>
              <div className="absolute -bottom-2 w-full text-center">
                <span className="text-xs @content-sm:text-sm font-bold text-text-main">Risk Score</span>
              </div>
            </div>

            {/* Title & Desc */}
            <div className="flex-1">
              <div className="flex items-center space-x-2 mb-2">
                <AlertTriangle className={`w-5 h-5 @content-sm:w-6 @content-sm:h-6 ${riskColor === 'red' ? 'text-danger' : riskColor === 'orange' ? 'text-warning' : 'text-success'}`} />
                <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full uppercase tracking-wider ${riskColor === 'red' ? 'bg-danger/100 text-white' : riskColor === 'orange' ? 'bg-warning/100 text-white' : 'bg-success/100 text-white'}`}>
                  {result.risk_level} RISK
                </span>
              </div>
              <h2 className="text-xl @content-sm:text-2xl font-bold text-text-main mb-2 leading-tight">
                {result.classification === 'SCAM' ? `${result.category === 'Unknown' || !result.category ? 'Suspicious' : result.category} Scam` : (result.category === 'Unknown' || !result.category ? 'Normal Message' : result.category)}
              </h2>
              <p className="text-sm @content-sm:text-base text-text-muted mb-3 max-w-sm">
                {(result.risk_level === 'HIGH' || result.risk_level === 'CRITICAL') ? 'This content shows strong indicators of a potential scam.' : 
                 result.risk_level === 'MEDIUM' ? 'This content shows some suspicious patterns.' :
                 'This content appears to be safe and genuine.'}
              </p>
            </div>
          </div>

          <div className="hidden w-px shrink-0 bg-background @content-xl:block"></div>

          {/* Metadata Grid */}
          <div className="mt-4 grid w-full shrink-0 grid-cols-2 gap-x-8 gap-y-6 @content-xl:mt-0 @content-xl:w-auto @content-sm:gap-x-12">
            <div>
              <div className="flex items-center space-x-2 text-text-muted mb-1.5">
                <Activity className="w-3.5 h-3.5" />
                <span className="text-[11px] font-semibold uppercase tracking-wider">Classification</span>
              </div>
              <span className={`text-sm font-bold px-2 py-0.5 rounded uppercase tracking-wider ${isScam ? 'bg-danger/20 text-red-700' : 'bg-success/20 text-success'}`}>
                {result.classification}
              </span>
            </div>
            <div>
              <div className="flex items-center space-x-2 text-text-muted mb-1.5">
                <FileText className="w-3.5 h-3.5" />
                <span className="text-[11px] font-semibold uppercase tracking-wider">Category</span>
              </div>
              <span className="text-sm font-bold px-2 py-0.5 rounded bg-primary/10 text-blue-700">
                {result.category || 'General'}
              </span>
            </div>
            <div>
              <div className="flex items-center space-x-2 text-text-muted mb-1.5">
                {getIconForType(result.input_type)}
                <span className="text-[11px] font-semibold uppercase tracking-wider">Input Type</span>
              </div>
              <span className="text-sm font-bold text-text-main capitalize">
                {result.input_type || 'Text'}
              </span>
            </div>
            <div>
              <div className="flex items-center space-x-2 text-text-muted mb-1.5">
                <Clock className="w-3.5 h-3.5" />
                <span className="text-[11px] font-semibold uppercase tracking-wider">Analyzed At</span>
              </div>
              <span className="text-sm font-bold text-text-main">
                {dateStr}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 @content-lg:grid-cols-2 gap-6">
        {/* Analyzed Content */}
        <div className="min-w-0 bg-card rounded-2xl shadow-sm border border-border-light p-6 flex flex-col h-full">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-2">
              <FileText className="w-5 h-5 text-primary" />
              <h3 className="font-bold text-text-main text-lg">Analyzed Content</h3>
            </div>
            <span className="text-[10px] font-bold px-2 py-1 bg-background border border-border-light rounded text-text-muted uppercase tracking-wider">
              {result.input_type || 'TEXT'}
            </span>
          </div>
          
          <div className="mb-6 min-w-0 max-w-full flex-1 overflow-hidden rounded-xl border border-border-light bg-background p-4">
            <p className="max-h-60 max-w-full overflow-x-hidden overflow-y-auto whitespace-pre-wrap break-words [overflow-wrap:anywhere] text-base font-mono text-text-secondary custom-scrollbar">
              {result.original_text || result.content}
            </p>
          </div>

          <div className="grid grid-cols-1 gap-4 border-t border-border-light pt-4 @content-sm:grid-cols-3">
            <div className="min-w-0">
              <div className="text-[10px] text-text-muted font-semibold mb-1 uppercase tracking-wider">Characters</div>
              <div className="text-sm font-bold text-text-main">{(result.original_text || result.content).length}</div>
            </div>
            <div className="min-w-0">
              <div className="text-[10px] text-text-muted font-semibold mb-1 uppercase tracking-wider">Analysis ID</div>
              <div className="text-sm font-bold text-text-main">#ANL_{result.id}</div>
            </div>
            <div className="min-w-0">
              <div className="text-[10px] text-text-muted font-semibold mb-1 uppercase tracking-wider">Status</div>
              <div className={`flex min-w-0 items-start gap-1 text-xs font-bold ${result.processing_status === 'COMPLETED_WITH_LIMITATIONS' ? 'text-warning' : 'text-success'}`}>
                <CheckCircle className="mt-0.5 h-3 w-3 shrink-0" />
                <span className="break-words">{(result.processing_status || 'COMPLETED').replaceAll('_', ' ').toLocaleLowerCase()}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Risk Indicators */}
        <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center space-x-2">
              <ShieldAlert className="w-5 h-5 text-danger" />
              <h3 className="font-bold text-text-main text-lg">Risk Indicators</h3>
            </div>
            <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-danger/10 text-danger uppercase">
              {result.indicators.length}
            </span>
          </div>
          <p className="text-sm text-text-muted mb-4">Key elements that suggest this might be a scam.</p>
          
          <div className="space-y-3">
            {result.indicators.length > 0 ? (showAllIndicators ? result.indicators : result.indicators.slice(0, 4)).map((indicator, idx) => (
              <div key={idx} className="bg-danger/10/50 border border-red-100 rounded-xl p-3 @content-sm:p-4 flex items-start space-x-3">
                <AlertCircle className="w-4 h-4 text-danger shrink-0 mt-0.5" />
                <div className="flex-1">
                  <h4 className="font-bold text-text-main text-sm mb-0.5 capitalize">
                    {indicator.split(' ').slice(0, 3).join(' ')}
                  </h4>
                  <p className="text-xs text-text-secondary leading-snug">{indicator}</p>
                </div>
                <div className="shrink-0 text-[10px] font-bold px-2 py-1 rounded bg-danger/10 text-danger uppercase">
                  HIGH
                </div>
              </div>
            )) : (
              <div className="bg-success/10 border border-green-100 rounded-xl p-4 flex items-start space-x-3">
                <CheckCircle className="w-4 h-4 text-success shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-bold text-text-main text-sm mb-1">No Risk Indicators</h4>
                  <p className="text-xs text-text-secondary leading-snug">No strong suspicious patterns were detected in this content.</p>
                </div>
              </div>
            )}
            
            {result.indicators.length > 4 && (
              <button 
                onClick={() => setShowAllIndicators(!showAllIndicators)}
                className="w-full text-center text-sm font-bold text-primary hover:text-primary-hover py-2 mt-2 transition-colors"
              >
                {showAllIndicators ? 'Show less \u2191' : 'View all indicators \u2192'}
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Quick Safe Action */}
      <div className="w-full rounded-2xl border border-[#bbf7d0] bg-[#f0fdf4] p-6 @content-sm:p-8">
        <div className="flex items-center space-x-2 mb-3">
          <ShieldCheck className="w-6 h-6 text-success" />
          <h3 className="text-lg font-bold text-success">Recommended Action</h3>
        </div>
        <RecommendedActions
          key={result.id}
          recommendedAction={result.recommended_action}
          safeActions={result.safe_actions}
          analyzedText={result.original_text || result.content}
        />
      </div>

      {/* Primary CTA to Page 2 */}
      <div className="mt-8 pt-4">
        <div className="min-w-0 bg-primary/5 border border-primary/20 rounded-2xl p-6 @content-sm:p-10 flex flex-col justify-between gap-6 relative overflow-hidden group hover:border-primary/40 transition-colors @content-lg:flex-row @content-lg:items-center">
          <div className="absolute -right-10 -top-10 w-40 h-40 bg-primary/10 rounded-full blur-3xl group-hover:bg-primary/20 transition-all duration-500"></div>
          
          <div className="relative z-10 min-w-0 w-full max-w-2xl @content-lg:w-auto">
            <h3 className="mb-2 flex min-w-0 flex-wrap items-center gap-x-2 text-xl font-bold text-text-main @content-sm:text-2xl">
              <span aria-hidden="true" className="shrink-0 text-2xl">✨</span>
              <span className="min-w-0">Understand the Analysis</span>
            </h3>
            <p className="text-text-muted text-base">
              Explore how ScamShield reached this result using ML prediction, AI reasoning and retrieved evidence from our knowledge base.
            </p>
          </div>
          
          <div className="relative z-10 w-full @content-lg:w-auto">
            <button 
              onClick={() => navigate(`/results/${result.id}/details`, { state: { result } })}
              className="flex w-full items-center justify-center space-x-3 rounded-xl bg-primary px-5 py-4 font-bold text-white shadow-sm transition hover:bg-primary-hover @content-lg:w-auto @content-lg:px-8"
            >
              <span>View Detailed AI Analysis</span>
              <ArrowRight className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

    </div>
  );
}

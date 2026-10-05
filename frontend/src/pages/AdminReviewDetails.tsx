import React, { useCallback, useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { 
  ShieldAlert, CheckCircle, AlertTriangle,
  ExternalLink, Database, RefreshCw
} from 'lucide-react';
import { reviewService } from '../services/reviewService';
import { formatRecommendedActions } from '../utils/formatRecommendedActions';
import AdminBackButton from '../components/AdminBackButton';

export const AdminReviewDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [caseData, setCaseData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [decision, setDecision] = useState('');
  const [notes, setNotes] = useState('');
  const [startingReview, setStartingReview] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  
  const fetchData = useCallback(async () => {
    try {
      const data = await reviewService.getReviewDetails(Number(id));
      setCaseData(data);
      setError(null);
    } catch (err) {
      console.error(err);
      setError('Unable to load this review case. Please try again.');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    void fetchData();
  }, [fetchData]);

  const handleStartReview = async () => {
    if (startingReview || !Number.isInteger(Number(id))) return;
    setStartingReview(true);
    try {
      const result = await reviewService.startReview(Number(id));
      setCaseData((current: any) => current ? {
        ...current,
        status: result.status,
        assigned_reviewer_id: result.assigned_reviewer_id,
      } : current);
      setError(null);
      setSuccess('Review started. You can now record a decision.');
      await fetchData();
    } catch (err) {
      console.error(err);
      const detail = (err as { response?: { data?: { detail?: string } } })
        ?.response?.data?.detail;
      setError(detail || 'Unable to start this review. Please try again.');
    } finally {
      setStartingReview(false);
    }
  };

  const handleSubmitDecision = async () => {
    if (!decision) return;
    try {
      await reviewService.submitDecision(Number(id), decision, notes);
      setError(null);
      fetchData();
    } catch (err) {
      console.error(err);
      setError('Unable to submit the review decision.');
    }
  };

  const handleCreateJira = async () => {
    try {
      const result = await reviewService.createJiraTicket(Number(id));
      setSuccess(result.issue_key
        ? `Jira ticket ${result.issue_key} created successfully.`
        : 'Jira ticket created successfully.');
      setError(null);
      fetchData();
    } catch (err) {
      console.error(err);
      setError('Unable to create the Jira ticket. Check the integration settings and try again.');
    }
  };

  const handleCreateKnowledge = async () => {
    try {
      await reviewService.createTrustedKnowledge(Number(id), {
        title: `Verified Pattern RV-${id}`,
        pattern: caseData.analysis?.content,
        category: caseData.analysis?.category,
        description: caseData.reviewer_notes,
        indicators: caseData.analysis?.indicators,
        safe_action: formatRecommendedActions(caseData.analysis?.recommended_action || '').join('\n')
      });
      setError(null);
      window.alert('Trusted knowledge created successfully.');
    } catch (err) {
      console.error(err);
      setError('Unable to add this case to the knowledge base.');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="animate-spin text-primary" size={32} />
      </div>
    );
  }

  if (!caseData) {
    return (
      <div className="rounded-xl border border-danger/20 bg-danger/5 p-6 text-danger">
        <p>{error || 'Case not found.'}</p>
        {error && <button onClick={fetchData} className="mt-3 font-bold underline">Retry</button>}
      </div>
    );
  }

  const analysis = caseData.analysis;

  return (
    <div className="space-y-6 max-w-5xl mx-auto pb-10">
      <AdminBackButton to="/admin/reviews" label="Back to Human Reviews" />

      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-3 mb-1">
            <h1 className="text-2xl font-bold text-text-main tracking-tight">Review Case RV-{caseData.id}</h1>
            <span className={`text-xs font-bold px-2 py-1 rounded-full ${caseData.status === 'VERIFIED' ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning'}`}>
              {caseData.status}
            </span>
            <span className="text-xs font-bold px-2 py-1 rounded-full bg-danger/10 text-danger uppercase">
              {caseData.priority} Priority
            </span>
          </div>
          <p className="text-text-muted text-sm">Escalated due to: {caseData.escalation_reasons?.join(', ') || 'No reason recorded'}</p>
        </div>

        {['PENDING', 'ASSIGNED'].includes(caseData.status) && (
          <button 
            type="button"
            onClick={() => void handleStartReview()}
            disabled={startingReview}
            className="inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 font-semibold text-white transition hover:bg-primary-hover disabled:cursor-not-allowed disabled:opacity-60"
          >
            {startingReview && <RefreshCw className="h-4 w-4 animate-spin" aria-hidden="true" />}
            {startingReview ? 'Starting review…' : 'Start Review'}
          </button>
        )}
      </div>

      {success && (
        <div className="rounded-xl border border-success/25 bg-success/10 px-4 py-3 text-sm font-semibold text-success" role="status">
          {success}
        </div>
      )}
      {error && (
        <div role="alert" className="rounded-xl border border-danger/20 bg-danger/5 px-4 py-3 text-sm text-danger">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 @content-md:grid-cols-3 gap-6">
        <div className="@content-md:col-span-2 space-y-6">
          {/* Analysis Summary */}
          <div className="bg-card border border-border-light rounded-2xl p-6 shadow-sm">
            <h2 className="text-lg font-semibold text-text-main mb-4 flex items-center gap-2">
              <ShieldAlert className="text-primary" size={20} />
              AI Assessment
            </h2>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="bg-background rounded-xl p-3 border border-border-light">
                <span className="text-xs text-text-muted">Risk Level</span>
                <p className="text-lg font-bold text-danger">{analysis.risk_level}</p>
              </div>
              <div className="bg-background rounded-xl p-3 border border-border-light">
                <span className="text-xs text-text-muted">Risk Score</span>
                <p className="text-lg font-bold text-text-main">{analysis.risk_score}/100</p>
              </div>
              <div className="bg-background rounded-xl p-3 border border-border-light">
                <span className="text-xs text-text-muted">ML Classification</span>
                <p className="text-sm font-semibold text-text-main">{analysis.classification} ({(analysis.ml_probability * 100).toFixed(0)}%)</p>
              </div>
              <div className="bg-background rounded-xl p-3 border border-border-light">
                <span className="text-xs text-text-muted">Category</span>
                <p className="text-sm font-semibold text-text-main">{analysis.category}</p>
              </div>
            </div>
            
            <div className="mb-4">
              <span className="text-xs text-text-muted uppercase font-semibold">Original Content</span>
              <div className="mt-2 p-3 bg-background rounded-lg text-text-secondary text-sm font-mono whitespace-pre-wrap border border-border-light">
                {analysis.content}
              </div>
            </div>

            {analysis.indicators && analysis.indicators.length > 0 && (
              <div>
                <span className="text-xs text-text-muted uppercase font-semibold">Detected Indicators</span>
                <ul className="mt-2 space-y-1">
                  {analysis.indicators.map((ind: string, i: number) => (
                    <li key={i} className="text-sm text-text-secondary flex items-start gap-2">
                      <AlertTriangle className="text-warning shrink-0 mt-0.5" size={14} />
                      {ind}
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </div>

          {/* Decision Section */}
          {(caseData.status === 'IN_REVIEW' || caseData.status === 'NEEDS_INFORMATION') && (
            <div className="bg-card border border-primary/20 rounded-2xl p-6 shadow-sm">
              <h2 className="text-lg font-semibold text-text-main mb-4">Human Verification Decision</h2>
              <div className="grid grid-cols-2 gap-3 mb-4">
                <button 
                  onClick={() => setDecision('CONFIRMED_SCAM')}
                  className={`p-3 rounded-lg border text-sm font-semibold transition ${decision === 'CONFIRMED_SCAM' ? 'bg-danger/10 border-danger text-danger' : 'bg-background border-border-light text-text-secondary hover:border-danger/50'}`}
                >
                  Confirm Scam
                </button>
                <button 
                  onClick={() => setDecision('CONFIRMED_GENUINE')}
                  className={`p-3 rounded-lg border text-sm font-semibold transition ${decision === 'CONFIRMED_GENUINE' ? 'bg-success/10 border-success text-success' : 'bg-background border-border-light text-text-secondary hover:border-success/50'}`}
                >
                  Confirm Genuine
                </button>
                <button 
                  onClick={() => setDecision('UNCERTAIN')}
                  className={`p-3 rounded-lg border text-sm font-semibold transition ${decision === 'UNCERTAIN' ? 'bg-warning/10 border-warning text-warning' : 'bg-background border-border-light text-text-secondary hover:border-warning/50'}`}
                >
                  Uncertain
                </button>
                <button 
                  onClick={() => setDecision('INSUFFICIENT_INFORMATION')}
                  className={`p-3 rounded-lg border text-sm font-semibold transition ${decision === 'INSUFFICIENT_INFORMATION' ? 'bg-primary/10 border-primary text-primary' : 'bg-background border-border-light text-text-secondary hover:border-primary/50'}`}
                >
                  Needs Information
                </button>
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-text-muted mb-1">Reviewer Notes (Required for Uncertain/Needs Info)</label>
                <textarea 
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="w-full bg-background border border-border-light rounded-lg p-3 text-text-main focus:border-primary focus:ring-1 focus:ring-primary text-sm"
                  rows={3}
                  placeholder="Explain reasoning or specify what information is needed..."
                />
              </div>
              <button 
                onClick={handleSubmitDecision}
                disabled={!decision || ((decision === 'UNCERTAIN' || decision === 'INSUFFICIENT_INFORMATION') && !notes)}
                className="w-full bg-primary hover:bg-primary-hover text-white font-bold py-2.5 rounded-lg transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Submit Decision
              </button>
            </div>
          )}

          {caseData.status === 'VERIFIED' && (
            <div className="bg-card border border-success/30 rounded-2xl p-6 shadow-sm">
              <div className="flex items-center gap-2 mb-2">
                <CheckCircle className="text-success" size={24} />
                <h2 className="text-xl font-bold text-text-main">Case Verified</h2>
              </div>
              <p className="text-text-secondary text-sm mb-4">
                Decision: <span className="font-bold text-text-main">{caseData.review_decision}</span>
              </p>
              {caseData.reviewer_notes && (
                <div className="bg-background p-3 rounded-lg text-sm text-text-secondary mb-4 border border-border-light">
                  {caseData.reviewer_notes}
                </div>
              )}
              
              {caseData.review_decision === 'CONFIRMED_SCAM' && (
                <div className="pt-4 border-t border-border-light">
                  <p className="text-sm text-text-muted mb-3">You can add this verified scam to the knowledge base to provide supporting evidence in future analyses.</p>
                  <button 
                    onClick={handleCreateKnowledge}
                    className="flex items-center gap-2 bg-primary/10 hover:bg-primary/20 text-primary border border-primary/30 px-4 py-2 rounded-lg font-medium text-sm transition"
                  >
                    <Database size={16} /> Create Trusted Knowledge
                  </button>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Jira Integration */}
          <div className="bg-card border border-border-light rounded-2xl p-6 shadow-sm">
            <h3 className="text-md font-semibold text-text-main flex items-center gap-2 mb-4">
          <ExternalLink size={18} className="text-primary" />
              External Workflow
            </h3>
            
            {!caseData.jira?.enabled ? (
              <p className="text-sm text-text-muted">Jira integration is not configured.</p>
            ) : caseData.jira.issue_key ? (
              <div>
                <p className="text-sm text-text-muted mb-2">Linked to Jira Issue:</p>
                <div className="bg-background border border-border-light rounded-lg p-3 flex justify-between items-center">
                  <span className="font-mono text-primary font-bold">{caseData.jira.issue_key}</span>
                  <ExternalLink size={14} className="text-text-muted" />
                </div>
              </div>
            ) : (
              <div>
                <p className="text-sm text-text-muted mb-3">No Jira ticket exists for this case.</p>
                <button 
                  onClick={handleCreateJira}
                  className="w-full bg-primary hover:bg-primary-hover text-white font-medium py-2 rounded-lg transition text-sm flex justify-center items-center gap-2"
                >
                  Create Jira Ticket
                </button>
              </div>
            )}
          </div>

          {/* Audit Trail */}
          <div className="bg-card border border-border-light rounded-2xl p-6 shadow-sm">
            <h3 className="text-md font-semibold text-text-main mb-4">Audit Timeline</h3>
            <div className="space-y-4">
              {caseData.events?.map((e: any, idx: number) => (
                <div key={idx} className="flex gap-3">
                  <div className="flex flex-col items-center">
                    <div className="w-2 h-2 rounded-full bg-primary mt-1.5" />
                    {idx !== caseData.events.length - 1 && <div className="w-px h-full bg-border-light mt-1" />}
                  </div>
                  <div className="pb-4">
                    <p className="text-sm font-medium text-text-main">{e.event_type.replace(/_/g, ' ')}</p>
                    <p className="text-xs text-text-muted">{new Date(e.created_at).toLocaleString()}</p>
                    {e.notes && <p className="text-xs text-text-secondary mt-1">{e.notes}</p>}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminReviewDetails;

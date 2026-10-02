import { useLocation, Navigate, useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { 
  AlertTriangle, CheckCircle, FileText, Download, Plus, Clock, Globe,
  Activity, AlertCircle, MessageSquare, ArrowRight, ShieldAlert,
  ShieldCheck, FileImage, Headphones, File
} from 'lucide-react';
import { PieChart, Pie, Cell } from 'recharts';

interface AnalysisItem {
  id: number;
  content: string;
  risk_score: number;
  risk_level: string;
  classification: string;
  ml_probability: number;
  category: string;
  indicators: string[];
  explanation: string;
  evidence: string[];
  recommended_action: string;
  created_at: string;
  input_type?: string;
  original_filename?: string;
  original_text?: string;
  llm_confidence?: number;
  llm_reasoning?: string;
  processing_status?: string;
  model_version?: string;
  rag_version?: string;
  retrieved_evidence_data?: any[];
  evidence_status?: string;
}

export default function AnalysisOverview() {
  const location = useLocation();
  const navigate = useNavigate();
  const result: AnalysisItem = location.state?.result;
  const [showAllIndicators, setShowAllIndicators] = useState(false);

  if (!result) {
    return <Navigate to="/history" replace />;
  }

  const isScam = result.classification === 'SCAM';
  const riskColor = result.risk_level === 'HIGH' || result.risk_level === 'CRITICAL' ? 'red' : 
                   result.risk_level === 'MEDIUM' ? 'orange' : 'green';

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
      {/* Step Indicator */}
      <div className="flex items-center justify-center space-x-4 mb-4">
        <div className="flex items-center space-x-2 text-primary font-bold text-sm">
          <div className="w-6 h-6 rounded-full bg-primary text-white flex items-center justify-center text-xs">1</div>
          <span>Overview</span>
        </div>
        <div className="w-16 h-px bg-border-main hidden sm:block"></div>
        <div className="flex items-center space-x-2 text-text-muted font-bold text-sm">
          <div className="w-6 h-6 rounded-full border-2 border-border-main flex items-center justify-center text-xs">2</div>
          <span>Detailed Analysis</span>
        </div>
      </div>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-1">Analysis Result</h1>
          <p className="text-text-muted text-base">Here's what we found and why this content might be risky.</p>
        </div>
        <div className="flex items-center space-x-3 shrink-0">
          <button 
            onClick={() => {
              const report = `ScamShield Analysis Report\n\nID: ANL_${result.id}\nDate: ${dateStr}\n\nClassification: ${result.classification}\nRisk Score: ${result.risk_score}/100 (${result.risk_level} RISK)\nCategory: ${result.category || 'Unknown'}\nInput Type: ${result.input_type || 'Text'}\n\nAnalyzed Content:\n${result.original_text || result.content}\n\nIndicators:\n${result.indicators.join('\n')}\n\nRecommended Action:\n${result.recommended_action}`;
              const blob = new Blob([report], { type: 'text/plain' });
              const url = URL.createObjectURL(blob);
              const a = document.createElement('a');
              a.href = url;
              a.download = `ScamShield_Report_ANL_${result.id}.txt`;
              document.body.appendChild(a);
              a.click();
              document.body.removeChild(a);
              URL.revokeObjectURL(url);
            }}
            className="flex items-center space-x-2 bg-card border border-border-light hover:border-border-main text-text-secondary font-semibold py-2 px-4 rounded-lg shadow-sm transition"
          >
            <Download className="w-4 h-4" />
            <span>Download Report</span>
          </button>
          <button 
            onClick={async () => {
              try {
                const { reviewService } = await import('../services/reviewService');
                const res = await reviewService.requestReview(result.id);
                if(res.success) {
                  alert('Human verification requested successfully! Check your Review Center.');
                  navigate('/app/admin/reviews'); // Or just show success
                }
              } catch (e) {
                console.error(e);
                alert('Failed to request human verification or it already exists.');
              }
            }}
            className="flex items-center space-x-2 bg-amber-500 hover:bg-amber-600 text-white font-semibold py-2 px-4 rounded-lg shadow-sm transition"
          >
            <ShieldAlert className="w-4 h-4" />
            <span>Request Human Review</span>
          </button>
          <button onClick={() => navigate('/analyze')} className="flex items-center space-x-2 bg-primary hover:bg-primary-hover text-white font-semibold py-2 px-4 rounded-lg shadow-sm transition">
            <Plus className="w-4 h-4" />
            <span>Analyze New Content</span>
          </button>
        </div>
      </div>

      {/* Top Card */}
      <div className={`bg-card rounded-2xl shadow-sm border ${riskColor === 'red' ? 'border-red-100 ring-1 ring-red-50' : 'border-border-light'} p-6 sm:p-8`}>
        <div className="flex flex-col md:flex-row items-center md:items-stretch justify-between gap-8">
          
          <div className="flex items-center space-x-6 sm:space-x-8 flex-1 w-full sm:w-auto">
            {/* Gauge */}
            <div className="relative w-28 h-28 sm:w-32 sm:h-32 shrink-0">
              <PieChart width={128} height={128} className="scale-90 sm:scale-100 origin-top-left">
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
                <span className="text-2xl sm:text-3xl font-bold text-text-main leading-none">{result.risk_score}</span>
                <span className="text-[10px] text-text-muted font-bold">/100</span>
              </div>
              <div className="absolute -bottom-2 w-full text-center">
                <span className="text-xs sm:text-sm font-bold text-text-main">Risk Score</span>
              </div>
            </div>

            {/* Title & Desc */}
            <div className="flex-1">
              <div className="flex items-center space-x-2 mb-2">
                <AlertTriangle className={`w-5 h-5 sm:w-6 sm:h-6 ${riskColor === 'red' ? 'text-danger' : riskColor === 'orange' ? 'text-warning' : 'text-success'}`} />
                <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full uppercase tracking-wider ${riskColor === 'red' ? 'bg-danger/100 text-white' : riskColor === 'orange' ? 'bg-warning/100 text-white' : 'bg-success/100 text-white'}`}>
                  {result.risk_level} RISK
                </span>
              </div>
              <h2 className="text-xl sm:text-2xl font-bold text-text-main mb-2 leading-tight">
                {result.classification === 'SCAM' ? `${result.category === 'Unknown' || !result.category ? 'Suspicious' : result.category} Scam` : (result.category === 'Unknown' || !result.category ? 'Normal Message' : result.category)}
              </h2>
              <p className="text-sm sm:text-base text-text-muted mb-3 max-w-sm">
                {(result.risk_level === 'HIGH' || result.risk_level === 'CRITICAL') ? 'This content shows strong indicators of a potential scam.' : 
                 result.risk_level === 'MEDIUM' ? 'This content shows some suspicious patterns.' :
                 'This content appears to be safe and genuine.'}
              </p>
            </div>
          </div>

          <div className="hidden md:block w-px bg-background shrink-0"></div>

          {/* Metadata Grid */}
          <div className="grid grid-cols-2 gap-x-8 sm:gap-x-12 gap-y-6 shrink-0 w-full md:w-auto mt-4 md:mt-0">
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

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Analyzed Content */}
        <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6 flex flex-col h-full">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-2">
              <FileText className="w-5 h-5 text-primary" />
              <h3 className="font-bold text-text-main text-lg">Analyzed Content</h3>
            </div>
            <span className="text-[10px] font-bold px-2 py-1 bg-background border border-border-light rounded text-text-muted uppercase tracking-wider">
              {result.input_type || 'TEXT'}
            </span>
          </div>
          
          <div className="bg-background rounded-xl p-4 mb-6 flex-1 border border-border-light">
            <p className="text-base text-text-secondary font-mono whitespace-pre-wrap break-all sm:break-normal max-h-60 overflow-y-auto custom-scrollbar">
              {result.original_text || result.content}
            </p>
          </div>

          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-border-light">
            <div>
              <div className="text-[10px] text-text-muted font-semibold mb-1 uppercase tracking-wider">Characters</div>
              <div className="text-sm font-bold text-text-main">{(result.original_text || result.content).length}</div>
            </div>
            <div>
              <div className="text-[10px] text-text-muted font-semibold mb-1 uppercase tracking-wider">Analysis ID</div>
              <div className="text-sm font-bold text-text-main">#ANL_{result.id}</div>
            </div>
            <div>
              <div className="text-[10px] text-text-muted font-semibold mb-1 uppercase tracking-wider">Status</div>
              <div className="text-sm font-bold text-success flex items-center space-x-1">
                <CheckCircle className="w-3 h-3" />
                <span>{result.processing_status || 'COMPLETED'}</span>
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
              <div key={idx} className="bg-danger/10/50 border border-red-100 rounded-xl p-3 sm:p-4 flex items-start space-x-3">
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
      <div className="bg-[#f0fdf4] border border-[#bbf7d0] rounded-2xl p-6 sm:p-8">
        <div className="flex items-center space-x-2 mb-3">
          <ShieldCheck className="w-6 h-6 text-success" />
          <h3 className="text-lg font-bold text-success">Recommended Action</h3>
        </div>
        <p className="text-base sm:text-lg text-success font-semibold leading-relaxed max-w-3xl ml-8">
          {result.recommended_action}
        </p>
      </div>

      {/* Primary CTA to Page 2 */}
      <div className="mt-8 pt-4">
        <div className="bg-primary/5 border border-primary/20 rounded-2xl p-6 sm:p-10 flex flex-col sm:flex-row sm:items-center justify-between gap-6 relative overflow-hidden group hover:border-primary/40 transition-colors">
          <div className="absolute -right-10 -top-10 w-40 h-40 bg-primary/10 rounded-full blur-3xl group-hover:bg-primary/20 transition-all duration-500"></div>
          
          <div className="relative z-10 max-w-2xl">
            <h3 className="text-2xl font-bold text-text-main mb-2 flex items-center space-x-2">
              <span className="text-2xl">✨</span>
              <span>Understand the Analysis</span>
            </h3>
            <p className="text-text-muted text-base">
              Explore how ScamShield reached this result using ML prediction, AI reasoning and retrieved evidence from our knowledge base.
            </p>
          </div>
          
          <div className="relative z-10 shrink-0">
            <button 
              onClick={() => navigate(`/results/${result.id}/details`, { state: { result } })}
              className="w-full sm:w-auto bg-primary hover:bg-primary-hover text-white px-8 py-4 rounded-xl font-bold flex items-center justify-center space-x-3 transition shadow-sm"
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

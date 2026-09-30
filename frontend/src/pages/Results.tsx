import { useLocation, Navigate } from 'react-router-dom';
import { AlertTriangle, CheckCircle, ShieldAlert, FileText, ArrowRight, Info } from 'lucide-react';

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
}

export default function Results() {
  const location = useLocation();
  const result: AnalysisItem = location.state?.result;

  if (!result) {
    return <Navigate to="/analyze" />;
  }

  const isScam = result.classification === 'SCAM';

  return (
    <div className="max-w-5xl">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-800 mb-1">Analysis Result</h1>
        <p className="text-slate-500 text-sm">This result is stored in your database history.</p>
      </div>

      <div className="bg-slate-50 border border-slate-200 rounded-xl p-5 mb-6 shadow-sm">
        <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Analyzed Content</h3>
        <p className="text-slate-700 text-sm whitespace-pre-wrap font-mono bg-white p-4 rounded-lg border border-slate-100">{result.content}</p>
      </div>

      <div className={`${isScam ? 'bg-red-50 border-red-200' : 'bg-green-50 border-green-200'} border rounded-xl p-5 flex items-center justify-between mb-6 shadow-sm`}>
        <div className="flex items-center space-x-3">
          {isScam ? (
             <AlertTriangle className="w-6 h-6 text-red-500" />
          ) : (
             <CheckCircle className="w-6 h-6 text-green-500" />
          )}
          <span className={`font-bold ${isScam ? 'text-red-700' : 'text-green-700'} text-lg`}>
            {isScam ? 'SCAM DETECTED' : 'SAFE MESSAGE'}
          </span>
          <span className={`text-xs ${isScam ? 'text-red-500/70' : 'text-green-500/70'} ml-2`}>
            Processed via backend analysis engine.
          </span>
        </div>
        <div className={`${isScam ? 'bg-red-500' : 'bg-green-500'} text-white text-xs font-bold px-3 py-1.5 rounded flex items-center space-x-1 shadow-sm`}>
          <ShieldAlert className="w-3.5 h-3.5" />
          <span>{result.risk_level} Risk</span>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-8 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 divide-x divide-slate-100">
          <div className="flex flex-col justify-center">
            <div className="text-center relative">
              <svg viewBox="0 0 36 36" className="w-24 h-24 mx-auto mb-2">
                <path
                  className="text-slate-100"
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="3"
                />
                <path
                  className={isScam ? "text-red-500" : "text-green-500"}
                  strokeDasharray={`${result.risk_score}, 100`}
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="3"
                />
                <text x="18" y="20.35" className="text-3xl font-bold" textAnchor="middle" fill="#0f172a">{result.risk_score}</text>
                <text x="18" y="27" className="text-[6px] font-bold text-slate-400" textAnchor="middle" fill="#64748b">/100</text>
              </svg>
              <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">Risk Score</div>
            </div>
          </div>
          <div className="pl-8 flex flex-col justify-center">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-2">Classification</div>
            <div className={`text-3xl font-bold ${isScam ? 'text-red-600' : 'text-green-600'}`}>{result.classification}</div>
          </div>
          <div className="pl-8 flex flex-col justify-center">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-2">ML Probability</div>
            <div className="text-3xl font-bold text-blue-600">{Math.round(result.ml_probability * 100)}%</div>
          </div>
          <div className="pl-8 flex flex-col justify-center">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-2">Scam Category</div>
            <div className={`text-xl font-bold ${isScam ? 'text-red-600' : 'text-slate-800'}`}>{result.category}</div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-6">
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 h-full">
            <h3 className="font-bold text-slate-800 mb-4 text-sm flex items-center space-x-2">
               <AlertTriangle className={`w-4 h-4 ${isScam ? 'text-red-500' : 'text-slate-400'}`} />
               <span>Suspicious Indicators</span>
            </h3>
            <ul className="space-y-3">
              {result.indicators.length > 0 ? result.indicators.map((indicator, idx) => (
                <li key={idx} className="flex items-start space-x-3 text-sm text-slate-600">
                  <div className={`w-5 h-5 ${isScam ? 'bg-red-100 text-red-600' : 'bg-slate-100 text-slate-500'} rounded-full flex items-center justify-center shrink-0`}>
                     <ShieldAlert className="w-3 h-3" />
                  </div>
                  <span className="font-medium text-slate-700">{indicator}</span>
                </li>
              )) : (
                <p className="text-sm text-slate-500">No suspicious indicators detected.</p>
              )}
            </ul>
          </div>
        </div>

        <div className="space-y-6">
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
            <h3 className="font-bold text-slate-800 mb-2 text-sm">Why This Is Suspicious</h3>
            <p className="text-sm text-slate-600 leading-relaxed">
              {result.explanation}
            </p>
          </div>
          <div className="bg-green-50 border border-green-200 rounded-2xl p-6 shadow-sm">
            <h3 className="font-bold text-green-800 mb-4 text-sm flex items-center space-x-2">
              <CheckCircle className="w-4 h-4 text-green-600" />
              <span>Recommended Safe Action</span>
            </h3>
            <div className="flex items-start space-x-2 text-sm text-green-700 font-medium bg-white/50 p-4 rounded-lg">
              <ArrowRight className="w-4 h-4 mt-0.5 shrink-0" />
              <span className="leading-relaxed">{result.recommended_action}</span>
            </div>
          </div>
        </div>
      </div>
      
      <div className="mt-6 bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
        <h3 className="font-bold text-slate-800 mb-4 text-sm flex items-center space-x-2">
          <FileText className="w-4 h-4 text-slate-400" />
          <span>Supporting Evidence</span>
        </h3>
        <ul className="space-y-3">
          {result.evidence.length > 0 ? result.evidence.map((item, idx) => (
            <li key={idx} className="flex items-start space-x-3 text-sm text-slate-600">
              <Info className="w-4 h-4 text-blue-500 shrink-0 mt-0.5" />
              <span className="font-medium">{item}</span>
            </li>
          )) : (
            <p className="text-sm text-slate-500">No external evidence needed.</p>
          )}
        </ul>
      </div>
    </div>
  );
}

import { useState } from 'react';
import { useLocation, Navigate, useNavigate } from 'react-router-dom';
import { 
  AlertTriangle, CheckCircle, FileText, Download, Plus, Clock, Globe,
  ShieldAlert, Activity, AlertCircle, MessageSquare, Fingerprint, ChevronDown, ChevronUp, Lock, Database, Search
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
}

export default function Results() {
  const location = useLocation();
  const navigate = useNavigate();
  const result: AnalysisItem = location.state?.result;
  const [expandedSection, setExpandedSection] = useState<string>('summary');

  if (!result) {
    return <Navigate to="/analyze" />;
  }

  const isScam = result.classification === 'SCAM';
  const riskColor = result.risk_level === 'HIGH' || result.risk_level === 'CRITICAL' ? 'red' : 
                   result.risk_level === 'MEDIUM' ? 'orange' : 'green';

  const dateStr = new Date(result.created_at).toLocaleString('en-US', {
    month: 'short', day: 'numeric', year: 'numeric', hour: 'numeric', minute: '2-digit'
  });

  // Calculate gauge data
  const data = [
    { value: result.risk_score },
    { value: 100 - result.risk_score }
  ];
  const COLORS = [
    riskColor === 'red' ? '#ef4444' : riskColor === 'orange' ? '#f97316' : '#22c55e',
    '#f1f5f9'
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <div className="flex items-center text-xs text-slate-500 mb-1">
            <span className="hover:text-slate-800 cursor-pointer" onClick={() => navigate('/analyze')}>Analyze</span>
            <span className="mx-2">&gt;</span>
            <span className="text-slate-800 font-medium">Result</span>
          </div>
          <h1 className="text-3xl font-bold text-slate-800 mb-1">Analysis Result</h1>
          <p className="text-slate-500 text-sm">Here's what we found and why this content might be risky.</p>
        </div>
        <div className="flex items-center space-x-3 shrink-0">
          <button className="flex items-center space-x-2 bg-white border border-slate-200 hover:border-slate-300 text-slate-700 font-medium py-2 px-4 rounded-lg shadow-sm transition">
            <Download className="w-4 h-4" />
            <span>Download Report</span>
          </button>
          <button onClick={() => navigate('/analyze')} className="flex items-center space-x-2 bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg shadow-sm shadow-blue-600/20 transition">
            <Plus className="w-4 h-4" />
            <span>Analyze New Content</span>
          </button>
        </div>
      </div>

      {/* Top Card */}
      <div className={`bg-white rounded-2xl shadow-sm border ${riskColor === 'red' ? 'border-red-100 ring-1 ring-red-50' : 'border-slate-200'} p-8`}>
        <div className="flex flex-col md:flex-row items-center md:items-stretch justify-between gap-8">
          
          <div className="flex items-center space-x-8 flex-1">
            {/* Gauge */}
            <div className="relative w-32 h-32 shrink-0">
              <PieChart width={128} height={128}>
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
                <span className="text-3xl font-bold text-slate-800 leading-none">{result.risk_score}</span>
                <span className="text-[10px] text-slate-400 font-bold">/100</span>
              </div>
              <div className="absolute -bottom-2 w-full text-center">
                <span className="text-xs font-bold text-slate-800">Risk Score</span>
              </div>
            </div>

            {/* Title & Desc */}
            <div>
              <div className="flex items-center space-x-2 mb-2">
                <AlertTriangle className={`w-6 h-6 ${riskColor === 'red' ? 'text-red-500' : riskColor === 'orange' ? 'text-orange-500' : 'text-green-500'}`} />
                <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full uppercase tracking-wider ${riskColor === 'red' ? 'bg-red-500 text-white' : riskColor === 'orange' ? 'bg-orange-500 text-white' : 'bg-green-500 text-white'}`}>
                  {result.risk_level} RISK
                </span>
              </div>
              <h2 className="text-2xl font-bold text-slate-800 mb-2">
                {result.classification === 'SCAM' ? `${result.category || 'Unknown'} Scam` : (result.category || 'Normal Message')}
              </h2>
              <p className="text-sm text-slate-500 mb-3 max-w-sm">
                {result.risk_level === 'HIGH' ? 'This content shows strong indicators of a potential scam.' : 
                 result.risk_level === 'MEDIUM' ? 'This content shows some suspicious patterns.' :
                 'This content appears to be safe and genuine.'}
              </p>
              <div className="flex items-center text-xs text-slate-400 space-x-1.5">
                <Clock className="w-3.5 h-3.5" />
                <span>Analyzed on {dateStr}</span>
              </div>
            </div>
          </div>

          <div className="hidden md:block w-px bg-slate-100"></div>

          {/* Metadata Grid */}
          <div className="grid grid-cols-2 gap-x-12 gap-y-6 shrink-0 w-full md:w-auto">
            <div>
              <div className="flex items-center space-x-2 text-slate-500 mb-2">
                <Activity className="w-4 h-4" />
                <span className="text-xs font-medium">Classification</span>
              </div>
              <span className={`text-xs font-bold px-2 py-0.5 rounded uppercase tracking-wider ${isScam ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
                {result.classification}
              </span>
            </div>
            <div>
              <div className="flex items-center space-x-2 text-slate-500 mb-2">
                <FileText className="w-4 h-4" />
                <span className="text-xs font-medium">Category</span>
              </div>
              <span className="text-xs font-bold px-2 py-0.5 rounded bg-blue-50 text-blue-700">
                {result.category || 'General'}
              </span>
            </div>
            <div>
              <div className="flex items-center space-x-2 text-slate-500 mb-2">
                <MessageSquare className="w-4 h-4" />
                <span className="text-xs font-medium">Input Type</span>
              </div>
              <span className="text-xs font-bold text-slate-800 capitalize">
                {result.input_type || 'Text'}
              </span>
            </div>
            <div>
              <div className="flex items-center space-x-2 text-slate-500 mb-2">
                <Globe className="w-4 h-4" />
                <span className="text-xs font-medium">Language</span>
              </div>
              <span className="text-xs font-bold text-slate-800 flex items-center space-x-1.5">
                <Globe className="w-3.5 h-3.5 text-slate-400" />
                <span>English</span>
              </span>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Analyzed Content */}
        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6 flex flex-col h-full">
          <div className="flex items-center space-x-2 mb-4">
            <FileText className="w-5 h-5 text-blue-500" />
            <h3 className="font-bold text-slate-800 text-base">Analyzed Content</h3>
          </div>
          
          <div className="bg-slate-50 rounded-xl p-4 mb-6 flex-1 border border-slate-100 relative group">
            <p className="text-sm text-slate-700 font-mono whitespace-pre-wrap">{result.content}</p>
            <button className="absolute top-2 right-2 p-1.5 bg-white rounded shadow-sm text-slate-400 hover:text-slate-600 opacity-0 group-hover:opacity-100 transition border border-slate-200">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
            </button>
          </div>

          <div className="grid grid-cols-4 gap-4 pt-4 border-t border-slate-100">
            <div>
              <div className="text-[10px] text-slate-400 font-medium mb-1">Characters</div>
              <div className="text-xs font-bold text-slate-800">{result.content.length}</div>
            </div>
            <div>
              <div className="text-[10px] text-slate-400 font-medium mb-1">Source</div>
              <div className="text-xs font-bold text-slate-800 capitalize">{result.input_type || 'Text Input'}</div>
            </div>
            <div>
              <div className="text-[10px] text-slate-400 font-medium mb-1">Analysis ID</div>
              <div className="text-xs font-bold text-slate-800">#ANL_{result.id}</div>
            </div>
            <div>
              <div className="text-[10px] text-slate-400 font-medium mb-1">Processing Time</div>
              <div className="text-xs font-bold text-slate-800">0.8 seconds</div>
            </div>
          </div>
        </div>

        {/* Risk Indicators */}
        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center space-x-2">
              <ShieldAlert className="w-5 h-5 text-red-500" />
              <h3 className="font-bold text-slate-800 text-base">Risk Indicators</h3>
            </div>
            <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-red-50 text-red-600 uppercase">
              {result.indicators.length} Indicators
            </span>
          </div>
          <p className="text-xs text-slate-500 mb-4">Key elements that suggest this might be a scam.</p>
          
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {result.indicators.length > 0 ? result.indicators.map((indicator, idx) => (
              <div key={idx} className="bg-red-50/50 border border-red-100 rounded-xl p-4 flex items-start space-x-3">
                <AlertCircle className="w-4 h-4 text-red-500 shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-bold text-slate-800 text-xs mb-1 capitalize">
                    {indicator.split(' ').slice(0, 2).join(' ')}
                  </h4>
                  <p className="text-[10px] text-slate-600 leading-snug">{indicator}</p>
                </div>
              </div>
            )) : (
              <div className="col-span-2 bg-green-50/50 border border-green-100 rounded-xl p-4 flex items-start space-x-3">
                <CheckCircle className="w-4 h-4 text-green-500 shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-bold text-slate-800 text-xs mb-1">No Risk Indicators</h4>
                  <p className="text-[10px] text-slate-600 leading-snug">No suspicious patterns were detected in this content.</p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* AI Analysis */}
        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
          <div className="flex items-center space-x-2 mb-2">
            <Fingerprint className="w-5 h-5 text-blue-600" />
            <h3 className="font-bold text-slate-800 text-base">AI Analysis & Reasoning</h3>
          </div>
          <p className="text-xs text-slate-500 mb-6">Our AI explains why this content is classified as risky.</p>
          
          <div className="space-y-3">
            {/* Accordion Item 1 */}
            <div className="border border-slate-200 rounded-xl overflow-hidden">
              <button 
                onClick={() => setExpandedSection(expandedSection === 'summary' ? '' : 'summary')}
                className={`w-full flex items-center justify-between p-4 bg-slate-50 hover:bg-slate-100 transition text-left ${expandedSection === 'summary' ? 'bg-blue-50/50 hover:bg-blue-50' : ''}`}
              >
                <div className="flex items-center space-x-3">
                  <FileText className={`w-4 h-4 ${expandedSection === 'summary' ? 'text-blue-600' : 'text-slate-500'}`} />
                  <span className={`font-bold text-sm ${expandedSection === 'summary' ? 'text-blue-700' : 'text-slate-700'}`}>AI Summary</span>
                </div>
                {expandedSection === 'summary' ? <ChevronUp className="w-4 h-4 text-blue-600" /> : <ChevronDown className="w-4 h-4 text-slate-400" />}
              </button>
              {expandedSection === 'summary' && (
                <div className="p-4 border-t border-slate-100 bg-white">
                  <p className="text-sm text-slate-600 leading-relaxed">
                    {result.explanation}
                  </p>
                </div>
              )}
            </div>

            {/* Accordion Item 2 */}
            <div className="border border-slate-200 rounded-xl overflow-hidden">
              <button 
                onClick={() => setExpandedSection(expandedSection === 'ml' ? '' : 'ml')}
                className="w-full flex items-center justify-between p-4 bg-slate-50 hover:bg-slate-100 transition text-left"
              >
                <div className="flex items-center space-x-3">
                  <Activity className="w-4 h-4 text-slate-500" />
                  <span className="font-bold text-sm text-slate-700">ML Prediction</span>
                </div>
                <div className="flex items-center space-x-3">
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-red-50 text-red-600">{Math.round(result.ml_probability * 100)}% scam probability</span>
                  {expandedSection === 'ml' ? <ChevronUp className="w-4 h-4 text-slate-400" /> : <ChevronDown className="w-4 h-4 text-slate-400" />}
                </div>
              </button>
              {expandedSection === 'ml' && (
                <div className="p-4 border-t border-slate-100 bg-white">
                  <p className="text-sm text-slate-600">The underlying machine learning model determined a {Math.round(result.ml_probability * 100)}% probability that this matches known fraudulent signatures.</p>
                </div>
              )}
            </div>
            
            {/* Accordion Item 3 */}
            <div className="border border-slate-200 rounded-xl overflow-hidden">
              <button 
                onClick={() => setExpandedSection(expandedSection === 'rag' ? '' : 'rag')}
                className="w-full flex items-center justify-between p-4 bg-slate-50 hover:bg-slate-100 transition text-left"
              >
                <div className="flex items-center space-x-3">
                  <Database className="w-4 h-4 text-slate-500" />
                  <span className="font-bold text-sm text-slate-700">RAG Evidence</span>
                </div>
                <div className="flex items-center space-x-3">
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-blue-50 text-blue-600">{result.evidence.length} similar patterns</span>
                  {expandedSection === 'rag' ? <ChevronUp className="w-4 h-4 text-slate-400" /> : <ChevronDown className="w-4 h-4 text-slate-400" />}
                </div>
              </button>
              {expandedSection === 'rag' && (
                <div className="p-4 border-t border-slate-100 bg-white">
                  <p className="text-sm text-slate-600 mb-2">Evidence retrieved from our knowledge base:</p>
                  <ul className="list-disc pl-5 text-sm text-slate-600 space-y-1">
                    {result.evidence.map((ev, i) => <li key={i}>{ev}</li>)}
                    {result.evidence.length === 0 && <li>No specific external evidence retrieved.</li>}
                  </ul>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Retrieved Evidence & Safe Action */}
        <div className="space-y-6">
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center space-x-2">
                <Database className="w-5 h-5 text-blue-600" />
                <h3 className="font-bold text-slate-800 text-base">Retrieved Evidence (Similar Scam Patterns)</h3>
              </div>
              <button className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center space-x-1">
                <span>View All</span>
                <span>&rarr;</span>
              </button>
            </div>
            <p className="text-xs text-slate-500 mb-4">Top matching examples from our scam knowledge base.</p>
            
            <div className="overflow-hidden border border-slate-100 rounded-xl">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-100 text-[10px] font-bold text-slate-500 uppercase tracking-wider">
                  <tr>
                    <th className="px-4 py-3 font-semibold">SIMILARITY</th>
                    <th className="px-4 py-3 font-semibold">CATEGORY</th>
                    <th className="px-4 py-3 font-semibold">EXAMPLE PATTERN</th>
                    <th className="px-4 py-3 font-semibold">SOURCE</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-600">
                  {result.evidence.length > 0 ? result.evidence.slice(0, 3).map((item, idx) => (
                    <tr key={idx}>
                      <td className="px-4 py-3">
                        <span className="text-[10px] font-bold bg-red-100 text-red-600 px-1.5 py-0.5 rounded">
                          {90 - (idx * 5)}%
                        </span>
                      </td>
                      <td className="px-4 py-3 font-medium text-slate-800">{result.category || 'Scam'}</td>
                      <td className="px-4 py-3 truncate max-w-[150px]">{item}</td>
                      <td className="px-4 py-3 text-slate-400">Knowledge Base</td>
                    </tr>
                  )) : (
                    <tr>
                      <td colSpan={4} className="px-4 py-6 text-center text-slate-500">No matching patterns found in DB.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>

          <div className="bg-[#f0fdf4] border border-[#bbf7d0] rounded-2xl p-6">
            <div className="flex items-center space-x-2 mb-1">
              <CheckCircle className="w-5 h-5 text-green-600" />
              <h3 className="text-sm font-bold text-green-800">Recommended Safe Action</h3>
            </div>
            <p className="text-xs text-green-700/80 mb-4 ml-7">Based on our analysis, here's what you should do.</p>
            
            <div className="bg-white border border-green-200 rounded-xl p-4 flex items-start space-x-3 shadow-sm ml-7">
              <div className="w-5 h-5 bg-green-100 rounded-full flex items-center justify-center shrink-0 mt-0.5">
                <CheckCircle className="w-3 h-3 text-green-600" />
              </div>
              <p className="text-sm text-green-800 font-medium leading-relaxed">
                {result.recommended_action}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

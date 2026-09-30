import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FileText, Image as ImageIcon, File, Mic, Info } from 'lucide-react';
import { api } from '../services/api';

export default function Analyze() {
  const [type, setType] = useState('Text');
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleAnalyze = async () => {
    if (!text) return;
    setLoading(true);
    try {
      const res = await api.post('/analysis/run', { content: text });
      navigate('/results', { state: { result: res.data, from: '/analyze' } });
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-4xl">
      <h1 className="text-2xl font-bold text-slate-800 mb-1">Analyze Suspicious Content</h1>
      <p className="text-slate-500 text-sm mb-8">Choose the type of content you want to analyze.</p>

      <div className="flex space-x-2 mb-8">
        <button onClick={() => setType('Text')} className={`flex items-center space-x-2 px-5 py-2.5 rounded-lg border text-sm font-medium transition ${type === 'Text' ? 'bg-blue-50 border-blue-200 text-blue-700' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'}`}>
          <FileText className="w-4 h-4" />
          <span>Text</span>
        </button>
        <button onClick={() => setType('Image')} className={`flex items-center space-x-2 px-5 py-2.5 rounded-lg border text-sm font-medium transition ${type === 'Image' ? 'bg-blue-50 border-blue-200 text-blue-700' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'}`}>
          <ImageIcon className="w-4 h-4" />
          <span>Image</span>
        </button>
        <button onClick={() => setType('PDF')} className={`flex items-center space-x-2 px-5 py-2.5 rounded-lg border text-sm font-medium transition ${type === 'PDF' ? 'bg-blue-50 border-blue-200 text-blue-700' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'}`}>
          <File className="w-4 h-4" />
          <span>PDF</span>
        </button>
        <button onClick={() => setType('Audio')} className={`flex items-center space-x-2 px-5 py-2.5 rounded-lg border text-sm font-medium transition ${type === 'Audio' ? 'bg-blue-50 border-blue-200 text-blue-700' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'}`}>
          <Mic className="w-4 h-4" />
          <span>Audio</span>
        </button>
      </div>

      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 mb-8">
        <h2 className="font-bold text-slate-800 mb-1 text-sm">Enter Text to Analyze</h2>
        <p className="text-xs text-slate-500 mb-4">Paste a suspicious message, email, WhatsApp message, or any other text here.</p>
        
        <textarea 
          className="w-full h-40 px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all resize-none mb-4 text-sm placeholder:text-slate-400" 
          placeholder="Type or paste your text here..."
          value={text}
          onChange={(e) => setText(e.target.value)}
        ></textarea>
        
        <button 
          onClick={handleAnalyze} 
          disabled={!text || loading}
          className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2.5 px-8 rounded-lg shadow-lg shadow-blue-500/30 transition-all disabled:opacity-50 text-sm"
        >
          {loading ? 'Analyzing...' : 'Analyze'}
        </button>
      </div>

      <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 flex items-start space-x-3">
        <div className="bg-blue-100 rounded-full p-1.5 shrink-0 mt-0.5">
          <Info className="w-4 h-4 text-blue-600" />
        </div>
        <div>
          <h3 className="text-sm font-bold text-blue-800 mb-1">AI Analysis Enabled</h3>
          <p className="text-xs text-blue-700/80 leading-relaxed">
            Submissions are now securely processed through the backend and persisted to your account history.
          </p>
        </div>
      </div>
    </div>
  );
}

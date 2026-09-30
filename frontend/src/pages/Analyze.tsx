import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { FileText, Image as ImageIcon, File, Mic, Trash2, Search, Lock, Mail, Link as LinkIcon, MessageSquare, Briefcase, Phone, Smartphone, AlertTriangle } from 'lucide-react';
import { api } from '../services/api';

export default function Analyze() {
  const location = useLocation();
  const [type, setType] = useState((location.state as any)?.tab || 'text');
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleAnalyze = async () => {
    if (type === 'text' && !text) return;
    setLoading(true);
    try {
      // currently backend only supports text analysis easily, but we pass what we have
      // In a real scenario for images/pdfs we'd use FormData
      const res = await api.post('/analysis/text', { content: text || "Uploaded file content placeholder" });
      navigate('/results', { state: { result: res.data, from: '/analyze' } });
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const setExample = (content: string) => {
    setText(content);
    setType('text');
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-800 mb-2">Analyze Suspicious Content</h1>
        <p className="text-slate-500 text-sm">Choose the type of content you want to analyze and let our AI detect potential scams.</p>
      </div>

      {/* Tabs */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <button 
          onClick={() => setType('text')} 
          className={`text-left border rounded-2xl p-5 transition-all ${type === 'text' ? 'border-blue-300 bg-blue-50/50 shadow-sm ring-1 ring-blue-300' : 'border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50'}`}
        >
          <div className="flex items-center space-x-3 mb-2">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${type === 'text' ? 'text-blue-600' : 'text-blue-500 bg-blue-50'}`}>
              <FileText className="w-5 h-5" />
            </div>
            <span className={`font-bold text-sm ${type === 'text' ? 'text-blue-700' : 'text-slate-800'}`}>Text</span>
          </div>
          <p className={`text-[11px] leading-tight ${type === 'text' ? 'text-blue-600/80' : 'text-slate-500'}`}>Messages, emails, links</p>
        </button>

        <button 
          onClick={() => setType('image')} 
          className={`text-left border rounded-2xl p-5 transition-all ${type === 'image' ? 'border-blue-300 bg-blue-50/50 shadow-sm ring-1 ring-blue-300' : 'border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50'}`}
        >
          <div className="flex items-center space-x-3 mb-2">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${type === 'image' ? 'text-blue-600' : 'text-slate-500 bg-slate-100'}`}>
              <ImageIcon className="w-5 h-5" />
            </div>
            <span className={`font-bold text-sm ${type === 'image' ? 'text-blue-700' : 'text-slate-800'}`}>Image</span>
          </div>
          <p className={`text-[11px] leading-tight ${type === 'image' ? 'text-blue-600/80' : 'text-slate-500'}`}>Screenshots, photos</p>
        </button>

        <button 
          onClick={() => setType('pdf')} 
          className={`text-left border rounded-2xl p-5 transition-all ${type === 'pdf' ? 'border-blue-300 bg-blue-50/50 shadow-sm ring-1 ring-blue-300' : 'border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50'}`}
        >
          <div className="flex items-center space-x-3 mb-2">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${type === 'pdf' ? 'text-blue-600' : 'text-red-500 bg-red-50'}`}>
              <File className="w-5 h-5" />
            </div>
            <span className={`font-bold text-sm ${type === 'pdf' ? 'text-blue-700' : 'text-slate-800'}`}>PDF</span>
          </div>
          <p className={`text-[11px] leading-tight ${type === 'pdf' ? 'text-blue-600/80' : 'text-slate-500'}`}>Documents, invoices</p>
        </button>

        <button 
          onClick={() => setType('audio')} 
          className={`text-left border rounded-2xl p-5 transition-all ${type === 'audio' ? 'border-blue-300 bg-blue-50/50 shadow-sm ring-1 ring-blue-300' : 'border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50'}`}
        >
          <div className="flex items-center space-x-3 mb-2">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${type === 'audio' ? 'text-blue-600' : 'text-green-500 bg-green-50'}`}>
              <Mic className="w-5 h-5" />
            </div>
            <span className={`font-bold text-sm ${type === 'audio' ? 'text-blue-700' : 'text-slate-800'}`}>Audio</span>
          </div>
          <p className={`text-[11px] leading-tight ${type === 'audio' ? 'text-blue-600/80' : 'text-slate-500'}`}>Call recordings, audio files</p>
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Main Work Area */}
        <div className="lg:col-span-8 space-y-6">
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            
            {type === 'text' && (
              <>
                <h3 className="font-bold text-slate-800 text-lg mb-1">Enter Text to Analyze</h3>
                <p className="text-xs text-slate-500 mb-6">Paste a suspicious message, email, WhatsApp message, URL, or any other text here.</p>
                
                <textarea 
                  className="w-full h-48 px-4 py-4 bg-slate-50/50 border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-blue-500 focus:bg-white transition-all resize-none text-sm placeholder:text-slate-400 mb-4" 
                  placeholder="Type or paste your text here..."
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                ></textarea>
                
                <div className="flex justify-between items-center mb-6">
                  <span className="text-xs text-slate-400 font-medium">
                    {text.length} / 10,000 characters
                  </span>
                  <button 
                    onClick={() => setText('')}
                    className="flex items-center space-x-1.5 text-xs font-semibold text-blue-600 hover:text-blue-700 transition disabled:opacity-50"
                    disabled={!text}
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>Clear</span>
                  </button>
                </div>
                
                <button 
                  onClick={handleAnalyze} 
                  disabled={!text || loading}
                  className="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-8 rounded-xl shadow-md shadow-blue-600/20 transition-all disabled:opacity-50 text-sm flex items-center space-x-2"
                >
                  <Search className="w-4 h-4" />
                  <span>{loading ? 'Analyzing...' : 'Analyze'}</span>
                </button>
              </>
            )}

            {(type === 'image' || type === 'pdf' || type === 'audio') && (
              <div className="h-full min-h-[320px] flex flex-col">
                <h3 className="font-bold text-slate-800 text-lg mb-1">
                  {type === 'image' && 'Upload Image to Analyze'}
                  {type === 'pdf' && 'Upload PDF to Analyze'}
                  {type === 'audio' && 'Upload Audio to Analyze'}
                </h3>
                <p className="text-xs text-slate-500 mb-6">
                  {type === 'image' && 'Drop a screenshot or photo containing suspicious content.'}
                  {type === 'pdf' && 'Drop a suspicious document or invoice.'}
                  {type === 'audio' && 'Upload an audio recording for analysis.'}
                </p>
                
                <div className="flex-1 border-2 border-dashed border-slate-200 rounded-2xl bg-slate-50 flex flex-col items-center justify-center p-8 hover:bg-slate-100 hover:border-slate-300 transition cursor-pointer">
                  <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center shadow-sm mb-4">
                    {type === 'image' && <ImageIcon className="w-8 h-8 text-blue-500" />}
                    {type === 'pdf' && <File className="w-8 h-8 text-red-500" />}
                    {type === 'audio' && <Mic className="w-8 h-8 text-green-500" />}
                  </div>
                  <h4 className="font-bold text-slate-700 text-sm mb-1">Click to upload or drag and drop</h4>
                  <p className="text-xs text-slate-500">
                    {type === 'image' && 'JPG, PNG, GIF (Max 10MB)'}
                    {type === 'pdf' && 'PDF (Max 10MB)'}
                    {type === 'audio' && 'MP3, WAV, M4A (Max 25MB)'}
                  </p>
                </div>
              </div>
            )}
          </div>

          {/* Examples */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h3 className="font-bold text-slate-800 text-base">Example Suspicious Messages</h3>
                <p className="text-xs text-slate-500">Here are some examples of content you can analyze:</p>
              </div>
              <button className="flex items-center space-x-1.5 text-xs font-semibold text-blue-600 hover:text-blue-700 transition">
                <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" /></svg>
                <span>Use Example</span>
              </button>
            </div>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <div onClick={() => setExample("Your account will be blocked in 24 hours. Verify your KYC now: https://...")} className="border border-slate-100 rounded-xl p-4 hover:border-slate-300 hover:bg-slate-50 transition cursor-pointer">
                <div className="flex items-center space-x-2 mb-3">
                  <div className="w-8 h-8 bg-red-50 text-red-500 rounded-lg flex items-center justify-center shrink-0">
                    <Mail className="w-4 h-4" />
                  </div>
                  <h4 className="font-bold text-slate-800 text-xs">Bank KYC Scam</h4>
                </div>
                <p className="text-[11px] text-slate-500 leading-snug">"Your account will be blocked in 24 hours. Verify your KYC now: https://..."</p>
              </div>

              <div onClick={() => setExample("Congratulations! You have won ₹25 lakh. Claim now: http://...")} className="border border-slate-100 rounded-xl p-4 hover:border-slate-300 hover:bg-slate-50 transition cursor-pointer">
                <div className="flex items-center space-x-2 mb-3">
                  <div className="w-8 h-8 bg-green-50 text-green-500 rounded-lg flex items-center justify-center shrink-0">
                    <MessageSquare className="w-4 h-4" />
                  </div>
                  <h4 className="font-bold text-slate-800 text-xs">Lottery Scam</h4>
                </div>
                <p className="text-[11px] text-slate-500 leading-snug">"Congratulations! You have won ₹25 lakh. Claim now: http://..."</p>
              </div>

              <div onClick={() => setExample("Check this photo of you: http://unknown-link.com")} className="border border-slate-100 rounded-xl p-4 hover:border-slate-300 hover:bg-slate-50 transition cursor-pointer">
                <div className="flex items-center space-x-2 mb-3">
                  <div className="w-8 h-8 bg-purple-50 text-purple-500 rounded-lg flex items-center justify-center shrink-0">
                    <LinkIcon className="w-4 h-4" />
                  </div>
                  <h4 className="font-bold text-slate-800 text-xs">Suspicious Link</h4>
                </div>
                <p className="text-[11px] text-slate-500 leading-snug">"Check this photo of you: http://unknown-link.com"</p>
              </div>

              <div onClick={() => setExample("Please share your OTP to confirm your account.")} className="border border-slate-100 rounded-xl p-4 hover:border-slate-300 hover:bg-slate-50 transition cursor-pointer">
                <div className="flex items-center space-x-2 mb-3">
                  <div className="w-8 h-8 bg-blue-50 text-blue-500 rounded-lg flex items-center justify-center shrink-0">
                    <Phone className="w-4 h-4" />
                  </div>
                  <h4 className="font-bold text-slate-800 text-xs">OTP Request</h4>
                </div>
                <p className="text-[11px] text-slate-500 leading-snug">"Please share your OTP to confirm your account."</p>
              </div>
            </div>
          </div>
          
          {/* Alert */}
          <div className="bg-[#f0fdf4] border border-[#bbf7d0] rounded-2xl p-5 flex items-start space-x-4">
            <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center shrink-0 mt-0.5">
              <Lock className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-green-800 mb-1">Your Data is Secure</h3>
              <p className="text-xs text-green-700/80 leading-relaxed">
                All submissions are encrypted and processed securely. We do not store your sensitive content longer than necessary.
              </p>
            </div>
          </div>
        </div>

        {/* Right Info Column */}
        <div className="lg:col-span-4">
          <div className="bg-slate-50/80 rounded-2xl border border-slate-200 p-6 h-full flex flex-col">
            <div className="flex items-center space-x-3 mb-4">
              <div className="w-8 h-8 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center shrink-0">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" /></svg>
              </div>
              <h3 className="font-bold text-slate-800 text-sm">What can you analyze?</h3>
            </div>
            <p className="text-xs text-slate-500 mb-6 leading-relaxed">
              ScamShield analyzes multiple types of suspicious content using AI, machine learning and known scam patterns.
            </p>
            
            <div className="space-y-4">
              <div className="flex items-center space-x-3">
                <MessageSquare className="w-4 h-4 text-green-500" />
                <span className="text-xs font-medium text-slate-700">SMS messages</span>
              </div>
              <div className="flex items-center space-x-3">
                <Smartphone className="w-4 h-4 text-green-500" />
                <span className="text-xs font-medium text-slate-700">WhatsApp messages</span>
              </div>
              <div className="flex items-center space-x-3">
                <Mail className="w-4 h-4 text-purple-500" />
                <span className="text-xs font-medium text-slate-700">Email content</span>
              </div>
              <div className="flex items-center space-x-3">
                <LinkIcon className="w-4 h-4 text-blue-500" />
                <span className="text-xs font-medium text-slate-700">Suspicious links/URLs</span>
              </div>
              <div className="flex items-center space-x-3">
                <svg className="w-4 h-4 text-red-500" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/></svg>
                <span className="text-xs font-medium text-slate-700">Social media messages</span>
              </div>
              <div className="flex items-center space-x-3">
                <Briefcase className="w-4 h-4 text-orange-500" />
                <span className="text-xs font-medium text-slate-700">Bank and OTP related texts</span>
              </div>
              <div className="flex items-center space-x-3">
                <AlertTriangle className="w-4 h-4 text-red-600" />
                <span className="text-xs font-medium text-slate-700">Job, investment and lottery scams</span>
              </div>
              <div className="flex items-center space-x-3">
                <Search className="w-4 h-4 text-blue-600" />
                <span className="text-xs font-medium text-slate-700">Any other suspicious text</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

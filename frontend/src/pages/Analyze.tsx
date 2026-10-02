import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { FileText, Image as ImageIcon, File, Mic, Trash2, Search, Lock, Mail, Link as LinkIcon, MessageSquare, Briefcase, Phone, Smartphone, AlertTriangle } from 'lucide-react';
import { api } from '../services/api';

export default function Analyze() {
  const location = useLocation();
  const [type, setType] = useState((location.state as any)?.tab || 'text');
  const [ocrLanguage, setOcrLanguage] = useState('en');
  const [text, setText] = useState('');
  const [emailData, setEmailData] = useState({ subject: '', sender: '', body: '' });
  const [file, setFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const selectType = (nextType: string) => {
    setType(nextType);
    setFile(null);
  };

  const handleAnalyze = async () => {
    if (type === 'text' && !text.trim()) return;
    if (type === 'email' && !emailData.body.trim() && !emailData.subject.trim()) return;
    if ((type === 'image' || type === 'pdf' || type === 'audio') && !file) return;
    
    setLoading(true);
    try {
      let res;
      if (type === 'text') {
        res = await api.post('/analysis/text', { content: text });
      } else if (type === 'email') {
        res = await api.post('/analysis/email', emailData);
      } else {
        const formData = new FormData();
        formData.append('file', file as File);
        if (type === 'image') formData.append('language', ocrLanguage);
        res = await api.post(`/analysis/${type}`, formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        });
      }
      navigate(`/results/${res.data.id}`, { state: { result: res.data, from: '/analyze' } });
    } catch (err: any) {
      console.error(err);
      alert(err.response?.data?.detail || "An error occurred during analysis.");
    } finally {
      setLoading(false);
    }
  };

  const setExample = (content: string) => {
    setText(content);
    selectType('text');
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-text-main mb-2">Analyze Suspicious Content</h1>
        <p className="text-text-muted text-base">Choose the type of content you want to analyze and let our AI detect potential scams.</p>
      </div>

      {/* Tabs */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <button 
          onClick={() => selectType('text')}
          aria-pressed={type === 'text'}
          className={`text-left border rounded-2xl p-5 transition-all ${type === 'text' ? 'border-primary bg-primary/10 shadow-sm ring-1 ring-primary/30' : 'border-border-light bg-card hover:border-border-main hover:bg-background'}`}
        >
          <div className="flex items-center space-x-3 mb-2">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${type === 'text' ? 'text-primary' : 'text-primary bg-primary/10'}`}>
              <FileText className="w-5 h-5" />
            </div>
            <span className={`font-bold text-base ${type === 'text' ? 'text-primary' : 'text-text-main'}`}>Text</span>
          </div>
          <p className={`text-[11px] leading-tight ${type === 'text' ? 'text-primary/80' : 'text-text-muted'}`}>Messages, emails, links</p>
        </button>

        <button 
          onClick={() => selectType('image')}
          aria-pressed={type === 'image'}
          className={`text-left border rounded-2xl p-5 transition-all ${type === 'image' ? 'border-primary bg-primary/10 shadow-sm ring-1 ring-primary/30' : 'border-border-light bg-card hover:border-border-main hover:bg-background'}`}
        >
          <div className="flex items-center space-x-3 mb-2">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${type === 'image' ? 'text-primary' : 'text-text-muted bg-background'}`}>
              <ImageIcon className="w-5 h-5" />
            </div>
            <span className={`font-bold text-base ${type === 'image' ? 'text-primary' : 'text-text-main'}`}>Image</span>
          </div>
          <p className={`text-[11px] leading-tight ${type === 'image' ? 'text-primary/80' : 'text-text-muted'}`}>Screenshots, photos</p>
        </button>

        <button 
          onClick={() => selectType('email')}
          aria-pressed={type === 'email'}
          className={`text-left border rounded-2xl p-5 transition-all ${type === 'email' ? 'border-primary bg-primary/10 shadow-sm ring-1 ring-primary/30' : 'border-border-light bg-card hover:border-border-main hover:bg-background'}`}
        >
          <div className="flex items-center space-x-3 mb-2">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${type === 'email' ? 'text-primary' : 'text-amber-500 bg-amber-50'}`}>
              <Mail className="w-5 h-5" />
            </div>
            <span className={`font-bold text-base ${type === 'email' ? 'text-primary' : 'text-text-main'}`}>Email</span>
          </div>
          <p className={`text-[11px] leading-tight ${type === 'email' ? 'text-primary/80' : 'text-text-muted'}`}>Phishing, scams</p>
        </button>

        <button 
          onClick={() => selectType('pdf')}
          aria-pressed={type === 'pdf'}
          className={`text-left border rounded-2xl p-5 transition-all ${type === 'pdf' ? 'border-primary bg-primary/10 shadow-sm ring-1 ring-primary/30' : 'border-border-light bg-card hover:border-border-main hover:bg-background'}`}
        >
          <div className="flex items-center space-x-3 mb-2">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${type === 'pdf' ? 'text-primary' : 'text-danger bg-danger/10'}`}>
              <File className="w-5 h-5" />
            </div>
            <span className={`font-bold text-base ${type === 'pdf' ? 'text-primary' : 'text-text-main'}`}>PDF</span>
          </div>
          <p className={`text-[11px] leading-tight ${type === 'pdf' ? 'text-primary/80' : 'text-text-muted'}`}>Documents, invoices</p>
        </button>

        <button 
          onClick={() => selectType('audio')}
          aria-pressed={type === 'audio'}
          className={`text-left border rounded-2xl p-5 transition-all ${type === 'audio' ? 'border-primary bg-primary/10 shadow-sm ring-1 ring-primary/30' : 'border-border-light bg-card hover:border-border-main hover:bg-background'}`}
        >
          <div className="flex items-center space-x-3 mb-2">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${type === 'audio' ? 'text-primary' : 'text-success bg-success/10'}`}>
              <Mic className="w-5 h-5" />
            </div>
            <span className={`font-bold text-base ${type === 'audio' ? 'text-primary' : 'text-text-main'}`}>Audio</span>
          </div>
          <p className={`text-[11px] leading-tight ${type === 'audio' ? 'text-primary/80' : 'text-text-muted'}`}>Call recordings, audio files</p>
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Main Work Area */}
        <div className="lg:col-span-8 space-y-6">
          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
            
            {type === 'text' && (
              <>
                <h3 className="font-bold text-text-main text-lg mb-1">Enter Text to Analyze</h3>
                <p className="text-sm text-text-muted mb-6">Paste a suspicious message, email, WhatsApp message, URL, or any other text here.</p>
                
                <textarea 
                  className="w-full h-48 px-4 py-4 bg-background/50 border border-border-light rounded-xl focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary focus:bg-card transition-all resize-none text-base placeholder:text-text-muted mb-4" 
                  placeholder="Type or paste your text here..."
                  maxLength={10000}
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                ></textarea>
                
                <div className="flex justify-between items-center mb-6">
                  <span className="text-sm text-text-muted font-semibold">
                    {text.length} / 10,000 characters
                  </span>
                  <button 
                    onClick={() => setText('')}
                    className="flex items-center space-x-1.5 text-sm font-bold text-primary hover:text-blue-700 transition disabled:opacity-50"
                    disabled={!text}
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>Clear</span>
                  </button>
                </div>
                
                <button 
                  onClick={handleAnalyze} 
                  disabled={!text || loading}
                  className="bg-primary hover:bg-primary-hover text-white font-bold py-3 px-8 rounded-xl shadow-md shadow-primary/20 transition-all disabled:opacity-50 text-base flex items-center space-x-2"
                >
                  <Search className="w-4 h-4" />
                  <span>{loading ? 'Analyzing...' : 'Analyze'}</span>
                </button>
              </>
            )}

            {type === 'email' && (
              <div className="space-y-4">
                <h3 className="font-bold text-text-main text-lg mb-1">Analyze Suspicious Email</h3>
                <p className="text-sm text-text-muted mb-4">Paste the email subject, sender, and body content for analysis.</p>
                <input 
                  type="text"
                  placeholder="Subject"
                  value={emailData.subject}
                  onChange={(e) => setEmailData({...emailData, subject: e.target.value})}
                  className="w-full p-4 border border-border-light rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-all shadow-sm"
                />
                <input 
                  type="text"
                  placeholder="Sender (e.g. support@paypal.com)"
                  value={emailData.sender}
                  onChange={(e) => setEmailData({...emailData, sender: e.target.value})}
                  className="w-full p-4 border border-border-light rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-all shadow-sm"
                />
                <textarea
                  placeholder="Email body..."
                  className="w-full h-48 p-5 border border-border-light rounded-2xl resize-none focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-all text-base shadow-sm bg-background"
                  value={emailData.body}
                  onChange={(e) => setEmailData({...emailData, body: e.target.value})}
                ></textarea>
                <div className="flex justify-end mt-4">
                  <button 
                    onClick={handleAnalyze} 
                    disabled={(!emailData.body && !emailData.subject) || loading}
                    className="bg-primary hover:bg-primary-hover text-white font-bold py-3 px-8 rounded-xl shadow-md shadow-primary/20 transition-all disabled:opacity-50 text-base flex items-center space-x-2"
                  >
                    <Search className="w-4 h-4" />
                    <span>{loading ? 'Analyzing...' : 'Analyze'}</span>
                  </button>
                </div>
              </div>
            )}

            {(type === 'image' || type === 'pdf' || type === 'audio') && (
              <div className="h-full min-h-[320px] flex flex-col">
                <h3 className="font-bold text-text-main text-lg mb-1">
                  {type === 'image' && 'Upload Image to Analyze'}
                  {type === 'pdf' && 'Upload PDF to Analyze'}
                  {type === 'audio' && 'Upload Audio to Analyze'}
                </h3>
                <p className="text-sm text-text-muted mb-6">
                  {type === 'image' && 'Drop a screenshot or photo containing suspicious content.'}
                  {type === 'pdf' && 'Upload a text-searchable PDF. For a scanned page, upload an image instead.'}
                  {type === 'audio' && 'Upload an audio recording for analysis.'}
                </p>
                {type === 'image' && (
                  <label className="block text-sm font-semibold text-text-main mb-4">
                    Text language in image
                    <select
                      value={ocrLanguage}
                      onChange={(event) => setOcrLanguage(event.target.value)}
                      className="ml-3 rounded-lg border border-border-light bg-card px-3 py-2 text-text-main focus:outline-none focus:ring-2 focus:ring-primary"
                    >
                      <option value="en">English</option>
                      <option value="hi">Hindi</option>
                      <option value="te">Telugu</option>
                    </select>
                  </label>
                )}
                
                <label className="flex-1 border-2 border-dashed border-border-light rounded-2xl bg-background flex flex-col items-center justify-center p-8 hover:bg-background hover:border-border-main transition cursor-pointer relative overflow-hidden">
                  <input 
                    type="file" 
                    className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                    onChange={(e) => {
                      const selectedFile = e.target.files?.[0] || null;
                      const maxSize = type === 'audio' ? 25 * 1024 * 1024 : 10 * 1024 * 1024;
                      if (selectedFile && selectedFile.size > maxSize) {
                        alert(`File is too large. Maximum size is ${type === 'audio' ? '25MB' : '10MB'}.`);
                        e.target.value = '';
                        setFile(null);
                        return;
                      }
                      setFile(selectedFile);
                    }}
                    accept={
                      type === 'image' ? "image/png,image/jpeg,image/gif" :
                      type === 'pdf' ? "application/pdf" : 
                      "audio/*"
                    }
                  />
                  {!file ? (
                    <>
                      <div className="w-16 h-16 bg-card rounded-full flex items-center justify-center shadow-sm mb-4">
                        {type === 'image' && <ImageIcon className="w-8 h-8 text-primary" />}
                        {type === 'pdf' && <File className="w-8 h-8 text-danger" />}
                        {type === 'audio' && <Mic className="w-8 h-8 text-success" />}
                      </div>
                      <h4 className="font-bold text-text-secondary text-base mb-1">Click to upload or drag and drop</h4>
                      <p className="text-sm text-text-muted">
                        {type === 'image' && 'JPG, PNG, GIF (Max 10MB)'}
                        {type === 'pdf' && 'PDF (Max 10MB)'}
                        {type === 'audio' && 'MP3, WAV, M4A (Max 25MB)'}
                      </p>
                    </>
                  ) : (
                    <div className="flex flex-col items-center text-center">
                       <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center shadow-sm mb-4 text-primary">
                         <File className="w-8 h-8" />
                       </div>
                       <h4 className="font-bold text-text-main text-lg mb-1">{file.name}</h4>
                       <p className="text-sm text-text-muted mb-6">{(file.size / 1024 / 1024).toFixed(2)} MB</p>
                       <div className="flex space-x-3">
                         <button onClick={(e) => { e.preventDefault(); setFile(null); }} className="px-4 py-2 border border-border-light text-text-secondary rounded-lg font-bold hover:bg-background transition z-10 relative">Cancel</button>
                         <button onClick={handleAnalyze} disabled={loading} className="px-6 py-2 bg-primary text-white rounded-lg font-bold hover:bg-primary-hover shadow-md shadow-primary/20 transition z-10 relative">
                           {loading ? 'Analyzing...' : 'Analyze'}
                         </button>
                       </div>
                    </div>
                  )}
                </label>
              </div>
            )}
          </div>

          {/* Examples */}
          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h3 className="font-bold text-text-main text-lg">Example Suspicious Messages</h3>
                <p className="text-sm text-text-muted">Here are some examples of content you can analyze:</p>
              </div>
              <button className="flex items-center space-x-1.5 text-sm font-bold text-primary hover:text-blue-700 transition">
                <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" /></svg>
                <span>Use Example</span>
              </button>
            </div>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <div onClick={() => setExample("Your account will be blocked in 24 hours. Verify your KYC now: https://...")} className="border border-border-light rounded-xl p-4 hover:border-border-main hover:bg-background transition cursor-pointer">
                <div className="flex items-center space-x-2 mb-3">
                  <div className="w-8 h-8 bg-danger/10 text-danger rounded-lg flex items-center justify-center shrink-0">
                    <Mail className="w-4 h-4" />
                  </div>
                  <h4 className="font-bold text-text-main text-sm">Bank KYC Scam</h4>
                </div>
                <p className="text-[11px] text-text-muted leading-snug">"Your account will be blocked in 24 hours. Verify your KYC now: https://..."</p>
              </div>

              <div onClick={() => setExample("Congratulations! You have won ₹25 lakh. Claim now: http://...")} className="border border-border-light rounded-xl p-4 hover:border-border-main hover:bg-background transition cursor-pointer">
                <div className="flex items-center space-x-2 mb-3">
                  <div className="w-8 h-8 bg-success/10 text-success rounded-lg flex items-center justify-center shrink-0">
                    <MessageSquare className="w-4 h-4" />
                  </div>
                  <h4 className="font-bold text-text-main text-sm">Lottery Scam</h4>
                </div>
                <p className="text-[11px] text-text-muted leading-snug">"Congratulations! You have won ₹25 lakh. Claim now: http://..."</p>
              </div>

              <div onClick={() => setExample("Check this photo of you: http://unknown-link.com")} className="border border-border-light rounded-xl p-4 hover:border-border-main hover:bg-background transition cursor-pointer">
                <div className="flex items-center space-x-2 mb-3">
                  <div className="w-8 h-8 bg-purple-50 text-purple-500 rounded-lg flex items-center justify-center shrink-0">
                    <LinkIcon className="w-4 h-4" />
                  </div>
                  <h4 className="font-bold text-text-main text-sm">Suspicious Link</h4>
                </div>
                <p className="text-[11px] text-text-muted leading-snug">"Check this photo of you: http://unknown-link.com"</p>
              </div>

              <div onClick={() => setExample("Please share your OTP to confirm your account.")} className="border border-border-light rounded-xl p-4 hover:border-border-main hover:bg-background transition cursor-pointer">
                <div className="flex items-center space-x-2 mb-3">
                  <div className="w-8 h-8 bg-primary/10 text-primary rounded-lg flex items-center justify-center shrink-0">
                    <Phone className="w-4 h-4" />
                  </div>
                  <h4 className="font-bold text-text-main text-sm">OTP Request</h4>
                </div>
                <p className="text-[11px] text-text-muted leading-snug">"Please share your OTP to confirm your account."</p>
              </div>
            </div>
          </div>
          
          {/* Alert */}
          <div className="bg-[#f0fdf4] border border-[#bbf7d0] rounded-2xl p-5 flex items-start space-x-4">
            <div className="w-10 h-10 bg-success/20 rounded-full flex items-center justify-center shrink-0 mt-0.5">
              <Lock className="w-5 h-5 text-success" />
            </div>
            <div>
              <h3 className="text-base font-bold text-success mb-1">Your Data is Secure</h3>
              <p className="text-sm text-success/80 leading-relaxed">
                All submissions are encrypted and processed securely. We do not store your sensitive content longer than necessary.
              </p>
            </div>
          </div>
        </div>

        {/* Right Info Column */}
        <div className="lg:col-span-4">
          <div className="bg-background/80 rounded-2xl border border-border-light p-6 h-full flex flex-col">
            <div className="flex items-center space-x-3 mb-4">
              <div className="w-8 h-8 bg-primary/10 text-primary rounded-full flex items-center justify-center shrink-0">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" /></svg>
              </div>
              <h3 className="font-bold text-text-main text-base">What can you analyze?</h3>
            </div>
            <p className="text-sm text-text-muted mb-6 leading-relaxed">
              ScamShield analyzes multiple types of suspicious content using AI, machine learning and known scam patterns.
            </p>
            
            <div className="space-y-4">
              <div className="flex items-center space-x-3">
                <MessageSquare className="w-4 h-4 text-success" />
                <span className="text-sm font-semibold text-text-secondary">SMS messages</span>
              </div>
              <div className="flex items-center space-x-3">
                <Smartphone className="w-4 h-4 text-success" />
                <span className="text-sm font-semibold text-text-secondary">WhatsApp messages</span>
              </div>
              <div className="flex items-center space-x-3">
                <Mail className="w-4 h-4 text-purple-500" />
                <span className="text-sm font-semibold text-text-secondary">Email content</span>
              </div>
              <div className="flex items-center space-x-3">
                <LinkIcon className="w-4 h-4 text-primary" />
                <span className="text-sm font-semibold text-text-secondary">Suspicious links/URLs</span>
              </div>
              <div className="flex items-center space-x-3">
                <svg className="w-4 h-4 text-danger" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/></svg>
                <span className="text-sm font-semibold text-text-secondary">Social media messages</span>
              </div>
              <div className="flex items-center space-x-3">
                <Briefcase className="w-4 h-4 text-warning" />
                <span className="text-sm font-semibold text-text-secondary">Bank and OTP related texts</span>
              </div>
              <div className="flex items-center space-x-3">
                <AlertTriangle className="w-4 h-4 text-danger" />
                <span className="text-sm font-semibold text-text-secondary">Job, investment and lottery scams</span>
              </div>
              <div className="flex items-center space-x-3">
                <Search className="w-4 h-4 text-primary" />
                <span className="text-sm font-semibold text-text-secondary">Any other suspicious text</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

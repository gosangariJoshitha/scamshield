import { Link } from 'react-router-dom';
import { 
  MessageSquare, MessageCircle, Mail, Image, FileText, Mic, ShieldAlert, 
  ShieldCheck, ArrowRight, FileSearch, CheckCircle, UploadCloud, Cpu, Eye, Network, AlertTriangle, FileLock2, Search
} from 'lucide-react';

export default function Landing() {
  return (
    <div className="flex-1 bg-[#0a0f1c] text-white flex flex-col relative overflow-x-hidden">
      {/* Background gradients */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[800px] bg-blue-900/20 rounded-full blur-[120px] pointer-events-none"></div>
      
      {/* Hero Section */}
      <section id="home" className="max-w-7xl mx-auto px-8 w-full flex flex-col lg:flex-row items-center pt-20 pb-24 relative z-10 min-h-[90vh]">
        <div className="lg:w-1/2 pr-8 mb-16 lg:mb-0">
          <h1 className="text-5xl lg:text-7xl font-bold mb-6 leading-tight">
            Don't Just Detect Scams.<br/>
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-blue-600">Understand Them.</span>
          </h1>
          <p className="text-lg text-slate-300 mb-10 max-w-xl leading-relaxed">
            Analyze suspicious messages, screenshots, PDFs and audio — and understand exactly why something looks risky.
          </p>
          <div className="flex space-x-4">
            <Link to="/signup" className="bg-blue-600 hover:bg-blue-500 text-white font-bold py-3 px-8 rounded-xl shadow-lg shadow-blue-500/30 transition-all flex items-center space-x-2">
              <span>Analyze Something</span>
              <ArrowRight className="w-5 h-5" />
            </Link>
            <a href="#how-it-works" className="border border-slate-700 hover:border-slate-500 hover:bg-slate-800 text-white font-bold py-3 px-8 rounded-xl transition-all">
              See How It Works
            </a>
          </div>
        </div>
        
        {/* Right side Interactive Analysis Visualization */}
        <div className="lg:w-1/2 flex justify-center relative w-full">
          <div className="w-full max-w-md relative">
            <div className="absolute inset-0 bg-blue-600/10 blur-3xl rounded-full"></div>
            
            {/* Suspicious Message Card */}
            <div className="bg-[#111827] border border-slate-700 rounded-2xl p-5 mb-4 shadow-xl relative z-10">
              <div className="flex items-center space-x-2 mb-3">
                <AlertTriangle className="w-4 h-4 text-orange-400" />
                <span className="text-xs font-bold text-orange-400 uppercase tracking-wider">Suspicious Message</span>
              </div>
              <p className="text-sm text-slate-300 leading-relaxed mb-4">
                Your KYC has expired. Verify your account within 30 minutes or it will be permanently blocked.
              </p>
              <div className="bg-slate-900 px-3 py-2 rounded border border-slate-800 font-mono text-xs text-blue-400 truncate">
                https://verify-bank.example.com
              </div>
            </div>

            <div className="flex justify-center my-3 relative z-10">
               <div className="bg-blue-900/50 border border-blue-500/30 px-4 py-1.5 rounded-full flex flex-col items-center shadow-lg shadow-blue-900/20">
                 <div className="flex items-center space-x-2">
                   <Cpu className="w-4 h-4 text-blue-400" />
                   <span className="text-xs font-bold text-blue-200 uppercase tracking-wider">ScamShield AI</span>
                 </div>
                 <span className="text-[10px] text-blue-300/70 mt-0.5">Example Analysis</span>
               </div>
            </div>

            {/* Analysis Result Card */}
            <div className="bg-gradient-to-b from-[#1a111a] to-[#0a0f1c] border border-red-900/50 rounded-2xl p-6 shadow-2xl relative z-10">
              <div className="flex justify-between items-start mb-6 border-b border-red-900/30 pb-4">
                <div>
                  <div className="text-4xl font-bold text-red-500 mb-1">87<span className="text-sm text-slate-500">/100</span></div>
                  <div className="text-xs font-bold text-red-600 bg-red-500/10 px-2 py-1 rounded inline-block uppercase tracking-wider">High Risk</div>
                </div>
                <div className="text-right">
                   <div className="text-sm font-bold text-slate-200">Bank KYC Scam</div>
                </div>
              </div>
              
              <div className="space-y-2 mb-6">
                <div className="flex items-center space-x-2 text-xs text-slate-300">
                  <CheckCircle className="w-3.5 h-3.5 text-red-400 shrink-0" />
                  <span>Urgency detected</span>
                </div>
                <div className="flex items-center space-x-2 text-xs text-slate-300">
                  <CheckCircle className="w-3.5 h-3.5 text-red-400 shrink-0" />
                  <span>Account threat</span>
                </div>
                <div className="flex items-center space-x-2 text-xs text-slate-300">
                  <CheckCircle className="w-3.5 h-3.5 text-red-400 shrink-0" />
                  <span>KYC request</span>
                </div>
                <div className="flex items-center space-x-2 text-xs text-slate-300">
                  <CheckCircle className="w-3.5 h-3.5 text-red-400 shrink-0" />
                  <span>Suspicious URL</span>
                </div>
              </div>

              <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-3 flex items-start space-x-3">
                <ShieldAlert className="w-4 h-4 text-red-400 shrink-0 mt-0.5" />
                <span className="text-xs text-red-200 font-medium">Don't click the link. Verify directly through the official bank app.</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Supported Inputs Section */}
      <section className="py-16 bg-[#0d1326] relative z-10 border-t border-slate-800/50">
        <div className="max-w-7xl mx-auto px-8">
          <div className="text-center mb-12">
            <h2 className="text-2xl lg:text-3xl font-bold mb-4">Whatever the message looks like, ScamShield can read it.</h2>
          </div>
          
          <div className="flex flex-wrap justify-center gap-4 lg:gap-6 max-w-5xl mx-auto">
            <div className="flex items-center space-x-3 bg-[#111827] px-6 py-4 rounded-xl border border-slate-800 w-36 justify-center">
              <MessageSquare className="w-5 h-5 text-blue-400" />
              <span className="text-sm font-bold text-slate-300">SMS</span>
            </div>
            <div className="flex items-center space-x-3 bg-[#111827] px-6 py-4 rounded-xl border border-slate-800 w-36 justify-center">
              <MessageCircle className="w-5 h-5 text-green-400" />
              <span className="text-sm font-bold text-slate-300">WhatsApp</span>
            </div>
            <div className="flex items-center space-x-3 bg-[#111827] px-6 py-4 rounded-xl border border-slate-800 w-36 justify-center">
              <Mail className="w-5 h-5 text-red-400" />
              <span className="text-sm font-bold text-slate-300">Email</span>
            </div>
            <div className="flex items-center space-x-3 bg-[#111827] px-6 py-4 rounded-xl border border-slate-800 w-36 justify-center">
              <Image className="w-5 h-5 text-purple-400" />
              <span className="text-sm font-bold text-slate-300">Image</span>
            </div>
            <div className="flex items-center space-x-3 bg-[#111827] px-6 py-4 rounded-xl border border-slate-800 w-36 justify-center">
              <FileText className="w-5 h-5 text-orange-400" />
              <span className="text-sm font-bold text-slate-300">PDF</span>
            </div>
            <div className="flex items-center space-x-3 bg-[#111827] px-6 py-4 rounded-xl border border-slate-800 w-36 justify-center">
              <Mic className="w-5 h-5 text-pink-400" />
              <span className="text-sm font-bold text-slate-300">Audio</span>
            </div>
          </div>
        </div>
      </section>

      {/* Detection Is Only the Beginning */}
      <section className="py-24 relative z-10 border-t border-slate-800/50">
        <div className="max-w-7xl mx-auto px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl lg:text-4xl font-bold mb-4">Detection Is Only the Beginning.</h2>
            <p className="text-slate-400 max-w-2xl mx-auto">Unlike traditional classifiers, our pipeline extracts, detects, and reasons.</p>
          </div>

          <div className="flex flex-col lg:flex-row items-stretch justify-center gap-8 max-w-5xl mx-auto">
            {/* Traditional */}
            <div className="lg:w-1/3 bg-[#111827] border border-slate-800 p-8 rounded-2xl flex flex-col items-center">
              <h3 className="text-sm font-bold text-slate-500 uppercase tracking-wider mb-8">Traditional Detection</h3>
              <div className="bg-slate-800 border border-slate-700 px-6 py-3 rounded-lg text-sm w-full text-center text-slate-300 mb-4">Message</div>
              <ArrowRight className="w-5 h-5 text-slate-600 rotate-90 mb-4" />
              <div className="flex justify-between w-full space-x-2">
                <div className="bg-red-900/30 border border-red-500/30 text-red-400 px-4 py-2 rounded text-xs text-center w-1/2">SCAM</div>
                <div className="bg-green-900/30 border border-green-500/30 text-green-400 px-4 py-2 rounded text-xs text-center w-1/2">NOT SCAM</div>
              </div>
            </div>

            {/* ScamShield */}
            <div className="lg:w-2/3 bg-gradient-to-b from-[#111827] to-blue-900/10 border border-blue-500/20 p-8 rounded-2xl flex flex-col items-center shadow-[0_0_30px_rgba(37,99,235,0.05)]">
              <h3 className="text-sm font-bold text-blue-400 uppercase tracking-wider mb-8">ScamShield Pipeline</h3>
              
              <div className="w-full grid grid-cols-2 sm:grid-cols-3 md:grid-cols-7 gap-2 text-center text-xs font-bold text-slate-300 items-center">
                 <div className="bg-slate-800 border border-slate-700 py-2 rounded shadow-md">Message</div>
                 <ArrowRight className="w-4 h-4 text-slate-600 mx-auto hidden md:block" />
                 <div className="bg-slate-800 border border-slate-700 py-2 rounded shadow-md">Extract</div>
                 <ArrowRight className="w-4 h-4 text-slate-600 mx-auto hidden md:block" />
                 <div className="bg-slate-800 border border-slate-700 py-2 rounded shadow-md">Detect</div>
                 <ArrowRight className="w-4 h-4 text-slate-600 mx-auto hidden md:block" />
                 <div className="bg-slate-800 border border-slate-700 py-2 rounded shadow-md">Retrieve Evidence</div>
                 <ArrowRight className="w-4 h-4 text-slate-600 mx-auto hidden md:block" />
                 <div className="bg-slate-800 border border-slate-700 py-2 rounded shadow-md">Explain</div>
                 <ArrowRight className="w-4 h-4 text-slate-600 mx-auto hidden md:block" />
                 <div className="bg-red-900/30 border border-red-500/30 text-red-400 py-2 rounded shadow-md">Risk Score</div>
                 <ArrowRight className="w-4 h-4 text-slate-600 mx-auto hidden md:block" />
                 <div className="bg-blue-600 border border-blue-500 text-white py-2 rounded shadow-md">Safe Action</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* How it Works Section */}
      <section id="how-it-works" className="py-24 bg-[#0d1326] relative z-10 border-t border-slate-800/50">
        <div className="max-w-7xl mx-auto px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl lg:text-4xl font-bold mb-4">From Suspicion to Understanding</h2>
            <p className="text-slate-400 max-w-2xl mx-auto">See how our AI pipeline analyzes and explains suspicious content.</p>
          </div>
          
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-6 relative">
            <div className="hidden lg:block absolute top-10 left-12 right-12 h-0.5 bg-slate-800 z-0"></div>
            
            <div className="relative z-10 flex flex-col items-center text-center">
              <div className="w-20 h-20 bg-[#111827] border border-slate-700 rounded-full flex items-center justify-center mb-4">
                <span className="text-xs font-bold text-slate-500 absolute top-2">01</span>
                <UploadCloud className="w-6 h-6 text-blue-400 mt-2" />
              </div>
              <h3 className="text-sm font-bold mb-2">INPUT</h3>
              <p className="text-slate-500 text-xs">Paste or upload suspicious content</p>
            </div>

            <div className="relative z-10 flex flex-col items-center text-center">
              <div className="w-20 h-20 bg-[#111827] border border-slate-700 rounded-full flex items-center justify-center mb-4">
                <span className="text-xs font-bold text-slate-500 absolute top-2">02</span>
                <FileSearch className="w-6 h-6 text-blue-400 mt-2" />
              </div>
              <h3 className="text-sm font-bold mb-2">EXTRACT</h3>
              <p className="text-slate-500 text-xs">Text • OCR • PDF • Audio</p>
            </div>

            <div className="relative z-10 flex flex-col items-center text-center">
              <div className="w-20 h-20 bg-[#111827] border border-slate-700 rounded-full flex items-center justify-center mb-4">
                <span className="text-xs font-bold text-slate-500 absolute top-2">03</span>
                <Search className="w-6 h-6 text-blue-400 mt-2" />
              </div>
              <h3 className="text-sm font-bold mb-2">DETECT</h3>
              <p className="text-slate-500 text-xs">ML identifies suspicious patterns</p>
            </div>

            <div className="relative z-10 flex flex-col items-center text-center">
              <div className="w-20 h-20 bg-[#111827] border border-slate-700 rounded-full flex items-center justify-center mb-4">
                <span className="text-xs font-bold text-slate-500 absolute top-2">04</span>
                <Network className="w-6 h-6 text-blue-400 mt-2" />
              </div>
              <h3 className="text-sm font-bold mb-2">VERIFY</h3>
              <p className="text-slate-500 text-xs">RAG retrieves relevant scam evidence</p>
            </div>

            <div className="relative z-10 flex flex-col items-center text-center">
              <div className="w-20 h-20 bg-[#111827] border border-slate-700 rounded-full flex items-center justify-center mb-4">
                <span className="text-xs font-bold text-slate-500 absolute top-2">05</span>
                <Eye className="w-6 h-6 text-blue-400 mt-2" />
              </div>
              <h3 className="text-sm font-bold mb-2">EXPLAIN</h3>
              <p className="text-slate-500 text-xs">LLM explains the indicators and reasoning</p>
            </div>

            <div className="relative z-10 flex flex-col items-center text-center">
              <div className="w-20 h-20 bg-[#111827] border border-blue-500/50 shadow-[0_0_15px_rgba(37,99,235,0.2)] rounded-full flex items-center justify-center mb-4">
                <span className="text-xs font-bold text-blue-300 absolute top-2">06</span>
                <ShieldCheck className="w-6 h-6 text-blue-400 mt-2" />
              </div>
              <h3 className="text-sm font-bold text-blue-400 mb-2">PROTECT</h3>
              <p className="text-slate-400 text-xs">Risk Engine recommends a safe action</p>
            </div>
          </div>
        </div>
      </section>

      {/* Explainability Demo Section */}
      <section className="py-24 relative z-10 border-t border-slate-800/50">
        <div className="max-w-7xl mx-auto px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl lg:text-4xl font-bold mb-4">A Score Isn't Enough. Show Me Why.</h2>
            <p className="text-slate-400 max-w-2xl mx-auto">We highlight exactly what makes a message dangerous so you can make informed decisions.</p>
          </div>

          <div className="flex flex-col lg:flex-row gap-8 items-stretch">
            {/* Left: Score Box */}
            <div className="lg:w-1/3 bg-[#111827] border border-slate-800 rounded-2xl p-8 flex flex-col justify-center items-center text-center relative overflow-hidden">
              <div className="absolute top-0 right-0 w-32 h-32 bg-red-500/10 blur-3xl rounded-full"></div>
              <div className="text-7xl font-bold text-red-500 mb-2">87</div>
              <div className="text-sm font-bold text-red-400 tracking-widest uppercase mb-6">High Risk</div>
              <div className="text-xl font-bold text-white mb-2">Bank KYC Scam</div>
              <p className="text-sm text-slate-400">ML prediction: <strong className="text-slate-200">91% scam probability</strong></p>
            </div>

            {/* Right: Explanations */}
            <div className="lg:w-2/3 bg-[#111827] border border-slate-800 rounded-2xl p-8 flex flex-col justify-between">
              <div>
                <h3 className="text-sm font-bold text-slate-500 tracking-wider uppercase mb-6 border-b border-slate-800 pb-2">Why was this flagged?</h3>
                <div className="grid sm:grid-cols-2 gap-6 mb-8">
                  <div>
                    <div className="flex items-center space-x-2 mb-1">
                      <span className="text-xs font-mono text-red-400 bg-red-400/10 px-1.5 py-0.5 rounded">01</span>
                      <h4 className="font-bold text-slate-200 text-sm">Urgency</h4>
                    </div>
                    <p className="text-xs text-slate-400 ml-8">"within 30 minutes"</p>
                  </div>
                  <div>
                    <div className="flex items-center space-x-2 mb-1">
                      <span className="text-xs font-mono text-red-400 bg-red-400/10 px-1.5 py-0.5 rounded">02</span>
                      <h4 className="font-bold text-slate-200 text-sm">Impersonation</h4>
                    </div>
                    <p className="text-xs text-slate-400 ml-8">Claims to represent a bank</p>
                  </div>
                  <div>
                    <div className="flex items-center space-x-2 mb-1">
                      <span className="text-xs font-mono text-red-400 bg-red-400/10 px-1.5 py-0.5 rounded">03</span>
                      <h4 className="font-bold text-slate-200 text-sm">Sensitive Request</h4>
                    </div>
                    <p className="text-xs text-slate-400 ml-8">Requests KYC verification</p>
                  </div>
                  <div>
                    <div className="flex items-center space-x-2 mb-1">
                      <span className="text-xs font-mono text-red-400 bg-red-400/10 px-1.5 py-0.5 rounded">04</span>
                      <h4 className="font-bold text-slate-200 text-sm">Suspicious Link</h4>
                    </div>
                    <p className="text-xs text-slate-400 ml-8">Domain doesn't match institution</p>
                  </div>
                </div>
              </div>

              <div className="grid sm:grid-cols-2 gap-6">
                <div>
                  <h3 className="text-xs font-bold text-slate-500 tracking-wider uppercase mb-3">Supporting Evidence</h3>
                  <div className="space-y-2">
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-slate-300">Bank KYC Scam</span>
                      <span className="text-blue-400 font-mono">92% similar</span>
                    </div>
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-slate-300">Phishing Pattern</span>
                      <span className="text-blue-400 font-mono">86% similar</span>
                    </div>
                  </div>
                </div>
                <div className="bg-blue-900/20 border border-blue-500/30 rounded-xl p-4">
                   <div className="flex items-center space-x-2 mb-2">
                     <ShieldCheck className="w-4 h-4 text-blue-400" />
                     <h4 className="text-xs font-bold text-blue-300 uppercase tracking-wider">Recommended Action</h4>
                   </div>
                   <p className="text-xs text-blue-100/70 leading-relaxed">
                     Do not click the link. Verify directly through the official bank application.
                   </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-24 bg-[#0d1326] relative z-10 border-t border-slate-800/50">
        <div className="max-w-7xl mx-auto px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl lg:text-4xl font-bold mb-4">Core Features</h2>
            <p className="text-slate-400 max-w-2xl mx-auto">Built with cutting-edge technology to keep you secure.</p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div className="bg-[#111827] border border-slate-800 p-8 rounded-2xl hover:border-blue-500/50 hover:-translate-y-1 transition-all group">
              <div className="w-12 h-12 bg-blue-900/30 group-hover:bg-blue-600/20 rounded-xl flex items-center justify-center mb-6 transition-colors">
                <Network className="w-6 h-6 text-blue-400" />
              </div>
              <h3 className="text-xl font-bold mb-3">Multi-Channel Detection</h3>
              <p className="text-slate-400 text-sm leading-relaxed">Analyze messages, screenshots, PDFs and audio through a unified pipeline using advanced OCR and speech processing.</p>
            </div>
            
            <div className="bg-[#111827] border border-slate-800 p-8 rounded-2xl hover:border-blue-500/50 hover:-translate-y-1 transition-all group">
              <div className="w-12 h-12 bg-blue-900/30 group-hover:bg-blue-600/20 rounded-xl flex items-center justify-center mb-6 transition-colors">
                <Eye className="w-6 h-6 text-blue-400" />
              </div>
              <h3 className="text-xl font-bold mb-3">Explainable AI (XAI)</h3>
              <p className="text-slate-400 text-sm leading-relaxed">See the indicators and reasoning behind a suspicious classification so you can understand the actual threat.</p>
            </div>
            
            <div className="bg-[#111827] border border-slate-800 p-8 rounded-2xl hover:border-blue-500/50 hover:-translate-y-1 transition-all group">
              <div className="w-12 h-12 bg-blue-900/30 group-hover:bg-blue-600/20 rounded-xl flex items-center justify-center mb-6 transition-colors">
                <FileSearch className="w-6 h-6 text-blue-400" />
              </div>
              <h3 className="text-xl font-bold mb-3">Evidence-Based Risk Analysis</h3>
              <p className="text-slate-400 text-sm leading-relaxed">ScamShield combines model predictions, known scam patterns and detected indicators to build an explainable risk assessment.</p>
            </div>
          </div>
        </div>
      </section>

      {/* What We Detect */}
      <section className="py-24 relative z-10 border-t border-slate-800/50">
        <div className="max-w-7xl mx-auto px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl lg:text-4xl font-bold mb-4">What We Detect</h2>
            <p className="text-slate-400 max-w-2xl mx-auto">Our models are trained to recognize a wide variety of evolving threat vectors.</p>
          </div>

          <div className="flex flex-wrap justify-center gap-4 max-w-4xl mx-auto">
            <div className="bg-[#111827] border border-slate-800 px-6 py-3 rounded-full text-sm font-bold text-slate-300">Bank & KYC</div>
            <div className="bg-[#111827] border border-slate-800 px-6 py-3 rounded-full text-sm font-bold text-slate-300">OTP / UPI</div>
            <div className="bg-[#111827] border border-slate-800 px-6 py-3 rounded-full text-sm font-bold text-slate-300">Phishing</div>
            <div className="bg-[#111827] border border-slate-800 px-6 py-3 rounded-full text-sm font-bold text-slate-300">Job Scams</div>
            <div className="bg-[#111827] border border-slate-800 px-6 py-3 rounded-full text-sm font-bold text-slate-300">Investment</div>
            <div className="bg-[#111827] border border-slate-800 px-6 py-3 rounded-full text-sm font-bold text-slate-300">Courier Scams</div>
            <div className="bg-[#111827] border border-slate-800 px-6 py-3 rounded-full text-sm font-bold text-slate-300">Digital Arrest</div>
            <div className="bg-[#111827] border border-slate-800 px-6 py-3 rounded-full text-sm font-bold text-slate-300">Customer Support</div>
            <div className="bg-[#111827] border border-slate-800 px-6 py-3 rounded-full text-sm font-bold text-slate-300">Account Takeover</div>
            <div className="bg-[#111827] border border-slate-800 px-6 py-3 rounded-full text-sm font-bold text-slate-300">SIM Swap</div>
          </div>
          <p className="text-center text-slate-500 text-sm mt-8">And more evolving scam patterns.</p>
        </div>
      </section>

      {/* Context Matters More Than Keywords Section */}
      <section className="py-24 bg-[#0d1326] relative z-10 border-t border-slate-800/50">
         <div className="max-w-7xl mx-auto px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl lg:text-4xl font-bold mb-4">Context Matters More Than Keywords.</h2>
            <p className="text-slate-400 max-w-2xl mx-auto">ScamShield considers the message context, detected indicators and supporting evidence instead of relying on a single keyword.</p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            <div className="bg-[#111827] border border-slate-800 p-6 rounded-2xl flex flex-col h-full">
              <div className="bg-slate-900 border border-slate-700 p-4 rounded-xl mb-4 text-sm text-slate-300 italic flex-grow">
                "Your parcel could not be delivered. Pay ₹49 to reschedule at evri-post.com"
              </div>
              <div className="flex items-center space-x-2 mt-auto">
                <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                <span className="font-bold text-red-400 text-sm">Delivery Scam</span>
              </div>
            </div>

            <div className="bg-[#111827] border border-slate-800 p-6 rounded-2xl flex flex-col h-full">
              <div className="bg-slate-900 border border-slate-700 p-4 rounded-xl mb-4 text-sm text-slate-300 italic flex-grow">
                "Your OTP for login is 483921. Do not share this code with anyone."
              </div>
              <div className="flex items-center space-x-2 mt-auto">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                <span className="font-bold text-green-400 text-sm">Potentially Genuine</span>
              </div>
            </div>

            <div className="bg-[#111827] border border-slate-800 p-6 rounded-2xl flex flex-col h-full">
              <div className="bg-slate-900 border border-slate-700 p-4 rounded-xl mb-4 text-sm text-slate-300 italic flex-grow">
                "Congratulations! You won ₹25 lakh. Pay ₹999 processing fee to claim."
              </div>
              <div className="flex items-center space-x-2 mt-auto">
                <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                <span className="font-bold text-red-400 text-sm">Lottery Scam</span>
              </div>
            </div>
          </div>
         </div>
      </section>


      {/* Security Section */}
      <section id="security" className="py-24 bg-[#0d1326] relative z-10 border-t border-slate-800/50">
        <div className="max-w-7xl mx-auto px-8 flex flex-col md:flex-row items-center">
          <div className="md:w-1/2 pr-12 mb-12 md:mb-0">
            <h2 className="text-3xl lg:text-4xl font-bold mb-6">Your Privacy is our Priority</h2>
            <p className="text-slate-400 mb-8 leading-relaxed">
              We understand that the messages you analyze might contain sensitive or personal information. ScamShield is built from the ground up with a privacy-first architecture.
            </p>
            <ul className="space-y-4 mb-8">
              <li className="flex items-start space-x-3">
                <CheckCircle className="w-5 h-5 text-blue-400 shrink-0 mt-0.5" />
                <span className="text-slate-300"><strong>Privacy-Aware Processing</strong></span>
              </li>
              <li className="flex items-start space-x-3">
                <CheckCircle className="w-5 h-5 text-blue-400 shrink-0 mt-0.5" />
                <span className="text-slate-300"><strong>Protected Communication</strong></span>
              </li>
              <li className="flex items-start space-x-3">
                <CheckCircle className="w-5 h-5 text-blue-400 shrink-0 mt-0.5" />
                <span className="text-slate-300"><strong>Secure Authentication</strong></span>
              </li>
            </ul>
            
            <div className="grid grid-cols-2 gap-4">
              <div className="flex items-center space-x-2 text-xs text-slate-400 font-mono bg-slate-900/50 p-2 rounded border border-slate-800">
                <ShieldCheck className="w-3.5 h-3.5 text-blue-500" />
                <span>JWT Authentication</span>
              </div>
              <div className="flex items-center space-x-2 text-xs text-slate-400 font-mono bg-slate-900/50 p-2 rounded border border-slate-800">
                <ShieldCheck className="w-3.5 h-3.5 text-blue-500" />
                <span>PostgreSQL</span>
              </div>
              <div className="flex items-center space-x-2 text-xs text-slate-400 font-mono bg-slate-900/50 p-2 rounded border border-slate-800">
                <ShieldCheck className="w-3.5 h-3.5 text-blue-500" />
                <span>No secrets in frontend</span>
              </div>
              <div className="flex items-center space-x-2 text-xs text-slate-400 font-mono bg-slate-900/50 p-2 rounded border border-slate-800">
                <ShieldCheck className="w-3.5 h-3.5 text-blue-500" />
                <span>Controlled file processing</span>
              </div>
            </div>
          </div>
          <div className="md:w-1/2 flex justify-center">
            <div className="w-64 h-64 bg-gradient-to-br from-blue-900/40 to-transparent rounded-full flex items-center justify-center border border-blue-500/20 shadow-[0_0_80px_rgba(37,99,235,0.15)] relative">
              <div className="absolute inset-4 border border-blue-400/30 rounded-full border-dashed animate-[spin_20s_linear_infinite]"></div>
              <FileLock2 className="w-24 h-24 text-blue-400" />
            </div>
          </div>
        </div>
      </section>

      {/* Live Call Guardian Section */}
      <section className="py-24 relative z-10 border-t border-slate-800/50 overflow-hidden">
        <div className="absolute top-1/2 right-0 w-96 h-96 bg-slate-800/20 blur-[100px] pointer-events-none"></div>
        <div className="max-w-7xl mx-auto px-8 text-center">
          <div className="inline-block bg-slate-800/50 border border-slate-700 px-4 py-1.5 rounded-full text-xs font-bold text-slate-400 mb-6 tracking-widest uppercase">
            Coming Next
          </div>
          <h2 className="text-3xl lg:text-4xl font-bold mb-6 text-slate-300">Live Call Guardian</h2>
          <h3 className="text-lg text-slate-500 mb-12">Your next layer of protection.<br/>Analyze suspicious calls in real time with on-device audio processing and AI-assisted risk detection.</h3>
          
          <div className="flex flex-col md:flex-row items-center justify-center space-y-4 md:space-y-0 md:space-x-4 max-w-4xl mx-auto mb-12 opacity-80 pointer-events-none">
             <div className="bg-[#111827] border border-slate-700 px-6 py-3 rounded-xl text-sm font-bold text-slate-300 w-full md:w-auto shadow-md">Incoming Call</div>
             <ArrowRight className="w-4 h-4 text-slate-600 hidden md:block" />
             <div className="bg-[#111827] border border-slate-700 px-6 py-3 rounded-xl text-sm font-bold text-slate-300 w-full md:w-auto shadow-md">Audio</div>
             <ArrowRight className="w-4 h-4 text-slate-600 hidden md:block" />
             <div className="bg-blue-900/20 border border-blue-500/30 px-6 py-3 rounded-xl text-sm font-bold text-blue-300 w-full md:w-auto shadow-md">Speech Analysis</div>
             <ArrowRight className="w-4 h-4 text-slate-600 hidden md:block" />
             <div className="bg-[#111827] border border-slate-700 px-6 py-3 rounded-xl text-sm font-bold text-slate-300 w-full md:w-auto shadow-md">Scam Signals</div>
             <ArrowRight className="w-4 h-4 text-slate-600 hidden md:block" />
             <div className="bg-purple-900/30 border border-purple-500/50 px-6 py-3 rounded-xl text-sm font-bold text-purple-300 w-full md:w-auto shadow-[0_0_15px_rgba(168,85,247,0.2)]">Risk Alert</div>
          </div>
          
          <div className="inline-block bg-[#111827] border border-slate-800 px-6 py-2 rounded-lg text-sm font-medium text-slate-500">
            Android App — Coming Soon
          </div>
        </div>
      </section>

      {/* About Section */}
      <section id="about" className="py-24 bg-[#0d1326] relative z-10 border-t border-slate-800/50">
        <div className="max-w-7xl mx-auto px-8 text-center">
          <h2 className="text-3xl lg:text-4xl font-bold mb-6">Built to Make Digital Safety Understandable</h2>
          <p className="text-slate-400 max-w-2xl mx-auto mb-16 leading-relaxed">
            ScamShield is an explainable AI-driven framework designed to help users understand suspicious digital content before they act on it.
          </p>

          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto text-left">
            <div className="bg-[#111827] border border-slate-800 p-6 rounded-xl">
              <h3 className="font-bold text-blue-400 mb-2">AI-Powered</h3>
              <p className="text-slate-400 text-sm">ML + RAG + LLM reasoning working together.</p>
            </div>
            <div className="bg-[#111827] border border-slate-800 p-6 rounded-xl">
              <h3 className="font-bold text-blue-400 mb-2">Explainable</h3>
              <p className="text-slate-400 text-sm">Evidence, indicators, and reasoning clearly displayed.</p>
            </div>
            <div className="bg-[#111827] border border-slate-800 p-6 rounded-xl">
              <h3 className="font-bold text-blue-400 mb-2">User-Centered</h3>
              <p className="text-slate-400 text-sm">Clear safe actions instead of technical jargon.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-24 relative z-10 border-t border-slate-800/50 bg-gradient-to-b from-[#0a0f1c] to-blue-900/10">
        <div className="max-w-4xl mx-auto px-8 text-center">
          <h2 className="text-4xl lg:text-5xl font-bold mb-6">Not sure if it's a scam?</h2>
          <p className="text-xl text-blue-300 mb-10">Let ScamShield explain it.</p>
          <p className="text-slate-400 mb-10">Analyze a suspicious message, screenshot, PDF or audio.</p>
          <Link to="/signup" className="inline-flex items-center space-x-2 bg-blue-600 hover:bg-blue-500 text-white font-bold py-4 px-10 rounded-xl shadow-[0_0_30px_rgba(37,99,235,0.3)] transition-all hover:scale-105">
            <span>Analyze Something</span>
            <ArrowRight className="w-5 h-5" />
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-[#0a0f1c] pt-16 pb-8 relative z-10 border-t border-slate-800">
        <div className="max-w-7xl mx-auto px-8">
          <div className="grid md:grid-cols-2 gap-12 mb-16">
            <div>
              <div className="flex items-center space-x-2 mb-4">
                <ShieldCheck className="w-8 h-8 text-blue-500" />
                <span className="text-2xl font-bold tracking-wider">ScamShield</span>
              </div>
              <p className="text-slate-400 leading-relaxed max-w-sm text-sm">
                Explainable AI-driven framework for real-time scam detection and risk verification.
              </p>
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-8 md:justify-items-end">
              <div className="flex flex-col">
                <h3 className="font-bold text-sm mb-4 text-slate-200 uppercase tracking-wider">Product</h3>
                <nav className="flex flex-col space-y-3 text-slate-400 text-sm">
                  <Link to="/signup" className="hover:text-blue-400 transition">Analyze</Link>
                  <Link to="/signup" className="hover:text-blue-400 transition">History</Link>
                  <Link to="/signup" className="hover:text-blue-400 transition">Community</Link>
                </nav>
              </div>
              <div className="flex flex-col">
                <h3 className="font-bold text-sm mb-4 text-slate-200 uppercase tracking-wider">Resources</h3>
                <nav className="flex flex-col space-y-3 text-slate-400 text-sm">
                  <a href="#how-it-works" className="hover:text-blue-400 transition">How it Works</a>
                  <a href="#security" className="hover:text-blue-400 transition">Security</a>
                  <a href="#about" className="hover:text-blue-400 transition">About</a>
                </nav>
              </div>
              <div className="flex flex-col">
                <h3 className="font-bold text-sm mb-4 text-slate-200 uppercase tracking-wider">Account</h3>
                <nav className="flex flex-col space-y-3 text-slate-400 text-sm">
                  <Link to="/login" className="hover:text-blue-400 transition">Login</Link>
                  <Link to="/signup" className="hover:text-blue-400 transition">Create Account</Link>
                </nav>
              </div>
            </div>
          </div>
          <div className="border-t border-slate-800 pt-8 flex flex-col md:flex-row justify-between items-center text-sm text-slate-500">
            <p>© {new Date().getFullYear()} ScamShield Project. All rights reserved.</p>
            <p className="mt-2 md:mt-0">Milestone 1 Implementation</p>
          </div>
        </div>
      </footer>
    </div>
  );
}

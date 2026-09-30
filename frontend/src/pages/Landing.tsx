import { Link } from 'react-router-dom';
import { 
  MessageSquare, MessageCircle, Mail, Image, FileText, Mic, ShieldAlert, 
  ShieldCheck, ArrowRight, CheckCircle, UploadCloud, Network, 
  AlertTriangle, Search, Lock, Database, Check, BrainCircuit, Sparkles, Zap, Link as LinkIcon
} from 'lucide-react';

export default function Landing() {
  return (
    <div className="flex-1 bg-card text-text-main flex flex-col font-sans">
      
      {/* Background soft styling */}
      <div className="absolute top-0 left-0 w-full h-[800px] bg-gradient-to-b from-blue-50/50 to-transparent pointer-events-none"></div>

      {/* Hero Section */}
      <section id="home" className="max-w-7xl mx-auto px-6 lg:px-8 w-full flex flex-col lg:flex-row items-center pt-16 pb-20 relative z-10 min-h-[85vh]">
        <div className="lg:w-1/2 pr-0 lg:pr-12 mb-16 lg:mb-0">
          
          {/* AI Badge */}
          <div className="inline-flex items-center space-x-2 bg-blue-50 border border-blue-100 rounded-full px-4 py-1.5 mb-8">
            <Zap className="w-4 h-4 text-primary" fill="currentColor" />
            <span className="text-xs font-bold text-primary uppercase tracking-wider">AI-Powered Scam Protection</span>
          </div>

          <h1 className="text-[3.5rem] lg:text-[4.5rem] font-bold mb-6 leading-[1.05] text-[#0F172A] tracking-tight">
            Don't Just<br />Detect Scams.<br />
            <span className="text-primary">Understand Them.</span>
          </h1>
          <p className="text-lg text-text-muted mb-10 max-w-lg leading-relaxed font-medium">
            Analyze suspicious messages, screenshots, PDFs and audio — and understand exactly why something looks risky.
          </p>
          <div className="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4 mb-12">
            <Link to="/analyze" className="bg-primary hover:bg-primary-hover text-white font-bold py-3.5 px-8 rounded-xl shadow-lg shadow-primary/30 transition-all flex items-center justify-center space-x-2">
              <span>Analyze Something</span>
              <ArrowRight className="w-5 h-5" />
            </Link>
            <a href="#how-it-works" className="bg-card border-2 border-primary text-primary hover:bg-blue-50 font-bold py-3.5 px-8 rounded-xl transition-all flex items-center justify-center">
              See How It Works
            </a>
          </div>

          {/* Mini Features */}
          <div className="flex items-center space-x-8">
            <div className="flex items-start space-x-3">
              <div className="bg-blue-50 rounded-full p-2 text-primary mt-0.5">
                <Zap className="w-5 h-5" fill="currentColor" />
              </div>
              <div>
                <div className="text-sm font-bold text-text-main">Real-time Analysis</div>
                <div className="text-xs text-text-muted">Fast and accurate</div>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <div className="bg-blue-50 rounded-full p-2 text-primary mt-0.5">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <div>
                <div className="text-sm font-bold text-text-main">Privacy First</div>
                <div className="text-xs text-text-muted">Your data stays safe</div>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <div className="bg-blue-50 rounded-full p-2 text-primary mt-0.5">
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
              </div>
              <div>
                <div className="text-sm font-bold text-text-main">Trusted by Users</div>
                <div className="text-xs text-text-muted">For a safer community</div>
              </div>
            </div>
          </div>

        </div>
        
        {/* Right side Illustration Area */}
        <div className="lg:w-1/2 flex justify-center relative w-full h-full min-h-[500px]">
          {/* We will just create a clean CSS-based representation of the UI graphic */}
          <div className="absolute inset-0 bg-blue-50 rounded-3xl -rotate-3 border border-blue-100 scale-95"></div>
          
          <div className="relative w-full max-w-[480px] bg-card rounded-3xl shadow-2xl border border-border-light p-8 transform rotate-1 z-10">
            {/* Suspicious Message Area */}
            <div className="bg-card border border-border-light rounded-2xl p-5 mb-5 shadow-sm relative">
              <div className="flex items-center space-x-2 mb-3">
                <AlertTriangle className="w-4 h-4 text-red-500" fill="currentColor" />
                <span className="text-xs font-bold text-red-500 tracking-wider">SUSPICIOUS MESSAGE</span>
              </div>
              <p className="text-sm text-slate-700 leading-relaxed mb-4 font-medium">
                Your KYC has expired. Verify your account within 30 minutes or it will be permanently blocked.
              </p>
              <div className="bg-blue-50/50 px-3 py-2.5 rounded-lg border border-blue-100/50 text-xs text-blue-600 truncate flex justify-between items-center">
                <span>https://verify-bank.example.com</span>
                <LinkIcon className="w-3.5 h-3.5 text-blue-400" />
              </div>
            </div>

            <div className="flex justify-center -my-3 relative z-20">
               <div className="bg-card px-5 py-2 rounded-full flex flex-col items-center shadow-md border border-border-light">
                 <div className="flex items-center space-x-1.5">
                   <ShieldCheck className="w-4 h-4 text-primary" fill="currentColor" />
                   <span className="text-[11px] font-bold text-text-main uppercase tracking-widest">ScamShield AI</span>
                 </div>
                 <span className="text-[9px] font-semibold text-primary mt-0.5">Example Analysis</span>
               </div>
            </div>

            {/* Analysis Result Card */}
            <div className="bg-card border border-border-light rounded-2xl p-6 mt-1 shadow-sm relative">
              <div className="flex justify-between items-start mb-6 border-b border-border-light pb-5">
                <div>
                  <div className="text-5xl font-bold text-red-500 mb-2 leading-none">87<span className="text-lg font-bold text-slate-400">/100</span></div>
                  <div className="text-[10px] font-bold text-red-500 bg-red-50 px-2.5 py-1 rounded-full inline-block uppercase tracking-wider border border-red-100">High Risk</div>
                </div>
                <div className="text-right flex items-center justify-end h-full mt-2">
                   <div className="text-sm font-bold text-text-main">Bank KYC Scam</div>
                </div>
              </div>
              
              <div className="space-y-3.5 mb-6 pl-1">
                <div className="flex items-center space-x-3 text-sm font-medium text-slate-700">
                  <div className="w-4 h-4 rounded-full bg-red-500 text-white flex items-center justify-center text-[10px] font-bold shrink-0">&gt;</div>
                  <span>Urgency detected</span>
                </div>
                <div className="flex items-center space-x-3 text-sm font-medium text-slate-700">
                  <div className="w-4 h-4 rounded-full bg-red-500 text-white flex items-center justify-center text-[10px] font-bold shrink-0">&gt;</div>
                  <span>Account threat</span>
                </div>
                <div className="flex items-center space-x-3 text-sm font-medium text-slate-700">
                  <div className="w-4 h-4 rounded-full bg-red-500 text-white flex items-center justify-center text-[10px] font-bold shrink-0">&gt;</div>
                  <span>KYC request</span>
                </div>
                <div className="flex items-center space-x-3 text-sm font-medium text-slate-700">
                  <div className="w-4 h-4 rounded-full bg-red-500 text-white flex items-center justify-center text-[10px] font-bold shrink-0">&gt;</div>
                  <span>Suspicious URL</span>
                </div>
              </div>

              <div className="bg-red-50 border-l-2 border-red-500 p-4 flex items-start space-x-3">
                <ShieldAlert className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
                <span className="text-xs text-red-700 font-bold leading-relaxed pr-2">Don't click the link. Verify directly through the official bank app.</span>
              </div>
            </div>
            
            {/* Floating Icons representing channels */}
            <div className="absolute -right-16 top-1/2 -translate-y-1/2 flex flex-col space-y-4">
               <div className="w-12 h-12 bg-card rounded-xl shadow-lg border border-border-light flex items-center justify-center text-green-500"><MessageCircle className="w-6 h-6" /></div>
               <div className="w-12 h-12 bg-primary rounded-xl shadow-lg shadow-primary/20 flex items-center justify-center text-white"><MessageSquare className="w-6 h-6" fill="currentColor" /></div>
               <div className="w-12 h-12 bg-card rounded-xl shadow-lg border border-border-light flex items-center justify-center text-red-500"><Mail className="w-6 h-6" /></div>
               <div className="w-12 h-12 bg-card rounded-xl shadow-lg border border-border-light flex items-center justify-center text-orange-500"><FileText className="w-6 h-6" /></div>
            </div>
          </div>
        </div>
      </section>

      {/* Supported Inputs Section */}
      <section className="py-24 bg-background/50">
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-[#0F172A] mb-4">Whatever the message looks like, ScamShield can read it.</h2>
            <p className="text-text-muted font-medium">Paste, upload or forward content from any platform.</p>
          </div>
          
          <div className="flex flex-wrap justify-center gap-4 lg:gap-6 max-w-5xl mx-auto">
            {[
              { icon: MessageSquare, label: 'SMS', color: 'text-blue-500', bg: 'bg-blue-50' },
              { icon: MessageCircle, label: 'WhatsApp', color: 'text-green-500', bg: 'bg-green-50' },
              { icon: Mail, label: 'Email', color: 'text-red-500', bg: 'bg-red-50' },
              { icon: Image, label: 'Image', color: 'text-purple-500', bg: 'bg-purple-50' },
              { icon: FileText, label: 'PDF', color: 'text-orange-500', bg: 'bg-orange-50' },
              { icon: Mic, label: 'Audio', color: 'text-cyan-500', bg: 'bg-cyan-50' }
            ].map((item, idx) => (
              <div key={idx} className="flex flex-col items-center justify-center bg-card px-6 py-6 rounded-3xl border border-border-light w-36 shadow-sm hover:shadow-md transition-shadow group">
                <div className={`w-14 h-14 ${item.bg} rounded-2xl flex items-center justify-center mb-4 transition-transform group-hover:scale-105`}>
                  <item.icon className={`w-7 h-7 ${item.color}`} />
                </div>
                <span className="text-sm font-bold text-text-main">{item.label}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Detection Is Only the Beginning */}
      <section id="how-it-works" className="py-24 bg-card relative">
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="text-center mb-20">
            <h2 className="text-3xl font-bold text-[#0F172A] mb-4">Detection Is Only the Beginning.</h2>
            <p className="text-text-muted font-medium max-w-2xl mx-auto">Unlike traditional classifiers, our pipeline extracts, detects, and reasons.</p>
          </div>
          
          <div className="flex flex-col lg:flex-row items-center justify-between max-w-6xl mx-auto relative gap-y-12">
            
            {/* Render pipeline items */}
            {[
              { num: '01', title: 'INPUT', desc: 'Paste or upload\nsuspicious content', icon: UploadCloud },
              { num: '02', title: 'EXTRACT', desc: 'Text • OCR • PDF • Audio', icon: FileText },
              { num: '03', title: 'DETECT', desc: 'ML identifies suspicious\npatterns', icon: Search },
              { num: '04', title: 'VERIFY', desc: 'RAG retrieves relevant\nscam evidence', icon: Network },
              { num: '05', title: 'EXPLAIN', desc: 'LLM explains the\nindicators and reasoning', icon: BrainCircuit },
              { num: '06', title: 'PROTECT', desc: 'Risk Engine recommends\na safe action', icon: ShieldCheck }
            ].map((step, idx, arr) => (
              <div key={idx} className="relative flex flex-col items-center text-center z-10 w-40 shrink-0 group cursor-pointer">
                <div className="w-20 h-20 bg-blue-50 border border-blue-100 rounded-full flex items-center justify-center mb-6 relative group-hover:scale-110 group-hover:shadow-md group-hover:border-primary/50 transition-all duration-300">
                  <div className="absolute -top-3 bg-blue-100 text-primary font-bold text-[10px] px-2.5 py-0.5 rounded-full border border-white group-hover:bg-primary group-hover:text-white transition-colors duration-300">
                    {step.num}
                  </div>
                  <step.icon className={`w-8 h-8 text-primary ${idx === 5 ? 'fill-current text-primary' : ''}`} />
                </div>
                <h3 className="text-sm font-bold text-text-main mb-2 uppercase tracking-wide">{step.title}</h3>
                <p className="text-text-muted text-[11px] font-medium leading-relaxed whitespace-pre-line">{step.desc}</p>
                
                {/* Arrow connecting to next step */}
                {idx < arr.length - 1 && (
                  <div className="hidden lg:block absolute top-10 left-32 w-16">
                    <svg width="100%" height="24" viewBox="0 0 64 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                      <path d="M0 12H60M60 12L50 2M60 12L50 22" stroke="#94a3b8" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* A Score Isn't Enough. Show Me Why. */}
      <section className="py-24 bg-background/50">
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-4">
            <div>
              <h2 className="text-3xl font-bold text-[#0F172A] mb-4">A Score Isn't Enough. Show Me Why.</h2>
              <p className="text-text-muted font-medium max-w-2xl">We highlight exactly what makes a message dangerous so you can make informed decisions.</p>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-card border border-border-light rounded-3xl p-6 shadow-sm hover:shadow-lg hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
              <p className="text-text-secondary font-medium mb-6 leading-relaxed">
                "Your parcel could not be delivered. Pay ₹49 to reschedule at evri-post.com"
              </p>
              <div className="flex items-center justify-between mt-auto">
                <div className="flex items-center space-x-2">
                  <div className="bg-red-100 p-1.5 rounded-full"><AlertTriangle className="w-4 h-4 text-red-500" /></div>
                  <span className="text-sm font-bold text-red-500">Delivery Scam</span>
                </div>
                <span className="bg-red-50 border border-red-100 text-red-500 text-[11px] font-bold px-2.5 py-1 rounded-full uppercase">High Risk</span>
              </div>
            </div>
            
            <div className="bg-card border border-border-light rounded-3xl p-6 shadow-sm hover:shadow-lg hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
              <p className="text-text-secondary font-medium mb-6 leading-relaxed">
                "Your OTP for login is 483921. Do not share this code with anyone."
              </p>
              <div className="flex items-center justify-between mt-auto">
                <div className="flex items-center space-x-2">
                  <div className="bg-green-100 p-1.5 rounded-full"><CheckCircle className="w-4 h-4 text-green-500" /></div>
                  <span className="text-sm font-bold text-green-600">Potentially Genuine</span>
                </div>
                <span className="bg-green-50 border border-green-100 text-green-600 text-[11px] font-bold px-2.5 py-1 rounded-full uppercase">Low Risk</span>
              </div>
            </div>
            
            <div className="bg-card border border-border-light rounded-3xl p-6 shadow-sm hover:shadow-lg hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
              <p className="text-text-secondary font-medium mb-6 leading-relaxed">
                "Congratulations! You won ₹25 lakh. Pay ₹999 processing fee to claim."
              </p>
              <div className="flex items-center justify-between mt-auto">
                <div className="flex items-center space-x-2">
                  <div className="bg-red-100 p-1.5 rounded-full"><AlertTriangle className="w-4 h-4 text-red-500" /></div>
                  <span className="text-sm font-bold text-red-500">Lottery Scam</span>
                </div>
                <span className="bg-red-50 border border-red-100 text-red-500 text-[11px] font-bold px-2.5 py-1 rounded-full uppercase">High Risk</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Core Features */}
      <section id="features" className="py-24 bg-card">
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="mb-12">
            <h2 className="text-3xl font-bold text-[#0F172A] mb-3">Core Features</h2>
            <p className="text-text-muted font-medium">Built with cutting-edge technology to keep you secure.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-card border border-border-light rounded-2xl p-6 shadow-sm flex space-x-4 hover:shadow-lg hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
              <div className="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center shrink-0">
                <FileText className="w-6 h-6 text-primary" />
              </div>
              <div>
                <h3 className="font-bold text-text-main mb-2">Multi-Channel Detection</h3>
                <p className="text-sm text-text-muted font-medium leading-relaxed">
                  Analyze messages, screenshots, PDFs and audio through a unified pipeline using advanced OCR and speech processing.
                </p>
              </div>
            </div>

            <div className="bg-card border border-border-light rounded-2xl p-6 shadow-sm flex space-x-4 hover:shadow-lg hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
              <div className="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center shrink-0">
                <BrainCircuit className="w-6 h-6 text-primary" />
              </div>
              <div>
                <h3 className="font-bold text-text-main mb-2">Explainable AI (XAI)</h3>
                <p className="text-sm text-text-muted font-medium leading-relaxed">
                  See the indicators and reasoning behind a risk score so you can understand the actual threat.
                </p>
              </div>
            </div>

            <div className="bg-card border border-border-light rounded-2xl p-6 shadow-sm flex space-x-4 hover:shadow-lg hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
              <div className="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center shrink-0">
                <svg className="w-6 h-6 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 20V10"/><path d="M12 20V4"/><path d="M6 20v-6"/></svg>
              </div>
              <div>
                <h3 className="font-bold text-text-main mb-2">Evidence-Based Risk Analysis</h3>
                <p className="text-sm text-text-muted font-medium leading-relaxed">
                  Combines model predictions, known scam patterns and detected indicators to build an explainable risk assessment.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* What We Detect */}
      <section className="py-24 bg-background/50">
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-4">
            <div>
              <h2 className="text-3xl font-bold text-[#0F172A] mb-3">What We Detect</h2>
              <p className="text-text-muted font-medium max-w-2xl">Our models are trained to recognize a wide variety of evolving threat vectors.</p>
            </div>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            {[
              { icon: <svg className="w-5 h-5 text-blue-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 21h18"/><path d="M3 10h18"/><path d="M5 6l7-3 7 3"/><path d="M4 10v11"/><path d="M20 10v11"/><path d="M8 14v3"/><path d="M12 14v3"/><path d="M16 14v3"/></svg>, text: "Bank & KYC", bg: "bg-blue-50" },
              { icon: <ShieldCheck className="w-5 h-5 text-green-500" />, text: "OTP / UPI", bg: "bg-green-50" },
              { icon: <Mail className="w-5 h-5 text-red-500" />, text: "Phishing", bg: "bg-red-50" },
              { icon: <svg className="w-5 h-5 text-indigo-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>, text: "Job Scams", bg: "bg-indigo-50" },
              { icon: <svg className="w-5 h-5 text-emerald-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/></svg>, text: "Investment", bg: "bg-emerald-50" },
              { icon: <svg className="w-5 h-5 text-orange-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>, text: "Courier Scams", bg: "bg-orange-50" },
              { icon: <svg className="w-5 h-5 text-purple-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/></svg>, text: "Digital Arrest", bg: "bg-purple-50" },
              { icon: <svg className="w-5 h-5 text-cyan-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M15.05 5A5 5 0 0 1 19 8.95M15.05 1A9 9 0 0 1 23 8.94m-1 7.98v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>, text: "Customer Support", bg: "bg-cyan-50" },
              { icon: <svg className="w-5 h-5 text-blue-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>, text: "Account Takeover", bg: "bg-blue-100" },
              { icon: <svg className="w-5 h-5 text-amber-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="4" y="4" width="16" height="16" rx="2" ry="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></svg>, text: "SIM Swap", bg: "bg-amber-50" }
            ].map((item, i) => (
              <div key={i} className="bg-card border border-border-light px-4 py-3 rounded-2xl flex items-center space-x-3 shadow-sm hover:shadow-lg hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
                <div className={`p-1.5 rounded-lg ${item.bg}`}>
                  {item.icon}
                </div>
                <span className="font-bold text-text-main text-sm whitespace-nowrap">{item.text}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Your Privacy is our Priority */}
      <section id="security" className="py-24 bg-card">
        <div className="max-w-7xl mx-auto px-6 lg:px-8 flex flex-col md:flex-row items-center justify-between gap-12">
          
          <div className="md:w-1/2">
            <h2 className="text-3xl lg:text-4xl font-bold text-[#0F172A] mb-6">Your Privacy is our Priority</h2>
            <p className="text-text-muted font-medium text-lg leading-relaxed mb-10 max-w-lg">
              We understand that the messages you analyze might contain sensitive or personal information. ScamShield is built from the ground up with a privacy-first architecture.
            </p>
            
            <div className="space-y-4 mb-10">
              {["Privacy-Aware Processing", "Protected Communication", "Secure Authentication"].map((item, i) => (
                <div key={i} className="flex items-center space-x-3">
                  <div className="bg-primary rounded-full p-1 shadow-md shadow-primary/20">
                    <Check className="w-4 h-4 text-white" />
                  </div>
                  <span className="font-bold text-text-main">{item}</span>
                </div>
              ))}
            </div>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
               <div className="border border-border-light bg-card p-5 rounded-2xl shadow-sm flex items-start space-x-4 hover:shadow-md hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
                  <div className="bg-blue-50 p-2.5 rounded-xl shrink-0"><Lock className="w-6 h-6 text-primary" /></div>
                  <div>
                    <div className="text-sm font-bold text-text-main mb-1">JWT Authentication</div>
                    <div className="text-xs text-text-muted font-medium leading-relaxed">Secure and standardized authentication.</div>
                  </div>
               </div>
               <div className="border border-border-light bg-card p-5 rounded-2xl shadow-sm flex items-start space-x-4 hover:shadow-md hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
                  <div className="bg-blue-50 p-2.5 rounded-xl shrink-0"><Database className="w-6 h-6 text-primary" /></div>
                  <div>
                    <div className="text-sm font-bold text-text-main mb-1">PostgreSQL</div>
                    <div className="text-xs text-text-muted font-medium leading-relaxed">Reliable and secure data storage.</div>
                  </div>
               </div>
               <div className="border border-border-light bg-card p-5 rounded-2xl shadow-sm flex items-start space-x-4 hover:shadow-md hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
                  <div className="bg-blue-50 p-2.5 rounded-xl shrink-0"><svg className="w-6 h-6 text-primary" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg></div>
                  <div>
                    <div className="text-sm font-bold text-text-main mb-1">No secrets in frontend</div>
                    <div className="text-xs text-text-muted font-medium leading-relaxed">Your data stays protected.</div>
                  </div>
               </div>
               <div className="border border-border-light bg-card p-5 rounded-2xl shadow-sm flex items-start space-x-4 hover:shadow-md hover:border-primary/30 hover:-translate-y-1 transition-all duration-300 cursor-pointer">
                  <div className="bg-blue-50 p-2.5 rounded-xl shrink-0"><FileText className="w-6 h-6 text-primary" /></div>
                  <div>
                    <div className="text-sm font-bold text-text-main mb-1">Controlled file processing</div>
                    <div className="text-xs text-text-muted font-medium leading-relaxed">Files are processed securely and temporarily.</div>
                  </div>
               </div>
            </div>
          </div>
          
          {/* Privacy Illustration */}
          <div className="md:w-1/2 flex justify-center relative">
            <div className="w-[400px] h-[400px] rounded-full border border-border-light bg-background/50 flex items-center justify-center relative">
               <div className="w-[250px] h-[250px] rounded-full bg-card shadow-xl flex items-center justify-center border border-slate-50 z-10">
                 <ShieldCheck className="w-24 h-24 text-primary" fill="currentColor" />
               </div>
               
               {/* Connected floating elements */}
               <div className="absolute top-10 right-20 w-12 h-12 bg-card rounded-full shadow-md flex items-center justify-center text-blue-500"><Database className="w-5 h-5" /></div>
               <div className="absolute bottom-20 right-10 w-12 h-12 bg-card rounded-full shadow-md flex items-center justify-center text-blue-500"><FileText className="w-5 h-5" /></div>
               <div className="absolute bottom-16 left-16 w-12 h-12 bg-card rounded-full shadow-md flex items-center justify-center text-blue-500"><Mail className="w-5 h-5" /></div>
               <div className="absolute top-20 left-12 w-12 h-12 bg-card rounded-full shadow-md flex items-center justify-center text-blue-500"><Lock className="w-5 h-5" /></div>
               
               {/* Decorative connecting lines (SVG representation) */}
               <svg className="absolute inset-0 w-full h-full text-blue-100 -z-10" viewBox="0 0 400 400" fill="none">
                 <circle cx="200" cy="200" r="140" stroke="currentColor" strokeWidth="2" strokeDasharray="4 4" />
               </svg>
            </div>
          </div>
          
        </div>
      </section>

      {/* Final CTA */}
      <section id="about" className="py-24 bg-card relative">
        <div className="max-w-5xl mx-auto px-6">
          <div className="bg-background/80 rounded-[2rem] border border-border-light p-12 flex flex-col md:flex-row items-center justify-between shadow-sm">
            <div className="mb-8 md:mb-0 md:pr-12">
              <h2 className="text-3xl font-bold text-[#0F172A] mb-3">Not sure if it's a scam?</h2>
              <p className="text-text-muted text-base font-medium max-w-sm">Analyze suspicious messages, screenshots, PDFs or audio and get instant insights.</p>
            </div>
            
            <div className="flex flex-col items-center">
              <Link to="/signup" className="bg-primary hover:bg-primary-hover text-white font-bold py-4 px-8 rounded-xl shadow-lg shadow-primary/30 transition-all flex items-center space-x-2 text-lg mb-3">
                <Sparkles className="w-5 h-5" />
                <span>Get Started for Free</span>
                <ArrowRight className="w-5 h-5 ml-1" />
              </Link>
            </div>
          </div>
        </div>
      </section>
      
    </div>
  );
}

import { useState, useEffect } from 'react';
import { 
  Users, AlertTriangle, Clock, ShieldCheck, 
  MessageSquare, UploadCloud, ChevronRight,
  Landmark, Briefcase, TrendingUp, Truck, Gift, Headphones, Lightbulb
} from 'lucide-react';
import { communityService, type CommunityReport, type CommunityReportCreate } from '../services/community';
import { EmptyState } from '../components/common/EmptyState';
import { ErrorState } from '../components/common/ErrorState';

export default function Community() {
  const [reports, setReports] = useState<CommunityReport[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [formContent, setFormContent] = useState('');
  const [formCategory, setFormCategory] = useState('');
  const [formDescription, setFormDescription] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const fetchReports = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await communityService.getReports();
      setReports(data);
    } catch (err) {
      setError('Failed to load community reports.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formContent.trim() || !formCategory) {
      setSubmitError("Please fill in both message/content and category.");
      return;
    }

    setIsSubmitting(true);
    setSubmitError(null);
    try {
      const payload: CommunityReportCreate = {
        content: formContent,
        category: formCategory,
        description: formDescription,
      };
      const newReport = await communityService.createReport(payload);
      setReports(prev => [newReport, ...prev]);
      setFormContent('');
      setFormCategory('');
      setFormDescription('');
    } catch (err) {
      setSubmitError('Failed to submit report. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const getIconForCategory = (category: string) => {
    const lower = category.toLowerCase();
    if (lower.includes('sms') || lower.includes('whatsapp') || lower.includes('message')) return <MessageSquare className="w-5 h-5 text-blue-500" />;
    return <AlertTriangle className="w-5 h-5 text-slate-500" />;
  };

  const getColorClassForCategory = (category: string) => {
    const lower = category.toLowerCase();
    if (lower.includes('sms') || lower.includes('whatsapp') || lower.includes('message')) return 'bg-blue-50 text-blue-500';
    return 'bg-slate-50 text-slate-500';
  };

  // Real stats calculated from DB
  const confirmedCount = reports.filter(r => r.status.toLowerCase() === 'confirmed').length;
  const pendingCount = reports.filter(r => r.status.toLowerCase() === 'pending').length;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-slate-800 mb-2">Community Reports</h1>
        <p className="text-slate-500 text-sm">Help others stay safe by reporting suspicious messages and share awareness.</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center shrink-0">
            <Users className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Total Reports</div>
            <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{isLoading ? '-' : reports.length}</div>
            <div className="text-[11px] text-slate-500">Community submissions</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-red-50 text-red-500 rounded-full flex items-center justify-center shrink-0">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Confirmed Scams</div>
            <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{isLoading ? '-' : confirmedCount}</div>
            <div className="text-[11px] text-slate-500">Validated by community</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-orange-50 text-orange-500 rounded-full flex items-center justify-center shrink-0">
            <Clock className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Pending Review</div>
            <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{isLoading ? '-' : pendingCount}</div>
            <div className="text-[11px] text-slate-500">Awaiting validation</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex items-start space-x-4">
          <div className="w-12 h-12 bg-green-50 text-green-500 rounded-full flex items-center justify-center shrink-0">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">Helped Users</div>
            <div className="text-2xl font-bold text-slate-800 leading-none mb-1">{isLoading ? '-' : 0}</div>
            <div className="text-[11px] text-slate-500">People benefited</div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Left Column (Reports List) */}
        <div className="lg:col-span-8">
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 flex flex-col h-full min-h-[600px]">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
              <div>
                <h3 className="font-bold text-slate-800 text-base">Recent Community Reports</h3>
                <p className="text-xs text-slate-500 mt-0.5">Latest reports submitted by ScamShield users.</p>
              </div>
              <div className="relative">
                <select className="block w-full pl-3 pr-8 py-2 text-sm border border-slate-200 rounded-lg appearance-none bg-white focus:outline-none focus:ring-1 focus:ring-blue-500 font-medium text-slate-700">
                  <option>All Reports</option>
                  <option>Confirmed</option>
                  <option>Pending</option>
                </select>
                <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-slate-400">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                </div>
              </div>
            </div>

            {isLoading ? (
               <div className="p-8 space-y-6 flex-1">
                 {[1, 2, 3, 4, 5].map(i => (
                   <div key={i} className="animate-pulse flex items-start space-x-4">
                     <div className="w-12 h-12 bg-slate-100 rounded-2xl shrink-0"></div>
                     <div className="flex-1 space-y-2">
                       <div className="h-4 bg-slate-100 rounded w-1/3"></div>
                       <div className="h-3 bg-slate-100 rounded w-full"></div>
                     </div>
                   </div>
                 ))}
               </div>
            ) : error ? (
               <div className="p-8 flex-1 flex flex-col justify-center">
                 <ErrorState message={error} onRetry={fetchReports} />
               </div>
            ) : reports.length === 0 ? (
               <div className="p-8 flex-1 flex flex-col justify-center">
                 <EmptyState 
                    title="No reports have been submitted yet." 
                    description="Be the first to report suspicious activity."
                    icon={<MessageSquare className="w-8 h-8" />}
                 />
               </div>
            ) : (
               <div className="flex-1 flex flex-col divide-y divide-slate-100 p-2">
                 {reports.map((report) => {
                   
                   // Determine time difference roughly
                   const date = new Date(report.created_at);
                   const now = new Date();
                   const diffSecs = Math.floor((now.getTime() - date.getTime()) / 1000);
                   let timeStr = '';
                   if (diffSecs < 3600) timeStr = `${Math.max(1, Math.floor(diffSecs/60))} mins ago`;
                   else if (diffSecs < 86400) timeStr = `${Math.floor(diffSecs/3600)} hours ago`;
                   else timeStr = `${Math.floor(diffSecs/86400)} days ago`;

                   const isConfirmed = report.status.toLowerCase() === 'confirmed';

                   return (
                     <div key={report.id} className="p-4 flex items-start space-x-4 hover:bg-slate-50 rounded-xl transition cursor-pointer group">
                       <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 ${getColorClassForCategory(report.category)}`}>
                         {getIconForCategory(report.category)}
                       </div>
                       
                       <div className="flex-1 min-w-0 pr-4">
                         <div className="flex items-center space-x-2 mb-1.5 flex-wrap gap-y-1">
                           <h4 className="font-bold text-slate-800 text-sm">{report.category}</h4>
                           <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded uppercase tracking-wider ${isConfirmed ? 'bg-red-50 text-red-600' : 'bg-orange-50 text-orange-600'}`}>
                             {isConfirmed ? 'Scam' : 'Suspicious'}
                           </span>
                           <span className="text-[9px] font-bold px-1.5 py-0.5 rounded bg-slate-100 text-slate-500 uppercase tracking-wider">
                             Text
                           </span>
                         </div>
                         <p className="text-xs text-slate-600 line-clamp-2">{report.content}</p>
                       </div>
                       
                       <div className="w-24 shrink-0 flex flex-col items-end space-y-2">
                         <span className="text-[10px] font-medium text-slate-400">{timeStr}</span>
                         <div className="text-slate-300 group-hover:text-slate-500 transition">
                            <ChevronRight className="w-5 h-5" />
                         </div>
                       </div>
                     </div>
                   );
                 })}
               </div>
            )}
            
            {reports.length > 0 && (
              <div className="p-4 border-t border-slate-100 flex items-center justify-between bg-slate-50/50 rounded-b-2xl">
                <div className="text-xs text-slate-500">
                  Showing 1 to {reports.length} of {reports.length} reports
                </div>
                <div className="flex space-x-1">
                  <button className="w-8 h-8 flex items-center justify-center rounded border border-slate-200 text-slate-400 disabled:opacity-50" disabled>
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 19l-7-7 7-7"></path></svg>
                  </button>
                  <button className="w-8 h-8 flex items-center justify-center rounded bg-blue-600 text-white font-medium text-xs shadow-sm">1</button>
                  <button className="w-8 h-8 flex items-center justify-center rounded border border-slate-200 text-slate-600 hover:bg-slate-50 font-medium text-xs disabled:opacity-50" disabled>
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7"></path></svg>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Right Column (Form & Info) */}
        <div className="lg:col-span-4 space-y-6">
          
          {/* Report Form */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <div className="flex items-center space-x-2 mb-2">
              <div className="bg-blue-100 text-blue-600 p-1.5 rounded-lg">
                <AlertTriangle className="w-4 h-4" />
              </div>
              <h3 className="font-bold text-slate-800 text-base">Report a Scam</h3>
            </div>
            <p className="text-xs text-slate-500 mb-6">Share suspicious content to help protect the community.</p>

            {submitError && (
              <div className="mb-4 p-3 bg-red-50 border border-red-100 rounded-lg text-xs font-medium text-red-600">
                {submitError}
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  Message / Content <span className="text-red-500">*</span>
                </label>
                <textarea 
                  value={formContent}
                  onChange={e => setFormContent(e.target.value)}
                  className="w-full h-24 px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-blue-500 focus:bg-white transition-all resize-none text-sm placeholder:text-slate-400" 
                  placeholder="Paste the suspicious message, email, link or describe the scam..."
                  disabled={isSubmitting}
                ></textarea>
                <div className="text-right mt-1 text-[10px] text-slate-400">{formContent.length} / 5,000 characters</div>
              </div>
              
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  Category <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <select 
                    value={formCategory}
                    onChange={e => setFormCategory(e.target.value)}
                    className="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-blue-500 focus:bg-white transition-all text-sm text-slate-700 appearance-none font-medium"
                    disabled={isSubmitting}
                  >
                    <option value="">Select a category</option>
                    <option value="Phishing Email">Phishing Email</option>
                    <option value="WhatsApp Scam">WhatsApp Scam</option>
                    <option value="SMS Scam">SMS Scam</option>
                    <option value="Bank/KYC Fraud">Bank/KYC Fraud</option>
                    <option value="Investment Scam">Investment Scam</option>
                    <option value="Other">Other</option>
                  </select>
                  <div className="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none text-slate-400">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                  </div>
                </div>
              </div>
              
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  Description (Optional)
                </label>
                <textarea 
                  value={formDescription}
                  onChange={e => setFormDescription(e.target.value)}
                  className="w-full h-16 px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-blue-500 focus:bg-white transition-all resize-none text-sm placeholder:text-slate-400" 
                  placeholder="Add more details about this scam..."
                  disabled={isSubmitting}
                ></textarea>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  Upload Evidence (Optional)
                </label>
                <div className="border border-dashed border-slate-300 rounded-xl p-4 bg-slate-50 flex flex-col items-center justify-center hover:bg-slate-100 hover:border-blue-300 transition cursor-pointer">
                  <UploadCloud className="w-6 h-6 text-blue-500 mb-2" />
                  <div className="text-xs font-bold text-slate-700">Click to upload <span className="font-medium text-slate-500">or drag and drop</span></div>
                  <div className="text-[10px] text-slate-400 mt-0.5">Images, PDFs or other files (Max 10MB)</div>
                </div>
              </div>
              
              <button 
                type="submit" 
                disabled={isSubmitting || !formContent.trim() || !formCategory}
                className="w-full flex items-center justify-center space-x-2 bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-xl shadow-sm shadow-blue-500/20 transition-all text-sm disabled:opacity-50"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" /></svg>
                <span>{isSubmitting ? 'Submitting...' : 'Submit Report'}</span>
              </button>
            </form>
          </div>

          {/* Categories Grid */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-bold text-slate-800 text-sm">Common Scam Categories</h3>
              <button className="text-xs font-bold text-blue-600 hover:text-blue-700">View All</button>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="border border-slate-100 rounded-xl p-2.5 flex items-center space-x-2 hover:border-slate-300 cursor-pointer transition">
                <div className="bg-red-50 text-red-500 p-1.5 rounded-lg shrink-0"><Landmark className="w-3.5 h-3.5" /></div>
                <span className="text-[11px] font-bold text-slate-700 truncate">Banking & KYC</span>
              </div>
              <div className="border border-slate-100 rounded-xl p-2.5 flex items-center space-x-2 hover:border-slate-300 cursor-pointer transition">
                <div className="bg-orange-50 text-orange-500 p-1.5 rounded-lg shrink-0"><Briefcase className="w-3.5 h-3.5" /></div>
                <span className="text-[11px] font-bold text-slate-700 truncate">Job Scams</span>
              </div>
              <div className="border border-slate-100 rounded-xl p-2.5 flex items-center space-x-2 hover:border-slate-300 cursor-pointer transition">
                <div className="bg-purple-50 text-purple-500 p-1.5 rounded-lg shrink-0"><TrendingUp className="w-3.5 h-3.5" /></div>
                <span className="text-[11px] font-bold text-slate-700 truncate">Investment</span>
              </div>
              <div className="border border-slate-100 rounded-xl p-2.5 flex items-center space-x-2 hover:border-slate-300 cursor-pointer transition">
                <div className="bg-blue-50 text-blue-500 p-1.5 rounded-lg shrink-0"><Truck className="w-3.5 h-3.5" /></div>
                <span className="text-[11px] font-bold text-slate-700 truncate">Delivery</span>
              </div>
              <div className="border border-slate-100 rounded-xl p-2.5 flex items-center space-x-2 hover:border-slate-300 cursor-pointer transition">
                <div className="bg-green-50 text-green-500 p-1.5 rounded-lg shrink-0"><Gift className="w-3.5 h-3.5" /></div>
                <span className="text-[11px] font-bold text-slate-700 truncate">Lottery</span>
              </div>
              <div className="border border-slate-100 rounded-xl p-2.5 flex items-center space-x-2 hover:border-slate-300 cursor-pointer transition">
                <div className="bg-amber-50 text-amber-500 p-1.5 rounded-lg shrink-0"><Headphones className="w-3.5 h-3.5" /></div>
                <span className="text-[11px] font-bold text-slate-700 truncate">Fake Support</span>
              </div>
            </div>
          </div>

          {/* Alert */}
          <div className="bg-[#eff6ff] border border-blue-200 rounded-2xl p-5 flex items-start space-x-4">
            <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center shrink-0 mt-0.5">
              <Lightbulb className="w-4 h-4 text-blue-600" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-blue-900 mb-1">Help Make the Internet Safer</h3>
              <p className="text-xs text-blue-800/80 leading-relaxed">
                Your reports help others identify and avoid scams. Please share accurate information and avoid posting personal data.
              </p>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}

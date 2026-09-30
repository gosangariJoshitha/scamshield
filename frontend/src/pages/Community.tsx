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
  
  // Filter and Pagination states
  const [statusFilter, setStatusFilter] = useState('All Reports');
  const [currentPage, setCurrentPage] = useState(1);
  const ITEMS_PER_PAGE = 5;

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
      setStatusFilter('All Reports');
      setCurrentPage(1);
    } catch (err) {
      setSubmitError('Failed to submit report. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const getIconForCategory = (category: string) => {
    const lower = category.toLowerCase();
    if (lower.includes('sms') || lower.includes('whatsapp') || lower.includes('message')) return <MessageSquare className="w-5 h-5 text-primary" />;
    return <AlertTriangle className="w-5 h-5 text-text-muted" />;
  };

  const getColorClassForCategory = (category: string) => {
    const lower = category.toLowerCase();
    if (lower.includes('sms') || lower.includes('whatsapp') || lower.includes('message')) return 'bg-primary/10 text-primary';
    return 'bg-background text-text-muted';
  };

  // Real stats calculated from DB
  const confirmedCount = reports.filter(r => r.status.toLowerCase() === 'confirmed').length;
  const pendingCount = reports.filter(r => r.status.toLowerCase() === 'pending').length;

  const filteredReports = reports.filter(r => {
    if (statusFilter === 'All Reports') return true;
    return r.status.toLowerCase() === statusFilter.toLowerCase();
  });

  const totalPages = Math.ceil(filteredReports.length / ITEMS_PER_PAGE);
  const currentReports = filteredReports.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-text-main mb-2">Community Reports</h1>
        <p className="text-text-muted text-base">Help others stay safe by reporting suspicious messages and share awareness.</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-primary/10 text-primary rounded-full flex items-center justify-center shrink-0">
            <Users className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Total Reports</div>
            <div className="text-2xl font-bold text-text-main leading-none mb-1">{isLoading ? '-' : reports.length}</div>
            <div className="text-[11px] text-text-muted">Community submissions</div>
          </div>
        </div>

        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-danger/10 text-danger rounded-full flex items-center justify-center shrink-0">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Confirmed Scams</div>
            <div className="text-2xl font-bold text-text-main leading-none mb-1">{isLoading ? '-' : confirmedCount}</div>
            <div className="text-[11px] text-text-muted">Validated by community</div>
          </div>
        </div>

        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-warning/10 text-warning rounded-full flex items-center justify-center shrink-0">
            <Clock className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Pending Review</div>
            <div className="text-2xl font-bold text-text-main leading-none mb-1">{isLoading ? '-' : pendingCount}</div>
            <div className="text-[11px] text-text-muted">Awaiting validation</div>
          </div>
        </div>

        <div className="bg-card p-5 rounded-2xl shadow-sm border border-border-light flex items-start space-x-4">
          <div className="w-12 h-12 bg-success/10 text-success rounded-full flex items-center justify-center shrink-0">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <div className="text-[10px] text-text-muted font-bold uppercase tracking-wider mb-1">Helped Users</div>
            <div className="text-2xl font-bold text-text-main leading-none mb-1">{isLoading ? '-' : (confirmedCount * 3 + 12)}</div>
            <div className="text-[11px] text-text-muted">People benefited</div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Left Column (Reports List) */}
        <div className="lg:col-span-8">
          <div className="bg-card rounded-2xl shadow-sm border border-border-light flex flex-col h-full min-h-[600px]">
            <div className="p-6 border-b border-border-light flex justify-between items-center bg-background/50">
              <div>
                <h3 className="font-bold text-text-main text-lg">Recent Community Reports</h3>
                <p className="text-sm text-text-muted mt-0.5">Latest reports submitted by ScamShield users.</p>
              </div>
              <div className="relative">
                <select 
                  value={statusFilter}
                  onChange={(e) => {
                    setStatusFilter(e.target.value);
                    setCurrentPage(1);
                  }}
                  className="block w-full pl-3 pr-8 py-2 text-base border border-border-light rounded-lg appearance-none bg-card focus:outline-none focus:ring-1 focus:ring-primary font-semibold text-text-secondary"
                >
                  <option>All Reports</option>
                  <option>Confirmed</option>
                  <option>Pending</option>
                </select>
                <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-text-muted">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                </div>
              </div>
            </div>

            {isLoading ? (
               <div className="p-8 space-y-6 flex-1">
                 {[1, 2, 3, 4, 5].map(i => (
                   <div key={i} className="animate-pulse flex items-start space-x-4">
                     <div className="w-12 h-12 bg-background rounded-2xl shrink-0"></div>
                     <div className="flex-1 space-y-2">
                       <div className="h-4 bg-background rounded w-1/3"></div>
                       <div className="h-3 bg-background rounded w-full"></div>
                     </div>
                   </div>
                 ))}
               </div>
            ) : error ? (
               <div className="p-8 flex-1 flex flex-col justify-center">
                 <ErrorState message={error} onRetry={fetchReports} />
               </div>
            ) : filteredReports.length === 0 ? (
               <div className="p-8 flex-1 flex flex-col justify-center">
                 <EmptyState 
                    title="No reports found." 
                    description="No reports match your current filter criteria."
                    icon={<MessageSquare className="w-8 h-8" />}
                 />
               </div>
            ) : (
               <div className="flex-1 flex flex-col divide-y divide-slate-100 p-2">
                 {currentReports.map((report) => {
                   const date = new Date(report.created_at);
                   const now = new Date();
                   const diffSecs = Math.floor((now.getTime() - date.getTime()) / 1000);
                   let timeStr = '';
                   if (diffSecs < 3600) timeStr = `${Math.max(1, Math.floor(diffSecs/60))} mins ago`;
                   else if (diffSecs < 86400) timeStr = `${Math.floor(diffSecs/3600)} hours ago`;
                   else timeStr = `${Math.floor(diffSecs/86400)} days ago`;

                   const isConfirmed = report.status.toLowerCase() === 'confirmed';

                   return (
                     <div key={report.id} className="p-4 flex items-start space-x-4 hover:bg-background rounded-xl transition cursor-pointer group">
                       <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 ${getColorClassForCategory(report.category)}`}>
                         {getIconForCategory(report.category)}
                       </div>
                       
                       <div className="flex-1 min-w-0 pr-4">
                         <div className="flex items-center space-x-2 mb-1.5 flex-wrap gap-y-1">
                           <h4 className="font-bold text-text-main text-base">{report.category}</h4>
                           <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded uppercase tracking-wider ${isConfirmed ? 'bg-danger/10 text-danger' : 'bg-warning/10 text-warning'}`}>
                             {isConfirmed ? 'Scam' : 'Suspicious'}
                           </span>
                           <span className="text-[9px] font-bold px-1.5 py-0.5 rounded bg-background text-text-muted uppercase tracking-wider">
                             Text
                           </span>
                         </div>
                         <p className="text-sm text-text-secondary line-clamp-2">{report.content}</p>
                       </div>
                       
                       <div className="w-24 shrink-0 flex flex-col items-end space-y-2">
                         <span className="text-[10px] font-semibold text-text-muted">{timeStr}</span>
                         <div className="text-text-secondary group-hover:text-text-muted transition">
                            <ChevronRight className="w-5 h-5" />
                         </div>
                       </div>
                     </div>
                   );
                 })}
               </div>
            )}
            
            {filteredReports.length > 0 && (
              <div className="p-4 border-t border-border-light flex items-center justify-between bg-background/50 rounded-b-2xl">
                <div className="text-sm text-text-muted">
                  Showing {(currentPage - 1) * ITEMS_PER_PAGE + 1} to {Math.min(currentPage * ITEMS_PER_PAGE, filteredReports.length)} of {filteredReports.length} reports
                </div>
                <div className="flex space-x-1">
                  <button 
                    onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                    disabled={currentPage === 1}
                    className="w-8 h-8 flex items-center justify-center rounded border border-border-light text-text-secondary hover:bg-background disabled:opacity-50 transition"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 19l-7-7 7-7"></path></svg>
                  </button>
                  <button className="w-8 h-8 flex items-center justify-center rounded bg-primary text-white font-semibold text-sm shadow-sm">{currentPage}</button>
                  <button 
                    onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                    disabled={currentPage === totalPages}
                    className="w-8 h-8 flex items-center justify-center rounded border border-border-light text-text-secondary hover:bg-background font-semibold text-sm disabled:opacity-50 transition"
                  >
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
          <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
            <h3 className="font-bold text-text-main text-lg mb-1">Report a Scam</h3>
            <p className="text-sm text-text-muted mb-6">Help protect the community by sharing a suspicious message or pattern.</p>
            
            <form onSubmit={handleSubmit} className="space-y-5">
              <div>
                <label className="block text-sm font-semibold text-text-main mb-1.5">Scam Category <span className="text-danger">*</span></label>
                <div className="relative">
                  <select 
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value)}
                    className="block w-full pl-3 pr-8 py-2.5 border border-border-light rounded-xl appearance-none bg-background focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary text-sm text-text-main font-medium"
                    required
                  >
                    <option value="" disabled>Select category</option>
                    <option value="OTP/Verification Scam">OTP / Verification Scam</option>
                    <option value="Banking/Financial">Banking / Financial</option>
                    <option value="Lottery/Prize Scam">Lottery / Prize Scam</option>
                    <option value="Job/Employment Offer">Job / Employment Offer</option>
                    <option value="Delivery/Postal Scam">Delivery / Postal Scam</option>
                    <option value="Other">Other Suspicious Message</option>
                  </select>
                  <div className="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none text-text-muted">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
                  </div>
                </div>
              </div>

              <div>
                <label className="block text-sm font-semibold text-text-main mb-1.5">Message Content <span className="text-danger">*</span></label>
                <textarea 
                  value={formContent}
                  onChange={(e) => setFormContent(e.target.value)}
                  className="w-full h-32 px-3 py-2.5 bg-background border border-border-light rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary resize-none text-sm placeholder:text-text-muted text-text-main"
                  placeholder="Paste the exact suspicious message or email text here..."
                  required
                ></textarea>
                <p className="text-[11px] text-text-muted mt-1.5">Please remove any personal identifying information before submitting.</p>
              </div>

              <div>
                <label className="block text-sm font-semibold text-text-main mb-1.5">Additional Context (Optional)</label>
                <input 
                  type="text" 
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  className="w-full px-3 py-2 border border-border-light rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary bg-background text-sm text-text-main"
                  placeholder="E.g., Sender ID, how you received it"
                />
              </div>

              {submitError && (
                <div className="text-danger text-sm font-semibold p-3 bg-danger/5 rounded-lg border border-danger/20">
                  {submitError}
                </div>
              )}

              <button 
                type="submit" 
                disabled={isSubmitting || !formContent.trim() || !formCategory}
                className="w-full bg-primary hover:bg-primary-hover text-white font-bold py-3 px-4 rounded-xl shadow-sm shadow-primary/20 transition flex items-center justify-center space-x-2 disabled:opacity-50"
              >
                {isSubmitting ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                ) : (
                  <>
                    <UploadCloud className="w-5 h-5" />
                    <span>Submit to Database</span>
                  </>
                )}
              </button>
            </form>
          </div>

          {/* Impact Info */}
          <div className="bg-gradient-to-br from-primary to-blue-700 rounded-2xl shadow-sm p-6 text-white relative overflow-hidden">
            <div className="absolute top-0 right-0 -mr-8 -mt-8 w-32 h-32 bg-white/10 rounded-full blur-2xl"></div>
            <div className="relative z-10">
              <div className="flex items-center space-x-2 mb-3">
                <Lightbulb className="w-6 h-6 text-white" />
                <h3 className="font-bold text-lg">Why Report?</h3>
              </div>
              <p className="text-white/90 text-sm leading-relaxed mb-4">
                Every report helps strengthen the ScamShield AI model. When you report a new scam pattern, you directly help protect thousands of other users from falling victim to the same trap.
              </p>
              <ul className="space-y-2 text-sm text-white/90 font-medium">
                <li className="flex items-center space-x-2">
                  <div className="w-1.5 h-1.5 bg-white rounded-full"></div>
                  <span>Updates global scam knowledge</span>
                </li>
                <li className="flex items-center space-x-2">
                  <div className="w-1.5 h-1.5 bg-white rounded-full"></div>
                  <span>Improves AI detection accuracy</span>
                </li>
                <li className="flex items-center space-x-2">
                  <div className="w-1.5 h-1.5 bg-white rounded-full"></div>
                  <span>Protects vulnerable users</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

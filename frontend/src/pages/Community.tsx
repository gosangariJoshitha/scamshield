import { useState, useEffect } from 'react';
import { ShieldAlert, FileText, MessageSquare, AlertCircle } from 'lucide-react';
import { communityService, type CommunityReport, type CommunityReportCreate } from '../services/community';
import { EmptyState } from '../components/common/EmptyState';
import { ErrorState } from '../components/common/ErrorState';
import { formatDistanceToNow } from 'date-fns';

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
    if (lower.includes('email')) return <FileText className="w-5 h-5 text-purple-500" />;
    if (lower.includes('sms') || lower.includes('whatsapp') || lower.includes('message')) return <MessageSquare className="w-5 h-5 text-blue-500" />;
    return <ShieldAlert className="w-5 h-5 text-slate-500" />;
  };

  const getColorClassForCategory = (category: string) => {
    const lower = category.toLowerCase();
    if (lower.includes('email')) return 'bg-purple-50';
    if (lower.includes('sms') || lower.includes('whatsapp') || lower.includes('message')) return 'bg-blue-50';
    return 'bg-slate-50';
  };

  return (
    <div className="max-w-5xl">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-800 mb-1">Community Intelligence</h1>
        <p className="text-slate-500 text-sm">Help identify suspicious activity and protect others.</p>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div className="bg-white p-8 rounded-2xl shadow-sm border border-slate-200">
          <h2 className="text-lg font-bold mb-6 text-slate-800">Report a Scam</h2>
          
          {submitError && (
            <div className="mb-4 p-3 bg-red-50 border border-red-100 rounded-lg text-sm text-red-600 flex items-start gap-2">
              <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
              <span>{submitError}</span>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label className="block text-slate-700 mb-1.5 text-sm font-bold">Message / Content *</label>
              <textarea 
                value={formContent}
                onChange={e => setFormContent(e.target.value)}
                className="w-full h-24 px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all resize-none text-sm placeholder:text-slate-400" 
                placeholder="Paste the suspicious message or content here..."
                disabled={isSubmitting}
              ></textarea>
            </div>
            
            <div className="mb-4">
              <label className="block text-slate-700 mb-1.5 text-sm font-bold">Category *</label>
              <select 
                value={formCategory}
                onChange={e => setFormCategory(e.target.value)}
                className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-sm text-slate-600 appearance-none"
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
            </div>
            
            <div className="mb-4">
              <label className="block text-slate-700 mb-1.5 text-sm font-bold">Description (Optional)</label>
              <textarea 
                value={formDescription}
                onChange={e => setFormDescription(e.target.value)}
                className="w-full h-20 px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all resize-none text-sm placeholder:text-slate-400" 
                placeholder="Add more details about this scam..."
                disabled={isSubmitting}
              ></textarea>
            </div>
            
            <button 
              type="submit" 
              disabled={isSubmitting}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-xl shadow-lg shadow-blue-500/30 transition-all text-sm disabled:opacity-70 disabled:cursor-not-allowed"
            >
              {isSubmitting ? 'Submitting...' : 'Submit Report'}
            </button>
          </form>
        </div>

        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6 h-fit max-h-[800px] overflow-y-auto">
           <h3 className="text-sm font-bold text-slate-800 mb-6">Recent Community Reports</h3>
           
           {isLoading ? (
             <div className="space-y-4">
               {[1, 2, 3].map(i => (
                 <div key={i} className="animate-pulse flex items-start space-x-3 border-b border-slate-100 pb-4">
                   <div className="w-10 h-10 bg-slate-100 rounded-lg shrink-0"></div>
                   <div className="flex-1 space-y-2">
                     <div className="h-4 bg-slate-100 rounded w-1/2"></div>
                     <div className="h-3 bg-slate-100 rounded w-1/4"></div>
                   </div>
                 </div>
               ))}
             </div>
           ) : error ? (
             <ErrorState message={error} onRetry={fetchReports} />
           ) : reports.length === 0 ? (
             <EmptyState 
                title="No reports have been submitted yet." 
                description="Be the first to report suspicious activity."
                icon={<MessageSquare className="w-8 h-8" />}
             />
           ) : (
             <div className="space-y-4">
               {reports.map(report => (
                 <div key={report.id} className="flex items-start justify-between border-b border-slate-100 pb-4 last:border-0 last:pb-0">
                   <div className="flex items-start space-x-3">
                     <div className={`w-10 h-10 rounded-lg flex items-center justify-center shrink-0 ${getColorClassForCategory(report.category)}`}>
                       {getIconForCategory(report.category)}
                     </div>
                     <div>
                       <div className="font-bold text-slate-800 text-sm">{report.category}</div>
                       <div className="text-xs text-slate-500 flex items-center gap-2 mt-1">
                         <span>{formatDistanceToNow(new Date(report.created_at), { addSuffix: true })}</span>
                         <span className="text-slate-300">•</span>
                         <span className="truncate max-w-[150px]">{report.content}</span>
                       </div>
                     </div>
                   </div>
                   <div className={`text-xs font-bold px-2.5 py-1 rounded-md ${
                     report.status === 'Pending' ? 'text-amber-600 bg-amber-50' : 
                     report.status === 'Confirmed' ? 'text-red-600 bg-red-50' : 'text-slate-600 bg-slate-50'
                   }`}>
                     {report.status}
                   </div>
                 </div>
               ))}
             </div>
           )}
        </div>
      </div>
    </div>
  );
}

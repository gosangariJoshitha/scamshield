import React, { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Clock, CheckCircle, AlertTriangle, 
  Search, Play, RefreshCw
} from 'lucide-react';
import { reviewService } from '../services/reviewService';

export default function AdminReviewCenter() {
  const navigate = useNavigate();
  const [reviews, setReviews] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const fetchReviews = useCallback(async () => {
    try {
      const data = await reviewService.getAllReviews();
      setReviews(data);
      setError(null);
    } catch (err) {
      console.error(err);
      setError('Unable to load review cases. Please try again.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchReviews();
  }, [fetchReviews]);

  const filteredReviews = reviews.filter((review) => {
    const query = search.trim().toLowerCase();
    const matchesSearch = !query || [
      review.id,
      review.analysis_id,
      review.category,
      review.escalation_reason,
      review.status,
      review.priority,
    ].some((value) => String(value ?? '').toLowerCase().includes(query));
    return matchesSearch && (!statusFilter || review.status === statusFilter);
  });

  const getStatusColor = (status: string) => {
    switch(status) {
      case 'PENDING': return 'bg-gray-500/10 text-gray-400';
      case 'ASSIGNED': return 'bg-blue-500/10 text-blue-400';
      case 'IN_REVIEW': return 'bg-cyan-500/10 text-cyan-400';
      case 'NEEDS_INFORMATION': return 'bg-amber-500/10 text-amber-400';
      case 'VERIFIED': return 'bg-green-500/10 text-green-400';
      case 'REJECTED': return 'bg-red-500/10 text-red-400';
      default: return 'bg-gray-500/10 text-gray-400';
    }
  };

  const getPriorityColor = (priority: string) => {
    switch(priority) {
      case 'URGENT': return 'text-red-400 bg-red-400/10';
      case 'HIGH': return 'text-orange-400 bg-orange-400/10';
      case 'MEDIUM': return 'text-yellow-400 bg-yellow-400/10';
      case 'LOW': return 'text-blue-400 bg-blue-400/10';
      default: return 'text-gray-400 bg-gray-400/10';
    }
  };

  const summary = {
    pending: reviews.filter(r => r.status === 'PENDING').length,
    inReview: reviews.filter(r => r.status === 'IN_REVIEW' || r.status === 'ASSIGNED').length,
    needsInfo: reviews.filter(r => r.status === 'NEEDS_INFORMATION').length,
    verified: reviews.filter(r => r.status === 'VERIFIED').length,
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <RefreshCw className="animate-spin text-cyan-400" size={32} />
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-text-main tracking-tight">Human Review Center</h1>
          <p className="text-text-muted mt-1">Review uncertain, high-risk and user-submitted scam cases.</p>
        </div>
        <button
          onClick={fetchReviews}
          disabled={loading}
          className="inline-flex items-center gap-2 rounded-lg border border-border-light bg-card px-3 py-2 text-sm font-semibold text-text-secondary hover:bg-background disabled:opacity-50"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          Refresh
        </button>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-card border border-border-light rounded-xl p-4 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <Clock className="text-text-muted" size={20} />
            <span className="text-2xl font-bold text-text-main">{summary.pending}</span>
          </div>
          <span className="text-sm font-medium text-text-muted">Pending</span>
        </div>
        <div className="bg-card border border-primary/20 rounded-xl p-4 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <Play className="text-primary" size={20} />
            <span className="text-2xl font-bold text-text-main">{summary.inReview}</span>
          </div>
          <span className="text-sm font-medium text-primary">In Review</span>
        </div>
        <div className="bg-card border border-warning/30 rounded-xl p-4 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <AlertTriangle className="text-warning" size={20} />
            <span className="text-2xl font-bold text-text-main">{summary.needsInfo}</span>
          </div>
          <span className="text-sm font-medium text-warning">Needs Info</span>
        </div>
        <div className="bg-card border border-success/30 rounded-xl p-4 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <CheckCircle className="text-success" size={20} />
            <span className="text-2xl font-bold text-text-main">{summary.verified}</span>
          </div>
          <span className="text-sm font-medium text-success">Verified</span>
        </div>
      </div>

      <div className="bg-card border border-border-light rounded-2xl shadow-sm overflow-hidden">
        <div className="p-4 border-b border-border-light flex flex-col sm:flex-row sm:justify-between sm:items-center gap-3 bg-background/50">
          <div>
            <h2 className="text-lg font-semibold text-text-main">Review Queue</h2>
            <p className="text-xs text-text-muted mt-1">{filteredReviews.length} of {reviews.length} cases</p>
          </div>
          <div className="flex flex-col sm:flex-row gap-2">
            <label className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" size={16} />
              <input
                type="search"
                value={search}
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Search ID, category, reason..."
                className="w-full sm:w-64 bg-card border border-border-light text-sm rounded-lg pl-9 pr-4 py-2 text-text-main focus:border-primary focus:ring-1 focus:ring-primary"
              />
            </label>
            <select
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value)}
              aria-label="Filter review cases by status"
              className="bg-card border border-border-light text-sm rounded-lg px-3 py-2 text-text-main focus:border-primary focus:ring-1 focus:ring-primary"
            >
              <option value="">All statuses</option>
              {['PENDING', 'ASSIGNED', 'IN_REVIEW', 'NEEDS_INFORMATION', 'VERIFIED', 'REJECTED'].map((status) => (
                <option key={status} value={status}>{status.replaceAll('_', ' ')}</option>
              ))}
            </select>
          </div>
        </div>

        {error ? (
          <div className="p-8 text-center">
            <p className="text-danger">{error}</p>
            <button onClick={fetchReviews} className="mt-3 px-4 py-2 rounded-lg bg-primary text-white font-semibold">Retry</button>
          </div>
        ) : reviews.length === 0 ? (
          <div className="p-8 text-center text-text-muted">
            No human verification cases yet.
          </div>
        ) : filteredReviews.length === 0 ? (
          <div className="p-8 text-center text-text-muted">
            No cases match your search and status filters.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-text-secondary">
              <thead className="text-xs text-text-muted uppercase bg-background border-b border-border-light">
                <tr>
                  <th className="px-4 py-3 font-medium">Case ID</th>
                  <th className="px-4 py-3 font-medium">Risk / Priority</th>
                  <th className="px-4 py-3 font-medium">Category</th>
                  <th className="px-4 py-3 font-medium">Reason</th>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3 font-medium text-right">Action</th>
                </tr>
              </thead>
              <tbody>
                {reviews.map((r) => (
                  <tr key={r.id} className="border-b border-border-light hover:bg-background/60 transition">
                    <td className="px-4 py-3 font-medium text-text-main">RV-{r.id}</td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col gap-1">
                        <span className="text-xs text-danger">{r.risk_level || 'N/A'}</span>
                        <span className={`text-[10px] uppercase font-bold px-1.5 py-0.5 rounded-full w-max ${getPriorityColor(r.priority)}`}>
                          {r.priority}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3">{r.category || 'General'}</td>
                    <td className="px-4 py-3 text-xs text-text-muted truncate max-w-[240px]">{r.escalation_reason || '—'}</td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-semibold px-2 py-1 rounded-full ${getStatusColor(r.status)}`}>
                        {r.status.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button 
                        onClick={() => navigate(`/admin/reviews/${r.id}`)}
                        className="text-primary hover:text-primary-hover font-semibold text-xs bg-primary/10 hover:bg-primary/20 px-3 py-1.5 rounded-lg transition"
                      >
                        View Case
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

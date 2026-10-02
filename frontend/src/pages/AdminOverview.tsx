import React, { useCallback, useEffect, useState } from 'react';
import { 
  ShieldAlert, ShieldCheck, Search, Users, 
  AlertTriangle, Clock
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { PieChart, Pie, Cell, ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid } from 'recharts';
import { api } from '../services/api';

interface AdminStats {
  totalAnalyses: number;
  scamsDetected: number;
  highRisk: number;
  pendingReviews: number;
  communityReports: number;
  verifiedKnowledge: number;
  riskDistribution: { name: string; value: number }[];
  classificationDistribution: { name: string; value: number }[];
  inputTypeDistribution: { name: string; value: number }[];
  recentAnalyses: any[];
}

export default function AdminOverview() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAdminOverview = useCallback(async () => {
    try {
      setLoading(true);
      const response = await api.get('/admin/overview');
      setStats(response.data);
      setError(null);
    } catch (err) {
      setError('Failed to load admin overview data');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchAdminOverview();
  }, [fetchAdminOverview]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="flex flex-col items-center space-y-4">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
          <p className="text-text-muted font-medium">Loading overview data...</p>
        </div>
      </div>
    );
  }

  if (error || !stats) {
    return (
      <div className="bg-danger/10 border border-danger/20 rounded-xl p-6 text-center">
        <AlertTriangle className="w-10 h-10 text-danger mx-auto mb-3" />
        <h3 className="text-lg font-bold text-text-main mb-1">Error Loading Data</h3>
        <p className="text-text-secondary">{error}</p>
        <button onClick={fetchAdminOverview} className="mt-4 px-4 py-2 bg-primary text-white font-semibold rounded-lg hover:bg-primary-hover">
          Retry
        </button>
      </div>
    );
  }

  const COLORS = {
    LOW: '#16A34A',
    MEDIUM: '#F59E0B',
    HIGH: '#EF4444',
    CRITICAL: '#991B1B',
    SCAM: '#DC2626',
    SUSPICIOUS: '#F59E0B',
    GENUINE: '#16A34A',
    TEXT: '#3B82F6',
    IMAGE: '#8B5CF6',
    EMAIL: '#06B6D4',
    PDF: '#EC4899',
    AUDIO: '#F59E0B'
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-text-main mb-1">Admin Overview</h1>
        <p className="text-text-muted">Monitor ScamShield activity, AI performance, and security operations.</p>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {[
          { label: 'Total Analyses', value: stats.totalAnalyses, icon: Search, color: 'text-blue-500' },
          { label: 'Scams Detected', value: stats.scamsDetected, icon: ShieldAlert, color: 'text-danger' },
          { label: 'High/Critical Risk', value: stats.highRisk, icon: AlertTriangle, color: 'text-orange-500' },
          { label: 'Pending Reviews', value: stats.pendingReviews, icon: Clock, color: 'text-purple-500' },
          { label: 'Community Reports', value: stats.communityReports, icon: Users, color: 'text-cyan-500' },
          { label: 'Verified Knowledge', value: stats.verifiedKnowledge, icon: ShieldCheck, color: 'text-success' },
        ].map((kpi, idx) => {
          const Icon = kpi.icon;
          return (
            <div key={idx} className="bg-card rounded-xl shadow-sm border border-border-light p-4 flex flex-col justify-between">
              <div className="flex items-center justify-between mb-2">
                <span className="text-[11px] font-bold text-text-muted uppercase tracking-wider">{kpi.label}</span>
                <Icon className={`w-4 h-4 ${kpi.color}`} />
              </div>
              <div className="text-2xl font-bold text-text-main">{kpi.value.toLocaleString()}</div>
            </div>
          )
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Risk Distribution */}
        <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
          <h3 className="text-lg font-bold text-text-main mb-4">Risk Distribution</h3>
          <div className="h-64">
            {stats.riskDistribution.length === 0 ? (
              <div className="h-full flex items-center justify-center text-text-muted text-sm">No data available</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={stats.riskDistribution}
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {stats.riskDistribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[entry.name as keyof typeof COLORS] || '#8884d8'} />
                    ))}
                  </Pie>
                  <Tooltip 
                    contentStyle={{ backgroundColor: 'var(--color-bg-card)', borderColor: 'var(--color-border-light)', borderRadius: '8px' }}
                    itemStyle={{ color: 'var(--color-text-main)' }}
                  />
                </PieChart>
              </ResponsiveContainer>
            )}
          </div>
          <div className="flex justify-center gap-4 mt-2 flex-wrap">
            {stats.riskDistribution.map(r => (
              <div key={r.name} className="flex items-center text-xs font-semibold text-text-secondary">
                <div className="w-3 h-3 rounded-full mr-1.5" style={{ backgroundColor: COLORS[r.name as keyof typeof COLORS] || '#8884d8' }}></div>
                {r.name} ({r.value})
              </div>
            ))}
          </div>
        </div>

        {/* Classification */}
        <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
          <h3 className="text-lg font-bold text-text-main mb-4">Classification</h3>
          <div className="h-64">
            {stats.classificationDistribution.length === 0 ? (
              <div className="h-full flex items-center justify-center text-text-muted text-sm">No data available</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={stats.classificationDistribution} layout="vertical" margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="var(--color-border-light)" />
                  <XAxis type="number" hide />
                  <YAxis dataKey="name" type="category" axisLine={false} tickLine={false} tick={{ fill: 'var(--color-text-secondary)', fontSize: 12, fontWeight: 600 }} width={80} />
                  <Tooltip 
                    cursor={{ fill: 'var(--color-bg-background)' }}
                    contentStyle={{ backgroundColor: 'var(--color-bg-card)', borderColor: 'var(--color-border-light)', borderRadius: '8px' }}
                  />
                  <Bar dataKey="value" radius={[0, 4, 4, 0]} barSize={24}>
                    {stats.classificationDistribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[entry.name as keyof typeof COLORS] || '#8884d8'} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* Input Types */}
        <div className="bg-card rounded-2xl shadow-sm border border-border-light p-6">
          <h3 className="text-lg font-bold text-text-main mb-4">Input Types</h3>
          <div className="h-64">
             {stats.inputTypeDistribution.length === 0 ? (
              <div className="h-full flex items-center justify-center text-text-muted text-sm">No data available</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={stats.inputTypeDistribution}
                    innerRadius={0}
                    outerRadius={80}
                    dataKey="value"
                  >
                    {stats.inputTypeDistribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[entry.name.toUpperCase() as keyof typeof COLORS] || '#94a3b8'} />
                    ))}
                  </Pie>
                  <Tooltip 
                    contentStyle={{ backgroundColor: 'var(--color-bg-card)', borderColor: 'var(--color-border-light)', borderRadius: '8px' }}
                  />
                </PieChart>
              </ResponsiveContainer>
            )}
          </div>
          <div className="flex justify-center gap-4 mt-2 flex-wrap">
            {stats.inputTypeDistribution.map(r => (
              <div key={r.name} className="flex items-center text-xs font-semibold text-text-secondary uppercase">
                <div className="w-3 h-3 rounded-full mr-1.5" style={{ backgroundColor: COLORS[r.name.toUpperCase() as keyof typeof COLORS] || '#94a3b8' }}></div>
                {r.name} ({r.value})
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Recent Analyses Table */}
      <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
        <div className="p-6 border-b border-border-light flex items-center justify-between">
          <h3 className="text-lg font-bold text-text-main">Recent Analyses</h3>
          <Link to="/admin/analyses" className="text-sm font-semibold text-primary hover:text-primary-hover">View All</Link>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-background text-text-muted text-[11px] uppercase tracking-wider">
              <tr>
                <th className="px-6 py-4 font-bold">ID</th>
                <th className="px-6 py-4 font-bold">Date</th>
                <th className="px-6 py-4 font-bold">Type</th>
                <th className="px-6 py-4 font-bold">Classification</th>
                <th className="px-6 py-4 font-bold">Risk</th>
                <th className="px-6 py-4 font-bold">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-light">
              {stats.recentAnalyses.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-text-muted">No recent analyses found.</td>
                </tr>
              ) : (
                stats.recentAnalyses.map(analysis => (
                  <tr key={analysis.id} className="hover:bg-background/50 transition-colors">
                    <td className="px-6 py-4 font-mono font-medium">#ANL_{analysis.id}</td>
                    <td className="px-6 py-4 text-text-secondary">
                      {new Date(analysis.created_at).toLocaleString()}
                    </td>
                    <td className="px-6 py-4">
                      <span className="font-semibold text-text-secondary uppercase tracking-wider text-[11px]">{analysis.input_type}</span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 rounded text-xs font-bold ${
                        analysis.classification === 'SCAM' ? 'bg-danger/10 text-danger' : 
                        analysis.classification === 'SUSPICIOUS' ? 'bg-warning/10 text-warning' : 
                        'bg-success/10 text-success'
                      }`}>
                        {analysis.classification}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 rounded text-xs font-bold ${
                        ['HIGH', 'CRITICAL'].includes(analysis.risk_level) ? 'bg-danger/10 text-danger' : 
                        analysis.risk_level === 'MEDIUM' ? 'bg-warning/10 text-warning' : 
                        'bg-success/10 text-success'
                      }`}>
                        {analysis.risk_level}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <Link to={`/admin/analyses/${analysis.id}`} className="text-primary hover:text-primary-hover font-semibold text-xs">
                        View
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
}

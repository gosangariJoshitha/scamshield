import React, { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { 
  ChevronLeft, ChevronRight, UserX, UserCheck, CheckCircle, XCircle, X
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { api } from '../services/api';
import AdminBackButton from '../components/AdminBackButton';

interface User {
  id: number;
  email: string;
  full_name: string;
  role: string;
  is_active: boolean;
  created_at: string;
}

interface UserDetails {
  user: User;
  analysis_count: number;
  recent_analyses: Array<{
    id: number;
    created_at: string;
    input_type: string;
    classification: string;
    risk_level: string;
    risk_score: number;
    status: string;
  }>;
}

export default function AdminUsers() {
  const [searchParams] = useSearchParams();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [roleFilter, setRoleFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const search = searchParams.get('search') ?? '';
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [userDetails, setUserDetails] = useState<UserDetails | null>(null);
  const [detailsLoading, setDetailsLoading] = useState(false);
  const [detailsError, setDetailsError] = useState<string | null>(null);

  const fetchUsers = useCallback(async () => {
    try {
      setLoading(true);
      const skip = (page - 1) * pageSize;
      const params = new URLSearchParams({ skip: String(skip), limit: String(pageSize) });
      if (roleFilter) params.set('role', roleFilter);
      if (statusFilter) params.set('status', statusFilter);
      if (search.trim()) params.set('search', search.trim());
      const response = await api.get(`/admin/users?${params.toString()}`);
      setUsers(response.data.items);
      setTotal(response.data.total);
      setTotalPages(response.data.total_pages);
      setError(null);
    } catch (err) {
      setError('Failed to load users');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, roleFilter, statusFilter, search]);

  useEffect(() => {
    void fetchUsers();
  }, [fetchUsers]);

  const handleToggleStatus = async (user: User) => {
    if (!window.confirm(`Are you sure you want to ${user.is_active ? 'deactivate' : 'activate'} this user?`)) return;
    try {
      await api.patch(`/admin/users/${user.id}/status`, {
        is_active: !user.is_active
      });
      setSelectedUser((current) => current?.id === user.id
        ? { ...current, is_active: !user.is_active }
        : current);
      await fetchUsers();
    } catch {
      alert("Failed to update user status");
    }
  };

  const handleRoleChange = async (user: User, newRole: string) => {
    if (user.role === newRole) return;
    if (!window.confirm(`Change role to ${newRole}?`)) return;
    try {
      await api.patch(`/admin/users/${user.id}/role`, {
        role: newRole
      });
      await fetchUsers();
    } catch {
      alert("Failed to update user role");
    }
  };

  const openUserDetails = async (user: User) => {
    setSelectedUser(user);
    setUserDetails(null);
    setDetailsError(null);
    setDetailsLoading(true);
    try {
      const response = await api.get<UserDetails>(`/admin/users/${user.id}`);
      setUserDetails(response.data);
    } catch (err) {
      console.error(err);
      setDetailsError('Unable to load this user’s analysis history.');
    } finally {
      setDetailsLoading(false);
    }
  };

  const closeUserDetails = () => {
    setSelectedUser(null);
    setUserDetails(null);
    setDetailsError(null);
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto pb-10">
      <div className="flex flex-col @content-sm:flex-row @content-sm:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-text-main mb-1">User Management</h1>
          <p className="text-text-muted">Manage system users, roles, and access controls.</p>
        </div>
        <AdminBackButton to="/admin" label="Back to Dashboard" />
      </div>

      <div className="bg-card rounded-xl shadow-sm border border-border-light p-4 flex flex-col @content-sm:flex-row justify-between items-center gap-4">
        <div className="flex w-full flex-col gap-3 @content-sm:w-auto @content-sm:flex-row">
          <select 
            value={roleFilter} 
            onChange={(e) => { setRoleFilter(e.target.value); setPage(1); }}
            className="px-3 py-2 bg-background border border-border-light rounded-lg text-sm text-text-main focus:outline-none focus:border-primary w-full @content-sm:w-auto"
          >
            <option value="">All Roles</option>
            <option value="user">User</option>
            <option value="admin">Admin</option>
          </select>
          <select 
            value={statusFilter} 
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
            className="px-3 py-2 bg-background border border-border-light rounded-lg text-sm text-text-main focus:outline-none focus:border-primary w-full @content-sm:w-auto"
          >
            <option value="">All Statuses</option>
            <option value="ACTIVE">Active</option>
            <option value="INACTIVE">Inactive</option>
          </select>
        </div>
      </div>

      <div className="bg-card rounded-2xl shadow-sm border border-border-light overflow-hidden">
        {loading && users.length === 0 ? (
          <div className="p-12 flex justify-center">
            <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : error ? (
          <div className="p-12 text-center text-danger font-medium">{error}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm whitespace-nowrap">
              <thead className="bg-background text-text-muted text-[11px] uppercase tracking-wider border-b border-border-light">
                <tr>
                  <th className="px-6 py-4 font-bold">User</th>
                  <th className="px-6 py-4 font-bold">Joined Date</th>
                  <th className="px-6 py-4 font-bold">Role</th>
                  <th className="px-6 py-4 font-bold">Status</th>
                  <th className="px-6 py-4 font-bold text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-light">
                {users.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-text-muted">No users found.</td>
                  </tr>
                ) : (
                  users.map((item) => (
                    <tr
                      key={item.id}
                      role="button"
                      tabIndex={0}
                      aria-label={`Open details for ${item.full_name || item.email}`}
                      onClick={() => void openUserDetails(item)}
                      onKeyDown={(event) => {
                        if (event.key === 'Enter' || event.key === ' ') {
                          event.preventDefault();
                          void openUserDetails(item);
                        }
                      }}
                      className="cursor-pointer transition-colors hover:bg-background/50 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary"
                    >
                      <td className="px-6 py-4">
                        <div className="flex items-center space-x-3">
                          <div className="w-8 h-8 rounded-full bg-primary/20 text-primary flex items-center justify-center font-bold text-xs shrink-0">
                            {item.full_name ? item.full_name.charAt(0).toUpperCase() : 'U'}
                          </div>
                          <div>
                            <button
                              type="button"
                              onClick={(event) => { event.stopPropagation(); void openUserDetails(item); }}
                              className="text-left text-sm font-bold text-text-main hover:text-primary"
                              aria-label={`View details for ${item.full_name || item.email}`}
                            >
                              {item.full_name || 'Unknown'}
                            </button>
                            <p className="text-xs text-text-muted">{item.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-text-secondary">
                        {new Date(item.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4">
                        <select
                          value={item.role}
                          onClick={(event) => event.stopPropagation()}
                          onChange={(e) => void handleRoleChange(item, e.target.value)}
                          className={`text-xs font-bold px-2 py-1 rounded bg-background border ${item.role === 'admin' ? 'border-primary/50 text-primary' : 'border-border-light text-text-secondary'}`}
                        >
                          <option value="user">USER</option>
                          <option value="admin">ADMIN</option>
                        </select>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider flex items-center w-max gap-1 ${
                          item.is_active ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'
                        }`}>
                          {item.is_active ? <CheckCircle className="w-3 h-3" /> : <XCircle className="w-3 h-3" />}
                          {item.is_active ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right space-x-2">
                        <button 
                          onClick={(event) => { event.stopPropagation(); void handleToggleStatus(item); }}
                          className={`p-1.5 rounded transition-colors ${
                            item.is_active ? 'text-danger hover:bg-danger/10' : 'text-success hover:bg-success/10'
                          }`}
                          title={item.is_active ? "Deactivate User" : "Activate User"}
                        >
                          {item.is_active ? <UserX className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />}
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
        
        {/* Pagination */}
        {!loading && totalPages > 1 && (
          <div className="p-4 border-t border-border-light flex items-center justify-between bg-background/50">
            <div className="text-sm text-text-muted font-medium">
              Showing <span className="text-text-main font-bold">{(page - 1) * pageSize + 1}</span> to <span className="text-text-main font-bold">{Math.min(page * pageSize, total)}</span> of <span className="text-text-main font-bold">{total}</span> users
            </div>
            <div className="flex items-center space-x-2">
              <button 
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
              <div className="text-sm font-semibold text-text-main px-3 py-1 bg-card border border-border-light rounded-lg">
                Page {page} of {totalPages}
              </div>
              <button 
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1.5 rounded-lg border border-border-light text-text-secondary hover:bg-card disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        )}
      </div>

      {selectedUser && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) closeUserDetails();
          }}
        >
          <section
            role="dialog"
            aria-modal="true"
            aria-labelledby="user-details-title"
            className="w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl border border-border-light bg-card p-6 shadow-xl"
          >
            <div className="flex items-start justify-between gap-4">
              <div>
                <h2 id="user-details-title" className="text-xl font-bold text-text-main">
                  {selectedUser.full_name || 'User details'}
                </h2>
                <p className="mt-1 text-sm text-text-muted">{selectedUser.email}</p>
              </div>
              <button
                type="button"
                onClick={closeUserDetails}
                className="rounded-lg p-2 text-text-muted hover:bg-background hover:text-text-main"
                aria-label="Close user details"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="mt-4 flex flex-col gap-3 rounded-xl border border-warning/20 bg-warning/5 p-4 @content-sm:flex-row @content-sm:items-center @content-sm:justify-between">
              <p className="text-sm text-text-secondary">
                Account access can be disabled and restored. Permanent deletion is not available here so user history and audit records remain intact.
              </p>
              <button
                type="button"
                onClick={() => void handleToggleStatus(selectedUser)}
                className={`inline-flex shrink-0 items-center justify-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold ${
                  selectedUser.is_active
                    ? 'bg-danger/10 text-danger hover:bg-danger/15'
                    : 'bg-success/10 text-success hover:bg-success/15'
                }`}
              >
                {selectedUser.is_active ? <UserX size={16} /> : <UserCheck size={16} />}
                {selectedUser.is_active ? 'Deactivate account' : 'Reactivate account'}
              </button>
            </div>

            <div className="mt-6 grid grid-cols-2 gap-3 @content-sm:grid-cols-4">
              <div className="rounded-xl border border-border-light bg-background p-3">
                <p className="text-[10px] font-bold uppercase text-text-muted">User ID</p>
                <p className="mt-1 font-mono text-sm text-text-main">#{selectedUser.id}</p>
              </div>
              <div className="rounded-xl border border-border-light bg-background p-3">
                <p className="text-[10px] font-bold uppercase text-text-muted">Role</p>
                <p className="mt-1 text-sm font-semibold capitalize text-text-main">{selectedUser.role}</p>
              </div>
              <div className="rounded-xl border border-border-light bg-background p-3">
                <p className="text-[10px] font-bold uppercase text-text-muted">Account</p>
                <p className={`mt-1 text-sm font-semibold ${selectedUser.is_active ? 'text-success' : 'text-danger'}`}>
                  {selectedUser.is_active ? 'Active' : 'Inactive'}
                </p>
              </div>
              <div className="rounded-xl border border-border-light bg-background p-3">
                <p className="text-[10px] font-bold uppercase text-text-muted">Joined</p>
                <p className="mt-1 text-sm text-text-main">{new Date(selectedUser.created_at).toLocaleDateString()}</p>
              </div>
            </div>

            <div className="mt-6">
              <div className="mb-3 flex items-center justify-between">
                <h3 className="font-bold text-text-main">Recent analyses</h3>
                {userDetails && (
                  <span className="text-xs text-text-muted">{userDetails.analysis_count} total</span>
                )}
              </div>
              {detailsLoading ? (
                <div className="py-8 text-center text-sm text-text-muted">Loading user activity…</div>
              ) : detailsError ? (
                <div className="rounded-xl border border-danger/20 bg-danger/5 p-4 text-sm text-danger">{detailsError}</div>
              ) : userDetails?.recent_analyses.length ? (
                <div className="divide-y divide-border-light rounded-xl border border-border-light">
                  {userDetails.recent_analyses.map((analysis) => (
                    <div key={analysis.id} className="flex items-center justify-between gap-4 p-3">
                      <div className="min-w-0">
                        <Link
                          to={`/admin/analyses/${analysis.id}`}
                          onClick={closeUserDetails}
                          className="font-mono text-sm font-semibold text-primary hover:underline"
                        >
                          #ANL_{analysis.id}
                        </Link>
                        <p className="mt-1 text-xs text-text-muted">
                          {analysis.classification || 'Unclassified'} · {analysis.risk_level || 'Unknown'} risk · {analysis.risk_score ?? '—'}/100
                        </p>
                      </div>
                      <div className="shrink-0 text-right">
                        <p className="text-xs text-text-secondary">{analysis.input_type}</p>
                        <p className="text-[11px] text-text-muted">{new Date(analysis.created_at).toLocaleDateString()}</p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="rounded-xl border border-border-light bg-background p-6 text-center text-sm text-text-muted">
                  This user has no analyses yet.
                </div>
              )}
            </div>
          </section>
        </div>
      )}

    </div>
  );
}

import { lazy, Suspense } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import ProtectedRoute from './components/ProtectedRoute';
import SidebarLayout from './components/SidebarLayout';
import PublicLayout from './components/PublicLayout';
import AdminLayout from './components/AdminLayout';

import { useTheme } from './hooks/useTheme';

const Landing = lazy(() => import('./pages/Landing'));
const Login = lazy(() => import('./pages/Login'));
const Signup = lazy(() => import('./pages/Signup'));
const ForgotPassword = lazy(() => import('./pages/ForgotPassword'));
const VerifyEmail = lazy(() => import('./pages/VerifyEmail'));
const Terms = lazy(() => import('./pages/Terms'));
const Privacy = lazy(() => import('./pages/Privacy'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Analyze = lazy(() => import('./pages/Analyze'));
const AnalysisOverview = lazy(() => import('./pages/AnalysisOverview'));
const AnalysisDetails = lazy(() => import('./pages/AnalysisDetails'));
const History = lazy(() => import('./pages/History'));
const Community = lazy(() => import('./pages/Community'));
const Profile = lazy(() => import('./pages/Profile'));
const ProfileSettings = lazy(() => import('./pages/ProfileSettings'));
const MonitoringDashboard = lazy(() => import('./pages/MonitoringDashboard'));
const AdminReviewCenter = lazy(() => import('./pages/AdminReviewCenter'));
const AdminReviewDetails = lazy(() => import('./pages/AdminReviewDetails'));
const AdminOverview = lazy(() => import('./pages/AdminOverview'));
const AdminAnalyses = lazy(() => import('./pages/AdminAnalyses'));
const AdminAnalysisDetails = lazy(() => import('./pages/AdminAnalysisDetails'));
const AdminCommunity = lazy(() => import('./pages/AdminCommunity'));
const AdminKnowledge = lazy(() => import('./pages/AdminKnowledge'));
const AdminUsers = lazy(() => import('./pages/AdminUsers'));
const AdminAuditLogs = lazy(() => import('./pages/AdminAuditLogs'));
const AdminSettings = lazy(() => import('./pages/AdminSettings'));

function App() {
  useTheme(); // Initialize theme on mount

  return (
    <Router>
      <Suspense fallback={<div className="grid min-h-screen place-items-center bg-background text-text-muted" role="status">Loading page...</div>}>
        <Routes>
          <Route element={<PublicLayout />}>
            <Route path="/" element={<Landing />} />
          </Route>
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />
          <Route path="/forgot-password" element={<ForgotPassword />} />
          <Route path="/verify-email" element={<VerifyEmail />} />
          <Route path="/terms" element={<Terms />} />
          <Route path="/privacy" element={<Privacy />} />
          <Route element={<ProtectedRoute><SidebarLayout /></ProtectedRoute>}>
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/analyze" element={<Analyze />} />
            <Route path="/results/:id" element={<AnalysisOverview />} />
            <Route path="/results/:id/details" element={<AnalysisDetails />} />
            <Route path="/history" element={<History />} />
            <Route path="/community" element={<Community />} />
            <Route path="/profile" element={<Profile />} />
            <Route path="/profile/settings" element={<ProfileSettings />} />
          </Route>

          <Route path="/admin/login" element={<Login adminOnly />} />
          <Route element={<AdminLayout />}>
            <Route path="/admin" element={<AdminOverview />} />
            <Route path="/admin/analyses" element={<AdminAnalyses />} />
            <Route path="/admin/analyses/:id" element={<AdminAnalysisDetails />} />
            <Route path="/admin/community" element={<AdminCommunity />} />
            <Route path="/admin/knowledge" element={<AdminKnowledge />} />
            <Route path="/admin/users" element={<AdminUsers />} />
            <Route path="/admin/audit" element={<AdminAuditLogs />} />
            <Route path="/admin/health" element={<Navigate to="/admin/monitoring" replace />} />
            <Route path="/admin/settings" element={<AdminSettings />} />
            <Route path="/admin/monitoring" element={<MonitoringDashboard />} />
            <Route path="/admin/reviews" element={<AdminReviewCenter />} />
            <Route path="/admin/reviews/:id" element={<AdminReviewDetails />} />
          </Route>
        </Routes>
      </Suspense>
    </Router>
  );
}

export default App;

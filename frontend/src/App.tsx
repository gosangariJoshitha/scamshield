import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import ProtectedRoute from './components/ProtectedRoute';
import SidebarLayout from './components/SidebarLayout';
import PublicLayout from './components/PublicLayout';

import Landing from './pages/Landing';
import Login from './pages/Login';
import Signup from './pages/Signup';
import ForgotPassword from './pages/ForgotPassword';
import Terms from './pages/Terms';
import Privacy from './pages/Privacy';
import Dashboard from './pages/Dashboard';
import Analyze from './pages/Analyze';
import AnalysisOverview from './pages/AnalysisOverview';
import AnalysisDetails from './pages/AnalysisDetails';
import History from './pages/History';
import Community from './pages/Community';
import Profile from './pages/Profile';
import ProfileSettings from './pages/ProfileSettings';

import { useTheme } from './hooks/useTheme';

function App() {
  useTheme(); // Initialize theme on mount

  return (
    <Router>
      <Routes>
        <Route element={<PublicLayout />}>
          <Route path="/" element={<Landing />} />
        </Route>
        
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<Signup />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
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
      </Routes>
    </Router>
  );
}

export default App;

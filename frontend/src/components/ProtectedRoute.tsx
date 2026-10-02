import React from 'react';
import { Navigate } from 'react-router-dom';
import { hasToken } from '../services/token';

export default function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = hasToken();
  if (!isAuthenticated) {
    return <Navigate to="/login" />;
  }
  return children;
}

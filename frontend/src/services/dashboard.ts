import { api } from './api';

export interface DashboardStats {
  total_analyses: number;
  scams_detected: number;
  safe_messages: number;
  high_risk: number;
}

export const dashboardService = {
  getStats: async (): Promise<DashboardStats> => {
    const response = await api.get('/analysis/dashboard');
    return response.data;
  }
};

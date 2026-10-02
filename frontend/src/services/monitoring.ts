import { api } from './api';

export const monitoringService = {
  getOverview: async () => {
    const response = await api.get('/admin/monitoring/overview');
    return response.data;
  },
  getPerformance: async () => {
    const response = await api.get('/admin/monitoring/performance');
    return response.data;
  },
  getChannels: async () => {
    const response = await api.get('/admin/monitoring/channels');
    return response.data;
  },
  getHealth: async () => {
    const response = await api.get('/admin/monitoring/health');
    return response.data;
  }
};

import { api } from './api';

export interface CommunityReport {
  id: number;
  content: string;
  category: string;
  description?: string;
  evidence?: string;
  analysis_id?: number | null;
  reporter_name?: string | null;
  status: string;
  created_at: string;
}

export interface CommunityReportCreate {
  content: string;
  category: string;
  description?: string;
  evidence?: string;
  analysis_id?: number;
}

export const communityService = {
  getReports: async (): Promise<CommunityReport[]> => {
    const response = await api.get('/community/reports');
    return response.data;
  },

  createReport: async (report: CommunityReportCreate): Promise<CommunityReport> => {
    const response = await api.post('/community/reports', report);
    return response.data;
  },
};

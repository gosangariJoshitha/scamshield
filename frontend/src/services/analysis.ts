import { api } from './api';

export interface AnalysisResult {
  id: number;
  content: string;
  risk_score: number;
  risk_level: string;
  classification: string;
  ml_probability: number;
  category: string;
  indicators: string[];
  explanation: string;
  evidence: string[];
  recommended_action: string;
  created_at: string;
}

export const analysisService = {
  getHistory: async (): Promise<AnalysisResult[]> => {
    const response = await api.get('/analysis/history');
    return response.data;
  },
  
  getRecentAnalyses: async (limit: number = 5): Promise<AnalysisResult[]> => {
    const history = await analysisService.getHistory();
    return history.slice(0, limit);
  }
};

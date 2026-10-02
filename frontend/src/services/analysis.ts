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
  retrieved_evidence_data?: {
    knowledge_id: number;
    title: string;
    category: string;
    similarity_score: number;
    pattern: string;
    safe_action: string;
    source: string;
  }[];
  evidence_status?: string;
  recommended_action: string;
  created_at: string;
  input_type?: string;
  original_filename?: string;
  llm_confidence?: number;
  llm_reasoning?: string;
  processing_status?: string;
  model_version?: string;
  rag_version?: string;
}

export const analysisService = {
  getHistory: async (): Promise<AnalysisResult[]> => {
    const response = await api.get('/analysis/history');
    return response.data;
  },

  getAnalysis: async (analysisId: number): Promise<AnalysisResult> => {
    const response = await api.get(`/analysis/${analysisId}`);
    return response.data;
  },
  
  getRecentAnalyses: async (limit: number = 5): Promise<AnalysisResult[]> => {
    const history = await analysisService.getHistory();
    return history.slice(0, limit);
  }
};

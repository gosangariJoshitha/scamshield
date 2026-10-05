import { api } from './api';

export interface SafeActions {
  canonical: string[];
  translations: Record<'en' | 'hi' | 'te', string[]>;
  default_language: 'en' | 'hi' | 'te';
}

export interface AnalysisResult {
  id: number;
  content: string;
  original_text?: string | null;
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
  safe_actions?: SafeActions | null;
  created_at: string;
  input_type?: string;
  original_filename?: string;
  llm_confidence?: number;
  llm_reasoning?: string;
  processing_status?: string;
  model_version?: string;
  rag_version?: string;
  escalation_status?: string;
  review_case_id?: number | null;
  email_notification_status?: 'PENDING' | 'SENT' | 'FAILED' | 'NOT_REQUIRED' | string;
  jira_status?: 'PENDING' | 'CREATED' | 'FAILED' | 'NOT_REQUIRED' | string;
  jira_issue_key?: string | null;
  jira_issue_url?: string | null;
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

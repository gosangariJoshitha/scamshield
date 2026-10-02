import { api } from './api';

export interface ReviewCase {
    id: number;
    analysis_id: number;
    status: string;
    priority: string;
    escalation_reasons: string[];
    review_decision: string | null;
    reviewer_notes: string | null;
    assigned_reviewer_id: number | null;
    created_at: string;
    jira: {
        enabled: boolean;
        issue_key: string | null;
    };
    analysis: any;
    events: any[];
}

export const reviewService = {
    // User endpoints
    requestReview: async (analysisId: number) => {
        const response = await api.post(`/reviews/request/${analysisId}`);
        return response.data;
    },
    
    getMyReviews: async () => {
        const response = await api.get('/reviews/my');
        return response.data;
    },
    
    provideAdditionalInfo: async (caseId: number, notes: string) => {
        const response = await api.post(`/reviews/${caseId}/information`, { notes });
        return response.data;
    },
    
    // Admin endpoints
    getAllReviews: async () => {
        const response = await api.get('/reviews/admin/list');
        return response.data;
    },
    
    getReviewDetails: async (caseId: number) => {
        const response = await api.get(`/reviews/admin/${caseId}`);
        return response.data;
    },
    
    assignReview: async (caseId: number) => {
        const response = await api.post(`/reviews/admin/${caseId}/assign`);
        return response.data;
    },
    
    startReview: async (caseId: number) => {
        const response = await api.post(`/reviews/admin/${caseId}/start`);
        return response.data;
    },
    
    submitDecision: async (caseId: number, decision: string, notes: string) => {
        const response = await api.post(`/reviews/admin/${caseId}/decision`, { decision, notes });
        return response.data;
    },
    
    createJiraTicket: async (caseId: number) => {
        const response = await api.post(`/reviews/admin/${caseId}/jira`);
        return response.data;
    },
    
    createTrustedKnowledge: async (caseId: number, data: any) => {
        const response = await api.post(`/reviews/admin/${caseId}/create-knowledge`, data);
        return response.data;
    }
};

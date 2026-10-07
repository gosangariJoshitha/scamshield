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

export interface ReviewListResponse {
    items: Array<ReviewCase & {
        risk_level: string | null;
        classification: string | null;
        category: string | null;
        input_type: string | null;
        content_preview: string;
        reporter: string;
        escalation_reason: string | null;
    }>;
    total: number;
    page: number;
    page_size: number;
    total_pages: number;
    summary: Record<string, number>;
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
    getAllReviews: async (params: {
        skip?: number;
        limit?: number;
        search?: string;
        review_status?: string;
        priority?: string;
        risk_level?: string;
        input_type?: string;
    } = {}): Promise<ReviewListResponse> => {
        const response = await api.get('/reviews/admin/list', { params });
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
    
    startReview: async (caseId: number): Promise<{
        success: boolean;
        status: string;
        assigned_reviewer_id: number | null;
    }> => {
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

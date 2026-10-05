import { api } from './api';
import { clearToken } from './token';

export interface SignupResponse {
  account_created: boolean;
  email_verified: boolean;
  verification_email_sent: boolean;
  verification_challenge_id?: string | null;
  message: string;
}

export const auth = {
  async me() {
    const response = await api.get('/auth/me');
    return response.data;
  },
  async login(
    credentials: { email: string; password: string },
    portal: 'user' | 'admin' = 'user',
    rememberMe = false,
  ) {
    const formData = new FormData();
    formData.append('username', credentials.email);
    formData.append('password', credentials.password);
    formData.append('remember_me', String(rememberMe));
    const endpoint = portal === 'admin' ? '/auth/admin/login' : '/auth/login';
    const response = await api.post(endpoint, formData);
    return response.data;
  },
  async verifyLogin(challenge_id: string, code: string, remember_me: boolean) {
    const response = await api.post('/auth/login/verify', { challenge_id, code, remember_me });
    return response.data;
  },
  async signup(data: { email: string; password: string; full_name: string }): Promise<SignupResponse> {
    const response = await api.post('/auth/signup', data);
    return response.data;
  },
  async verifyEmail(challenge_id: string, code: string) {
    const response = await api.post('/auth/verify-email', { challenge_id, code });
    return response.data;
  },
  async resendVerification() {
    const response = await api.post('/auth/resend-verification');
    return response.data;
  },
  logout() {
    clearToken();
  },
  async forgotPassword(email: string) {
    const response = await api.post('/auth/forgot-password', { email });
    return response.data;
  },
  async resetPassword(data: any) {
    const response = await api.post('/auth/reset-password', data);
    return response.data;
  },
  async updateProfile(data: any) {
    const response = await api.put('/auth/me', data);
    return response.data;
  },
  async changePassword(current_password: string, new_password: string) {
    const response = await api.post('/auth/change-password', { current_password, new_password });
    return response.data;
  },
  async deleteAccount() {
    const response = await api.delete('/auth/me');
    return response.data;
  }
};

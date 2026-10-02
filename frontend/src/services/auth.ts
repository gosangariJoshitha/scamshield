import { api } from './api';
import { clearToken } from './token';

export const auth = {
  async me() {
    const response = await api.get('/auth/me');
    return response.data;
  },
  async login(credentials: any) {
    const formData = new FormData();
    formData.append('username', credentials.email);
    formData.append('password', credentials.password);
    const response = await api.post('/auth/login', formData);
    return response.data;
  },
  async signup(data: any) {
    const response = await api.post('/auth/signup', data);
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

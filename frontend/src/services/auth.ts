import { api } from './api';

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
    localStorage.removeItem('token');
  },
  async forgotPassword(email: string) {
    const response = await api.post('/auth/forgot-password', { email });
    return response.data;
  },
  async resetPassword(data: any) {
    const response = await api.post('/auth/reset-password', data);
    return response.data;
  }
};

import axios from 'axios';
import { getToken } from './token';

const rawUrl = (
  import.meta.env.VITE_API_URL ||
  import.meta.env.VITE_API_BASE_URL ||
  'https://scamshield-backend-f0wc.onrender.com/api'
).trim().replace(/\/+$/, '');

const API_URL = rawUrl.endsWith('/api') ? rawUrl : `${rawUrl}/api`;

export const api = axios.create({
  baseURL: API_URL,
  timeout: 45000,
});

api.interceptors.request.use((config) => {
  const token = getToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
      error.message = 'The server took too long to respond. The AI backend may be warming up. Please try again.';
      if (error.response) {
        error.response.data = { detail: error.message };
      } else {
        error.response = { status: 504, data: { detail: error.message } };
      }
    } else if (!error.response && error.request) {
      error.message = 'Could not reach ScamShield. Check your network or API connection.';
      error.response = { status: 503, data: { detail: error.message } };
    }
    return Promise.reject(error);
  }
);

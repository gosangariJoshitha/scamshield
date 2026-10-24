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
});

api.interceptors.request.use((config) => {
  const token = getToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

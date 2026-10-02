import axios from 'axios';
import { getToken } from './token';

const localHost = ['localhost', '127.0.0.1'].includes(window.location.hostname)
  ? window.location.hostname
  : 'localhost';
const API_URL = import.meta.env.VITE_API_URL
  || (import.meta.env.DEV ? '/api' : `http://${localHost}:8000/api`);

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

import axios from 'axios';
import { getToken } from './token';

const API_URL = import.meta.env.VITE_API_URL?.trim() || '/api';

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

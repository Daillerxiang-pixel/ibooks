import axios, { type AxiosRequestConfig } from 'axios';
import { message } from 'ant-design-vue';

const TOKEN_KEY = 'ibooks_admin_token';

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}
export function setToken(t: string | null) {
  if (t) localStorage.setItem(TOKEN_KEY, t);
  else localStorage.removeItem(TOKEN_KEY);
}

const _axios = axios.create({
  baseURL: '/api',
  timeout: 30000,
});

_axios.interceptors.request.use((cfg) => {
  const t = getToken();
  if (t) {
    cfg.headers = cfg.headers || {};
    cfg.headers['Authorization'] = `Bearer ${t}`;
  }
  return cfg;
});

_axios.interceptors.response.use(
  (resp) => {
    const data = resp.data;
    if (data && typeof data === 'object' && 'success' in data) {
      if (!data.success) {
        const err = data.error || '請求失敗';
        message.error(err);
        return Promise.reject(new Error(err));
      }
      // 直接返回 data 部分；下方包一層讓 TS 把返回類型視為 T
      return data.data;
    }
    return data;
  },
  (error) => {
    if (error.response?.status === 401) {
      setToken(null);
      message.warning('登入已過期，請重新登入');
      if (location.pathname !== '/login') {
        location.href = '/login';
      }
    } else {
      const msg = error.response?.data?.error || error.message || '網絡錯誤';
      message.error(msg);
    }
    return Promise.reject(error);
  },
);

/**
 * 把 axios 的 `Promise<AxiosResponse<T>>` 重新包裝為 `Promise<T>`，
 * 這樣業務層直接拿到 `data.data`，無需到處 `(.data)` 取值。
 */
const api = {
  get<T = unknown>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return _axios.get<T, T>(url, config);
  },
  post<T = unknown>(url: string, body?: unknown, config?: AxiosRequestConfig): Promise<T> {
    return _axios.post<T, T>(url, body, config);
  },
  put<T = unknown>(url: string, body?: unknown, config?: AxiosRequestConfig): Promise<T> {
    return _axios.put<T, T>(url, body, config);
  },
  delete<T = unknown>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return _axios.delete<T, T>(url, config);
  },
};

export default api;

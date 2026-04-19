import { defineStore } from 'pinia';
import { authApi } from '../api/admin';
import { setToken, getToken } from '../api/client';

interface AdminInfo {
  id: number;
  username: string;
  role: string;
}

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: getToken() as string | null,
    admin: null as AdminInfo | null,
    loaded: false,
  }),
  getters: {
    isLogged: (s) => !!s.token,
  },
  actions: {
    async login(username: string, password: string) {
      const r = await authApi.login(username, password);
      this.token = r.token;
      this.admin = r.admin;
      setToken(r.token);
    },
    async fetchProfile() {
      if (!this.token) return;
      try {
        const p = await authApi.profile();
        this.admin = { id: p.id, username: p.username, role: p.role };
        this.loaded = true;
      } catch (_) {
        this.logout();
      }
    },
    logout() {
      this.token = null;
      this.admin = null;
      setToken(null);
    },
  },
});

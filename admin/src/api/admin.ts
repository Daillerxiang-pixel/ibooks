import api from './client';

// 認證
export const authApi = {
  login: (username: string, password: string) =>
    api.post<{ token: string; admin: any }>('/admin/auth/login', { username, password }),
  profile: () => api.get<any>('/admin/auth/profile'),
  changePassword: (oldPwd: string, newPwd: string) =>
    api.post('/admin/auth/change-password', { oldPwd, newPwd }),
};

// 儀表盤
export const dashboardApi = {
  summary: () => api.get<any>('/admin/dashboard/summary'),
  userTrend: () => api.get<any[]>('/admin/dashboard/user-trend'),
  revenueTrend: () => api.get<any[]>('/admin/dashboard/revenue-trend'),
};

// 書籍
export interface AdminBook {
  id: number;
  title: string;
  author?: string;
  cover_url?: string;
  description?: string;
  category?: string;
  tags?: string[];
  status?: string;
  word_count?: number;
  chapter_count?: number;
  is_active?: number;
  created_at?: string;
}

export const booksApi = {
  list: (params: { page?: number; size?: number; q?: string; category?: string }) =>
    api.get<{ items: AdminBook[]; total: number; page: number; size: number }>(
      '/admin/books',
      { params },
    ),
  detail: (id: number) => api.get<AdminBook>(`/admin/books/${id}`),
  create: (data: Partial<AdminBook>) => api.post<AdminBook>('/admin/books', data),
  update: (id: number, data: Partial<AdminBook>) =>
    api.put<AdminBook>(`/admin/books/${id}`, data),
  remove: (id: number) => api.delete(`/admin/books/${id}`),
  toggle: (id: number) => api.post(`/admin/books/${id}/toggle`),
};

// 章節
export interface AdminChapter {
  id: number;
  book_id: number;
  chapter_num: number;
  title: string;
  price: number;
  word_count?: number;
  content_oss_urls?: string;
  content_is_encrypted?: boolean;
  content_unlock_key_base64?: string;
  content?: string;
}

export const chaptersApi = {
  list: (bookId: number) => api.get<AdminChapter[]>(`/admin/books/${bookId}/chapters`),
  create: (bookId: number, data: Partial<AdminChapter>) =>
    api.post<AdminChapter>(`/admin/books/${bookId}/chapters`, data),
  update: (bookId: number, id: number, data: Partial<AdminChapter>) =>
    api.put<AdminChapter>(`/admin/books/${bookId}/chapters/${id}`, data),
  remove: (bookId: number, id: number) =>
    api.delete(`/admin/books/${bookId}/chapters/${id}`),
  batchPrice: (bookId: number, payload: { ids?: number[]; price: number; setAll?: boolean }) =>
    api.post(`/admin/books/${bookId}/chapters/batch-price`, payload),
};

// 分類
export interface AdminCategory {
  id: number;
  name: string;
  slug?: string;
  description?: string;
  sort?: number;
  is_active?: number;
}
export const categoriesApi = {
  list: () => api.get<AdminCategory[]>('/admin/categories'),
  create: (data: Partial<AdminCategory>) => api.post<AdminCategory>('/admin/categories', data),
  update: (id: number, data: Partial<AdminCategory>) =>
    api.put<AdminCategory>(`/admin/categories/${id}`, data),
  remove: (id: number) => api.delete(`/admin/categories/${id}`),
};

// 優惠券
export interface AdminCoupon {
  id: number;
  code: string;
  name: string;
  type: 'amount' | 'percent';
  value: number;
  valid_from?: string | null;
  valid_to?: string | null;
  max_uses?: number;
  used_count?: number;
  is_active?: number;
}
export const couponsApi = {
  list: () => api.get<AdminCoupon[]>('/admin/coupons'),
  create: (data: Partial<AdminCoupon>) => api.post<AdminCoupon>('/admin/coupons', data),
  update: (id: number, data: Partial<AdminCoupon>) =>
    api.put<AdminCoupon>(`/admin/coupons/${id}`, data),
  remove: (id: number) => api.delete(`/admin/coupons/${id}`),
};

// 充值套餐
export interface AdminCoinPackage {
  id: number;
  name: string;
  price_cents: number;
  coin_amount: number;
  bonus_coin?: number;
  badge?: string;
  sort?: number;
  is_active?: number;
}
export const coinPackagesApi = {
  list: () => api.get<AdminCoinPackage[]>('/admin/coin-packages'),
  create: (data: Partial<AdminCoinPackage>) =>
    api.post<AdminCoinPackage>('/admin/coin-packages', data),
  update: (id: number, data: Partial<AdminCoinPackage>) =>
    api.put<AdminCoinPackage>(`/admin/coin-packages/${id}`, data),
  remove: (id: number) => api.delete(`/admin/coin-packages/${id}`),
};

// 用戶
export interface AdminUserRow {
  id: string;
  phone?: string;
  nickname?: string;
  avatar?: string;
  balance: number;
  created_at: string;
}
export const usersApi = {
  list: (params: { page?: number; size?: number; q?: string }) =>
    api.get<{ items: AdminUserRow[]; total: number; page: number; size: number }>(
      '/admin/users',
      { params },
    ),
  adjustBalance: (id: string, delta: number) =>
    api.post(`/admin/users/${id}/balance`, { delta }),
  remove: (id: string) => api.delete(`/admin/users/${id}`),
};

// 推薦欄位
export interface AdminFeaturedSection {
  id: number;
  name: string;
  layout: string;
  sort: number;
  is_active: number;
}
export interface AdminFeaturedItem {
  id: number;
  section_id: number;
  book_id: number;
  sort: number;
}
export const featuredApi = {
  listSections: () => api.get<AdminFeaturedSection[]>('/admin/featured/sections'),
  createSection: (data: Partial<AdminFeaturedSection>) =>
    api.post<AdminFeaturedSection>('/admin/featured/sections', data),
  updateSection: (id: number, data: Partial<AdminFeaturedSection>) =>
    api.put<AdminFeaturedSection>(`/admin/featured/sections/${id}`, data),
  removeSection: (id: number) => api.delete(`/admin/featured/sections/${id}`),
  listItems: (id: number) => api.get<AdminFeaturedItem[]>(`/admin/featured/sections/${id}/items`),
  addItem: (id: number, data: { book_id: number; sort?: number }) =>
    api.post<AdminFeaturedItem>(`/admin/featured/sections/${id}/items`, data),
  removeItem: (itemId: number) => api.delete(`/admin/featured/items/${itemId}`),
};

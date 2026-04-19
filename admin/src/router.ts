import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router';
import { useAuthStore } from './stores/auth';

const routes: RouteRecordRaw[] = [
  { path: '/login', component: () => import('./views/Login.vue'), meta: { public: true } },
  {
    path: '/',
    component: () => import('./layouts/AdminLayout.vue'),
    children: [
      { path: '', redirect: '/dashboard' },
      { path: 'dashboard', component: () => import('./views/Dashboard.vue'), meta: { title: '儀表盤' } },
      { path: 'books', component: () => import('./views/Books.vue'), meta: { title: '書籍管理' } },
      { path: 'books/:id/chapters', component: () => import('./views/Chapters.vue'), meta: { title: '章節 / 計費' } },
      { path: 'categories', component: () => import('./views/Categories.vue'), meta: { title: '分類管理' } },
      { path: 'coupons', component: () => import('./views/Coupons.vue'), meta: { title: '優惠券' } },
      { path: 'coin-packages', component: () => import('./views/CoinPackages.vue'), meta: { title: '充值套餐' } },
      { path: 'featured', component: () => import('./views/Featured.vue'), meta: { title: '書城推薦' } },
      { path: 'users', component: () => import('./views/Users.vue'), meta: { title: '用戶管理' } },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
];

export const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.beforeEach(async (to) => {
  const auth = useAuthStore();
  if (to.meta?.public) return true;
  if (!auth.isLogged) return { path: '/login', query: { from: to.fullPath } };
  if (!auth.loaded) await auth.fetchProfile();
  return true;
});

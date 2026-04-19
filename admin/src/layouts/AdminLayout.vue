<template>
  <a-layout style="min-height: 100vh">
    <a-layout-sider :collapsed="collapsed" collapsible @collapse="(v: boolean) => (collapsed = v)" theme="light" width="220">
      <div class="brand">
        <span class="brand-mark">📚</span>
        <span v-if="!collapsed" class="brand-text">iBooks 管理</span>
      </div>
      <a-menu mode="inline" :selected-keys="[selectedKey]" @click="onMenu">
        <a-menu-item key="/dashboard">
          <template #icon><DashboardOutlined /></template>
          儀表盤
        </a-menu-item>
        <a-menu-item key="/books">
          <template #icon><BookOutlined /></template>
          書籍管理
        </a-menu-item>
        <a-menu-item key="/categories">
          <template #icon><AppstoreOutlined /></template>
          分類管理
        </a-menu-item>
        <a-menu-item key="/featured">
          <template #icon><StarOutlined /></template>
          書城推薦
        </a-menu-item>
        <a-menu-item key="/coin-packages">
          <template #icon><DollarOutlined /></template>
          充值套餐
        </a-menu-item>
        <a-menu-item key="/coupons">
          <template #icon><GiftOutlined /></template>
          優惠券
        </a-menu-item>
        <a-menu-item key="/users">
          <template #icon><TeamOutlined /></template>
          用戶管理
        </a-menu-item>
      </a-menu>
    </a-layout-sider>
    <a-layout>
      <a-layout-header class="header">
        <span class="page-title">{{ pageTitle }}</span>
        <a-dropdown>
          <a class="user">
            <UserOutlined /> {{ auth.admin?.username || '管理員' }}
          </a>
          <template #overlay>
            <a-menu @click="onUserMenu">
              <a-menu-item key="logout">登出</a-menu-item>
            </a-menu>
          </template>
        </a-dropdown>
      </a-layout-header>
      <a-layout-content class="content">
        <router-view />
      </a-layout-content>
    </a-layout>
  </a-layout>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  DashboardOutlined, BookOutlined, AppstoreOutlined, StarOutlined,
  DollarOutlined, GiftOutlined, TeamOutlined, UserOutlined,
} from '@ant-design/icons-vue';
import { useAuthStore } from '../stores/auth';

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const collapsed = ref(false);

const selectedKey = computed(() => '/' + (route.path.split('/')[1] || 'dashboard'));
const pageTitle = computed(() => (route.meta.title as string) || '');

function onMenu(e: any) {
  router.push(e.key);
}
function onUserMenu(e: any) {
  if (e.key === 'logout') {
    auth.logout();
    router.replace('/login');
  }
}
</script>

<style scoped>
.brand {
  display: flex; align-items: center; gap: 8px;
  height: 56px; padding: 0 16px; font-weight: 700; color: #8B3A2E;
}
.brand-mark { font-size: 22px; }
.brand-text { letter-spacing: 1px; }
.header {
  background: #fff; padding: 0 24px;
  display: flex; align-items: center; justify-content: space-between;
  box-shadow: 0 1px 4px rgba(0,21,41,0.08);
}
.page-title { font-size: 16px; font-weight: 600; }
.user { color: #555; }
.content { padding: 16px 16px 0; }
</style>

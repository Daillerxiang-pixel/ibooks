<template>
  <div class="login-bg">
    <a-card class="login-card" :bordered="false">
      <div class="login-title">
        <span class="emoji">📚</span>
        <h2>iBooks 管理後台</h2>
        <p class="hint">默認帳號：admin / admin123</p>
      </div>
      <a-form layout="vertical" :model="form" @finish="onSubmit">
        <a-form-item label="帳號" name="username" :rules="[{ required: true, message: '請輸入帳號' }]">
          <a-input v-model:value="form.username" autocomplete="username" />
        </a-form-item>
        <a-form-item label="密碼" name="password" :rules="[{ required: true, message: '請輸入密碼' }]">
          <a-input-password v-model:value="form.password" autocomplete="current-password" />
        </a-form-item>
        <a-button type="primary" html-type="submit" block :loading="loading">登入</a-button>
      </a-form>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from '../stores/auth';

const router = useRouter();
const route = useRoute();
const auth = useAuthStore();
const loading = ref(false);
const form = reactive({ username: 'admin', password: 'admin123' });

async function onSubmit() {
  loading.value = true;
  try {
    await auth.login(form.username.trim(), form.password);
    const from = (route.query.from as string) || '/dashboard';
    router.replace(from);
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.login-bg {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #f4f1eb 0%, #e8d8c8 100%);
}
.login-card {
  width: 380px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.08);
  border-radius: 12px;
}
.login-title { text-align: center; margin-bottom: 16px; }
.login-title .emoji { font-size: 32px; }
.login-title h2 { margin: 4px 0 0; color: #8B3A2E; letter-spacing: 1px; }
.hint { color: #999; font-size: 12px; margin-top: 4px; }
</style>

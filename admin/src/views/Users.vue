<template>
  <a-card :bordered="false" :body-style="{ padding: '16px' }">
    <a-space style="margin-bottom: 12px">
      <a-input v-model:value="q" placeholder="搜尋手機號" style="width: 220px" allow-clear @press-enter="reload" />
      <a-button @click="reload">查詢</a-button>
    </a-space>
    <a-table
      :columns="columns"
      :data-source="rows"
      :loading="loading"
      row-key="id"
      size="middle"
      :pagination="{ current: page, pageSize: size, total, onChange: (p: number, s: number) => ((page = p), (size = s), reload()) }"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'balance'">
          <strong>{{ Number(record.balance).toFixed(0) }}</strong>
        </template>
        <template v-if="column.key === 'action'">
          <a-space>
            <a @click="onAdjust(record, 100)">+100</a>
            <a @click="onAdjust(record, -100)">-100</a>
            <a-popconfirm title="刪除用戶（不可恢復）？" @confirm="onRemove(record)">
              <a class="danger">刪除</a>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>
  </a-card>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { message } from 'ant-design-vue';
import { usersApi, type AdminUserRow } from '../api/admin';

const rows = ref<AdminUserRow[]>([]);
const total = ref(0);
const page = ref(1);
const size = ref(20);
const q = ref('');
const loading = ref(false);

const columns = [
  { title: 'ID', dataIndex: 'id', ellipsis: true, width: 220 },
  { title: '手機', dataIndex: 'phone' },
  { title: '暱稱', dataIndex: 'nickname' },
  { title: '餘額（書幣）', key: 'balance', width: 130 },
  { title: '註冊時間', dataIndex: 'created_at', width: 200 },
  { title: '操作', key: 'action', width: 200 },
];

async function reload() {
  loading.value = true;
  try {
    const r = await usersApi.list({ page: page.value, size: size.value, q: q.value });
    rows.value = r.items;
    total.value = r.total;
  } finally {
    loading.value = false;
  }
}
async function onAdjust(r: AdminUserRow, delta: number) {
  await usersApi.adjustBalance(r.id, delta);
  message.success('餘額已更新');
  await reload();
}
async function onRemove(r: AdminUserRow) {
  await usersApi.remove(r.id);
  await reload();
}

onMounted(reload);
</script>

<style scoped>.danger { color: #d4380d; }</style>

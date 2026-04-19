<template>
  <a-card :bordered="false" :body-style="{ padding: '16px' }">
    <a-space style="margin-bottom: 12px"><a-button type="primary" @click="onCreate">新增優惠券</a-button><a-button @click="reload">刷新</a-button></a-space>
    <a-table :columns="columns" :data-source="rows" :loading="loading" row-key="id" size="middle" :pagination="{ pageSize: 12 }">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'type'">
          <a-tag :color="record.type === 'amount' ? 'gold' : 'blue'">{{ record.type === 'amount' ? '抵扣' : '折扣%' }}</a-tag>
          <span> {{ record.value }}</span>
        </template>
        <template v-if="column.key === 'period'">
          <span>{{ fmt(record.valid_from) }} ~ {{ fmt(record.valid_to) || '不限' }}</span>
        </template>
        <template v-if="column.key === 'usage'">
          <span>{{ record.used_count }} / {{ record.max_uses || '∞' }}</span>
        </template>
        <template v-if="column.key === 'is_active'">
          <a-tag :color="record.is_active ? 'green' : 'default'">{{ record.is_active ? '啟用' : '停用' }}</a-tag>
        </template>
        <template v-if="column.key === 'action'">
          <a-space>
            <a @click="onEdit(record)">編輯</a>
            <a-popconfirm title="刪除優惠券？" @confirm="onRemove(record)"><a class="danger">刪除</a></a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>
    <a-modal v-model:open="showModal" :title="editing.id ? '編輯優惠券' : '新增優惠券'" :confirm-loading="saving" @ok="onSave" width="640px">
      <a-form layout="vertical" :model="editing">
        <a-row :gutter="12">
          <a-col :span="12"><a-form-item label="券碼"><a-input v-model:value="editing.code" /></a-form-item></a-col>
          <a-col :span="12"><a-form-item label="名稱"><a-input v-model:value="editing.name" /></a-form-item></a-col>
        </a-row>
        <a-row :gutter="12">
          <a-col :span="8"><a-form-item label="類型">
            <a-select v-model:value="editing.type" :options="[{ value: 'amount', label: '抵扣（書幣）' }, { value: 'percent', label: '折扣（%）' }]" />
          </a-form-item></a-col>
          <a-col :span="8"><a-form-item label="值"><a-input-number v-model:value="editing.value" :min="0" style="width:100%" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="最大使用次數"><a-input-number v-model:value="editing.max_uses" :min="0" style="width:100%" placeholder="0=不限" /></a-form-item></a-col>
        </a-row>
        <a-row :gutter="12">
          <a-col :span="12"><a-form-item label="開始時間"><a-date-picker v-model:value="from" show-time style="width:100%" /></a-form-item></a-col>
          <a-col :span="12"><a-form-item label="結束時間"><a-date-picker v-model:value="to" show-time style="width:100%" /></a-form-item></a-col>
        </a-row>
        <a-form-item label="啟用"><a-switch v-model:checked="activeBool" /></a-form-item>
      </a-form>
    </a-modal>
  </a-card>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import dayjs, { Dayjs } from 'dayjs';
import { message } from 'ant-design-vue';
import { couponsApi, type AdminCoupon } from '../api/admin';

const rows = ref<AdminCoupon[]>([]);
const loading = ref(false);
const showModal = ref(false);
const saving = ref(false);
const editing = ref<Partial<AdminCoupon>>({});
const from = ref<Dayjs | null>(null);
const to = ref<Dayjs | null>(null);

const activeBool = computed({
  get: () => !!editing.value.is_active,
  set: (v) => (editing.value.is_active = v ? 1 : 0),
});

const columns = [
  { title: 'ID', dataIndex: 'id', width: 60 },
  { title: '券碼', dataIndex: 'code' },
  { title: '名稱', dataIndex: 'name' },
  { title: '類型/值', key: 'type', width: 130 },
  { title: '使用 / 上限', key: 'usage', width: 130 },
  { title: '有效期', key: 'period', width: 230 },
  { title: '狀態', key: 'is_active', width: 80 },
  { title: '操作', key: 'action', width: 120 },
];

function fmt(s?: string | null) {
  if (!s) return '';
  return dayjs(s).format('YYYY-MM-DD HH:mm');
}
async function reload() {
  loading.value = true;
  try {
    rows.value = await couponsApi.list();
  } finally {
    loading.value = false;
  }
}
function onCreate() {
  editing.value = { type: 'amount', value: 10, is_active: 1 };
  from.value = null;
  to.value = null;
  showModal.value = true;
}
function onEdit(r: AdminCoupon) {
  editing.value = { ...r };
  from.value = r.valid_from ? dayjs(r.valid_from) : null;
  to.value = r.valid_to ? dayjs(r.valid_to) : null;
  showModal.value = true;
}
async function onSave() {
  saving.value = true;
  try {
    const payload: any = {
      ...editing.value,
      valid_from: from.value ? from.value.toISOString() : null,
      valid_to: to.value ? to.value.toISOString() : null,
    };
    if (editing.value.id) await couponsApi.update(editing.value.id, payload);
    else await couponsApi.create(payload);
    message.success('已保存');
    showModal.value = false;
    await reload();
  } finally {
    saving.value = false;
  }
}
async function onRemove(r: AdminCoupon) {
  await couponsApi.remove(r.id);
  await reload();
}
onMounted(reload);
</script>

<style scoped>.danger { color: #d4380d; }</style>

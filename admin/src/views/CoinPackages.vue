<template>
  <a-card :bordered="false" :body-style="{ padding: '16px' }">
    <a-space style="margin-bottom: 12px"><a-button type="primary" @click="onCreate">新增套餐</a-button><a-button @click="reload">刷新</a-button></a-space>
    <a-table :columns="columns" :data-source="rows" :loading="loading" row-key="id" size="middle" :pagination="false">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'price'">
          NT$ {{ (record.price_cents / 100).toFixed(2) }}
        </template>
        <template v-if="column.key === 'reward'">
          {{ record.coin_amount }}<span v-if="record.bonus_coin"> +{{ record.bonus_coin }} 贈送</span> 書幣
        </template>
        <template v-if="column.key === 'is_active'">
          <a-tag :color="record.is_active ? 'green' : 'default'">{{ record.is_active ? '上架' : '下架' }}</a-tag>
        </template>
        <template v-if="column.key === 'action'">
          <a-space>
            <a @click="onEdit(record)">編輯</a>
            <a-popconfirm title="刪除套餐？" @confirm="onRemove(record)"><a class="danger">刪除</a></a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>
    <a-modal v-model:open="showModal" :title="editing.id ? '編輯套餐' : '新增套餐'" :confirm-loading="saving" @ok="onSave">
      <a-form layout="vertical" :model="editing">
        <a-form-item label="名稱"><a-input v-model:value="editing.name" /></a-form-item>
        <a-row :gutter="12">
          <a-col :span="8"><a-form-item label="售價（分）"><a-input-number v-model:value="editing.price_cents" :min="0" style="width:100%" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="主面值"><a-input-number v-model:value="editing.coin_amount" :min="0" style="width:100%" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="贈送"><a-input-number v-model:value="editing.bonus_coin" :min="0" style="width:100%" /></a-form-item></a-col>
        </a-row>
        <a-row :gutter="12">
          <a-col :span="8"><a-form-item label="角標"><a-input v-model:value="editing.badge" placeholder="划算 / 多送" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="排序"><a-input-number v-model:value="editing.sort" :min="0" style="width:100%" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="上架"><a-switch v-model:checked="activeBool" /></a-form-item></a-col>
        </a-row>
      </a-form>
    </a-modal>
  </a-card>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { message } from 'ant-design-vue';
import { coinPackagesApi, type AdminCoinPackage } from '../api/admin';

const rows = ref<AdminCoinPackage[]>([]);
const loading = ref(false);
const showModal = ref(false);
const saving = ref(false);
const editing = ref<Partial<AdminCoinPackage>>({});

const activeBool = computed({
  get: () => !!editing.value.is_active,
  set: (v) => (editing.value.is_active = v ? 1 : 0),
});

const columns = [
  { title: 'ID', dataIndex: 'id', width: 60 },
  { title: '名稱', dataIndex: 'name' },
  { title: '售價', key: 'price', width: 130 },
  { title: '到帳', key: 'reward' },
  { title: '角標', dataIndex: 'badge', width: 100 },
  { title: '排序', dataIndex: 'sort', width: 70 },
  { title: '狀態', key: 'is_active', width: 80 },
  { title: '操作', key: 'action', width: 120 },
];

async function reload() {
  loading.value = true;
  try {
    rows.value = await coinPackagesApi.list();
  } finally {
    loading.value = false;
  }
}
function onCreate() {
  editing.value = { is_active: 1, sort: 0, bonus_coin: 0 };
  showModal.value = true;
}
function onEdit(r: AdminCoinPackage) {
  editing.value = { ...r };
  showModal.value = true;
}
async function onSave() {
  saving.value = true;
  try {
    if (editing.value.id) await coinPackagesApi.update(editing.value.id, editing.value);
    else await coinPackagesApi.create(editing.value);
    message.success('已保存');
    showModal.value = false;
    await reload();
  } finally {
    saving.value = false;
  }
}
async function onRemove(r: AdminCoinPackage) {
  await coinPackagesApi.remove(r.id);
  await reload();
}
onMounted(reload);
</script>

<style scoped>.danger { color: #d4380d; }</style>

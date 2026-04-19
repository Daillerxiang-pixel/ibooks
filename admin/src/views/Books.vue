<template>
  <div>
    <a-card :bordered="false" :body-style="{ padding: '16px' }">
      <a-space style="margin-bottom: 12px" wrap>
        <a-input v-model:value="q" placeholder="搜尋書名" allow-clear style="width: 200px" @press-enter="reload" />
        <a-select v-model:value="category" placeholder="分類" allow-clear style="width: 160px" @change="reload">
          <a-select-option v-for="c in categories" :key="c" :value="c">{{ c }}</a-select-option>
        </a-select>
        <a-button type="primary" @click="onCreate">新增書籍</a-button>
        <a-button @click="reload">刷新</a-button>
      </a-space>
      <a-table
        :columns="columns"
        :data-source="rows"
        :loading="loading"
        :pagination="{
          current: page,
          pageSize: size,
          total,
          showSizeChanger: true,
          onChange: (p: number, s: number) => ((page = p), (size = s), reload()),
        }"
        row-key="id"
        size="middle"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'cover'">
            <img v-if="resolveCover(record.cover_url)" :src="resolveCover(record.cover_url)!" style="width: 36px; height: 48px; object-fit: cover; border-radius: 4px" />
            <span v-else style="color: #ccc">無</span>
          </template>
          <template v-if="column.key === 'is_active'">
            <a-tag :color="record.is_active ? 'green' : 'default'">{{ record.is_active ? '上架' : '下架' }}</a-tag>
          </template>
          <template v-if="column.key === 'action'">
            <a-space>
              <a @click="onEdit(record)">編輯</a>
              <a @click="$router.push(`/books/${record.id}/chapters`)">章節</a>
              <a @click="onToggle(record)">{{ record.is_active ? '下架' : '上架' }}</a>
              <a-popconfirm title="刪除書籍及其章節？" @confirm="onRemove(record)">
                <a class="danger">刪除</a>
              </a-popconfirm>
            </a-space>
          </template>
        </template>
      </a-table>
    </a-card>

    <a-modal v-model:open="showModal" :title="editing?.id ? '編輯書籍' : '新增書籍'" @ok="onSave" :confirm-loading="saving" width="640px">
      <a-form layout="vertical" :model="editing">
        <a-row :gutter="12">
          <a-col :span="14"><a-form-item label="書名"><a-input v-model:value="editing.title" /></a-form-item></a-col>
          <a-col :span="10"><a-form-item label="作者"><a-input v-model:value="editing.author" /></a-form-item></a-col>
        </a-row>
        <a-row :gutter="12">
          <a-col :span="12"><a-form-item label="分類"><a-input v-model:value="editing.category" /></a-form-item></a-col>
          <a-col :span="12"><a-form-item label="狀態"><a-input v-model:value="editing.status" placeholder="連載 / 完結" /></a-form-item></a-col>
        </a-row>
        <a-form-item label="封面 URL（可填相對路徑 `/data/...` 或絕對 URL）">
          <a-input v-model:value="editing.cover_url" />
        </a-form-item>
        <a-form-item label="簡介">
          <a-textarea v-model:value="editing.description" :rows="4" />
        </a-form-item>
        <a-row :gutter="12">
          <a-col :span="8"><a-form-item label="字數"><a-input-number v-model:value="editing.word_count" :min="0" style="width: 100%" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="章節數"><a-input-number v-model:value="editing.chapter_count" :min="0" style="width: 100%" /></a-form-item></a-col>
          <a-col :span="8"><a-form-item label="上下架"><a-switch v-model:checked="activeBool" /></a-form-item></a-col>
        </a-row>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { message } from 'ant-design-vue';
import { booksApi, type AdminBook } from '../api/admin';

const rows = ref<AdminBook[]>([]);
const total = ref(0);
const page = ref(1);
const size = ref(20);
const q = ref('');
const category = ref<string>();
const loading = ref(false);
const showModal = ref(false);
const saving = ref(false);
const editing = ref<Partial<AdminBook>>({});
const categories = ref<string[]>([]);

const activeBool = computed({
  get: () => !!editing.value.is_active,
  set: (v) => (editing.value.is_active = v ? 1 : 0),
});

const columns = [
  { title: 'ID', dataIndex: 'id', width: 70 },
  { title: '封面', key: 'cover', width: 70 },
  { title: '書名', dataIndex: 'title', ellipsis: true },
  { title: '作者', dataIndex: 'author', width: 140 },
  { title: '分類', dataIndex: 'category', width: 100 },
  { title: '章節', dataIndex: 'chapter_count', width: 80 },
  { title: '狀態', key: 'is_active', width: 80 },
  { title: '操作', key: 'action', width: 220 },
];

function resolveCover(url?: string) {
  if (!url) return null;
  if (/^https?:\/\//.test(url)) return url;
  return url; // dev 反代 /data/... 也能訪問
}

async function reload() {
  loading.value = true;
  try {
    const r = await booksApi.list({ page: page.value, size: size.value, q: q.value, category: category.value });
    rows.value = r.items;
    total.value = r.total;
    const set = new Set<string>();
    for (const b of r.items) {
      if (b.category) set.add(b.category);
    }
    categories.value = [...new Set([...categories.value, ...set])];
  } finally {
    loading.value = false;
  }
}

function onCreate() {
  editing.value = { is_active: 1, status: '连载' };
  showModal.value = true;
}
function onEdit(record: AdminBook) {
  editing.value = { ...record };
  showModal.value = true;
}
async function onSave() {
  saving.value = true;
  try {
    if (editing.value.id) {
      await booksApi.update(editing.value.id, editing.value);
      message.success('已更新');
    } else {
      await booksApi.create(editing.value);
      message.success('已新增');
    }
    showModal.value = false;
    await reload();
  } finally {
    saving.value = false;
  }
}
async function onToggle(record: AdminBook) {
  await booksApi.toggle(record.id);
  await reload();
}
async function onRemove(record: AdminBook) {
  await booksApi.remove(record.id);
  message.success('已刪除');
  await reload();
}

onMounted(reload);
</script>

<style scoped>
.danger { color: #d4380d; }
</style>

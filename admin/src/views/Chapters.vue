<template>
  <div>
    <a-page-header :title="`章節管理：${bookTitle || '#' + bookId}`" :sub-title="`書籍 ID ${bookId}`" @back="$router.back()" />
    <a-card :bordered="false" :body-style="{ padding: '16px' }">
      <a-space style="margin-bottom: 12px" wrap>
        <a-button type="primary" @click="onCreate">新增章節</a-button>
        <a-divider type="vertical" />
        <a-input-number v-model:value="batchPrice" :min="0" placeholder="批量價格（書幣）" style="width: 160px" />
        <a-button :disabled="selectedIds.length === 0" @click="onBatchPrice(false)">為選中章節設置</a-button>
        <a-button @click="onBatchPrice(true)">為全部章節設置</a-button>
      </a-space>
      <a-table
        :columns="columns"
        :data-source="rows"
        :loading="loading"
        :pagination="false"
        :row-selection="{ selectedRowKeys: selectedIds, onChange: (k: number[]) => (selectedIds = k) }"
        row-key="id"
        size="middle"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'price'">
            <a-tag :color="record.price > 0 ? 'gold' : 'green'">
              {{ record.price > 0 ? `${record.price} 書幣` : '免費' }}
            </a-tag>
          </template>
          <template v-if="column.key === 'enc'">
            <a-tag v-if="record.content_is_encrypted" color="purple">加密</a-tag>
            <span v-else style="color: #999">—</span>
          </template>
          <template v-if="column.key === 'action'">
            <a-space>
              <a @click="onEdit(record)">編輯</a>
              <a-popconfirm title="刪除章節？" @confirm="onRemove(record)">
                <a class="danger">刪除</a>
              </a-popconfirm>
            </a-space>
          </template>
        </template>
      </a-table>
    </a-card>

    <a-modal v-model:open="showModal" :title="editing.id ? '編輯章節' : '新增章節'" :confirm-loading="saving" @ok="onSave" width="720px">
      <a-form layout="vertical" :model="editing">
        <a-row :gutter="12">
          <a-col :span="6"><a-form-item label="序號"><a-input-number v-model:value="editing.chapter_num" :min="0" style="width: 100%" /></a-form-item></a-col>
          <a-col :span="12"><a-form-item label="章節名"><a-input v-model:value="editing.title" /></a-form-item></a-col>
          <a-col :span="6"><a-form-item label="價格（書幣）"><a-input-number v-model:value="editing.price" :min="0" style="width: 100%" /></a-form-item></a-col>
        </a-row>
        <a-row :gutter="12">
          <a-col :span="12"><a-form-item label="字數"><a-input-number v-model:value="editing.word_count" :min="0" style="width: 100%" /></a-form-item></a-col>
          <a-col :span="12"><a-form-item label="加密章節"><a-switch v-model:checked="encBool" /></a-form-item></a-col>
        </a-row>
        <a-form-item label="OSS 正文 URL（JSON 數組字串，例如 [&quot;https://cdn/.../ch1.json&quot;]）">
          <a-textarea v-model:value="editing.content_oss_urls" :rows="2" placeholder='["https://..."]' />
        </a-form-item>
        <a-form-item v-if="editing.content_is_encrypted" label="解鎖密鑰（AES-256 base64）">
          <a-input v-model:value="editing.content_unlock_key_base64" />
        </a-form-item>
        <a-form-item label="庫內正文（兼容舊版；OSS 已配置時可留空）">
          <a-textarea v-model:value="editing.content" :rows="6" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { message } from 'ant-design-vue';
import { booksApi, chaptersApi, type AdminChapter } from '../api/admin';

const route = useRoute();
const bookId = Number(route.params.id);
const bookTitle = ref('');
const rows = ref<AdminChapter[]>([]);
const loading = ref(false);
const showModal = ref(false);
const saving = ref(false);
const editing = ref<Partial<AdminChapter>>({});
const selectedIds = ref<number[]>([]);
const batchPrice = ref<number | null>(null);

const encBool = computed({
  get: () => !!editing.value.content_is_encrypted,
  set: (v) => (editing.value.content_is_encrypted = v),
});

const columns = [
  { title: '#', dataIndex: 'chapter_num', width: 60 },
  { title: '標題', dataIndex: 'title', ellipsis: true },
  { title: '字數', dataIndex: 'word_count', width: 90 },
  { title: '價格', key: 'price', width: 110 },
  { title: '加密', key: 'enc', width: 70 },
  { title: '操作', key: 'action', width: 140 },
];

async function reload() {
  loading.value = true;
  try {
    rows.value = await chaptersApi.list(bookId);
  } finally {
    loading.value = false;
  }
}

function onCreate() {
  editing.value = { chapter_num: (rows.value.at(-1)?.chapter_num ?? 0) + 1, price: 0 };
  showModal.value = true;
}
function onEdit(r: AdminChapter) {
  editing.value = { ...r };
  showModal.value = true;
}
async function onSave() {
  saving.value = true;
  try {
    if (editing.value.id) {
      await chaptersApi.update(bookId, editing.value.id, editing.value);
    } else {
      await chaptersApi.create(bookId, editing.value);
    }
    message.success('已保存');
    showModal.value = false;
    await reload();
  } finally {
    saving.value = false;
  }
}
async function onRemove(r: AdminChapter) {
  await chaptersApi.remove(bookId, r.id);
  await reload();
}
async function onBatchPrice(setAll: boolean) {
  if (batchPrice.value == null) {
    message.warning('請先輸入價格');
    return;
  }
  await chaptersApi.batchPrice(bookId, {
    ids: selectedIds.value,
    price: batchPrice.value,
    setAll,
  });
  message.success('價格已更新');
  await reload();
}

onMounted(async () => {
  try {
    const b = await booksApi.detail(bookId);
    bookTitle.value = b.title;
  } catch (_) {}
  await reload();
});
</script>

<style scoped>
.danger { color: #d4380d; }
</style>

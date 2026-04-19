<template>
  <a-row :gutter="16">
    <a-col :span="9">
      <a-card title="推薦欄位" :bordered="false" :body-style="{ padding: 12 }">
        <template #extra><a-button size="small" type="primary" @click="onCreateSection">新增欄位</a-button></template>
        <a-list :data-source="sections" item-layout="horizontal">
          <template #renderItem="{ item }">
            <a-list-item :class="{ active: current?.id === item.id }" @click="select(item)">
              <a-list-item-meta>
                <template #title>{{ item.name }} <a-tag color="blue">{{ item.layout }}</a-tag></template>
                <template #description>排序 {{ item.sort }} · {{ item.is_active ? '啟用' : '停用' }}</template>
              </a-list-item-meta>
              <template #actions>
                <a @click.stop="onEditSection(item)">編輯</a>
                <a-popconfirm title="刪除整欄？" @confirm.stop="onRemoveSection(item)"><a class="danger">刪除</a></a-popconfirm>
              </template>
            </a-list-item>
          </template>
        </a-list>
      </a-card>
    </a-col>

    <a-col :span="15">
      <a-card :title="current ? `欄位內容：${current.name}` : '請先選擇欄位'" :bordered="false" :body-style="{ padding: 12 }">
        <template v-if="current" #extra>
          <a-input-number v-model:value="newBookId" :min="1" placeholder="書籍 ID" style="width: 120px; margin-right: 8px" />
          <a-input-number v-model:value="newBookSort" :min="0" placeholder="排序" style="width: 100px; margin-right: 8px" />
          <a-button type="primary" size="small" :disabled="!newBookId" @click="onAddItem">加入書籍</a-button>
        </template>
        <a-empty v-if="!current" />
        <a-table v-else :data-source="items" :columns="itemColumns" :pagination="false" row-key="id" size="middle">
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'action'">
              <a-popconfirm title="移除？" @confirm="onRemoveItem(record)"><a class="danger">移除</a></a-popconfirm>
            </template>
          </template>
        </a-table>
      </a-card>
    </a-col>
  </a-row>

  <a-modal v-model:open="showModal" :title="editing.id ? '編輯欄位' : '新增欄位'" :confirm-loading="saving" @ok="onSaveSection">
    <a-form layout="vertical" :model="editing">
      <a-form-item label="名稱"><a-input v-model:value="editing.name" /></a-form-item>
      <a-row :gutter="12">
        <a-col :span="12"><a-form-item label="佈局">
          <a-select v-model:value="editing.layout" :options="[{value:'banner',label:'橫幅'},{value:'row',label:'卡片橫排'},{value:'rank',label:'排行榜'}]" />
        </a-form-item></a-col>
        <a-col :span="6"><a-form-item label="排序"><a-input-number v-model:value="editing.sort" :min="0" style="width:100%" /></a-form-item></a-col>
        <a-col :span="6"><a-form-item label="啟用"><a-switch v-model:checked="activeBool" /></a-form-item></a-col>
      </a-row>
    </a-form>
  </a-modal>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { message } from 'ant-design-vue';
import { featuredApi, type AdminFeaturedItem, type AdminFeaturedSection } from '../api/admin';

const sections = ref<AdminFeaturedSection[]>([]);
const items = ref<AdminFeaturedItem[]>([]);
const current = ref<AdminFeaturedSection | null>(null);
const showModal = ref(false);
const saving = ref(false);
const editing = ref<Partial<AdminFeaturedSection>>({});
const newBookId = ref<number | null>(null);
const newBookSort = ref<number | null>(0);

const activeBool = computed({
  get: () => !!editing.value.is_active,
  set: (v) => (editing.value.is_active = v ? 1 : 0),
});

const itemColumns = [
  { title: 'ID', dataIndex: 'id', width: 70 },
  { title: '書籍 ID', dataIndex: 'book_id', width: 100 },
  { title: '排序', dataIndex: 'sort', width: 80 },
  { title: '操作', key: 'action', width: 100 },
];

async function reload() {
  sections.value = await featuredApi.listSections();
}
async function select(s: AdminFeaturedSection) {
  current.value = s;
  items.value = await featuredApi.listItems(s.id);
}
function onCreateSection() {
  editing.value = { layout: 'row', sort: 0, is_active: 1 };
  showModal.value = true;
}
function onEditSection(s: AdminFeaturedSection) {
  editing.value = { ...s };
  showModal.value = true;
}
async function onSaveSection() {
  saving.value = true;
  try {
    if (editing.value.id) await featuredApi.updateSection(editing.value.id, editing.value);
    else await featuredApi.createSection(editing.value);
    message.success('已保存');
    showModal.value = false;
    await reload();
  } finally {
    saving.value = false;
  }
}
async function onRemoveSection(s: AdminFeaturedSection) {
  await featuredApi.removeSection(s.id);
  if (current.value?.id === s.id) current.value = null;
  await reload();
}
async function onAddItem() {
  if (!current.value || !newBookId.value) return;
  await featuredApi.addItem(current.value.id, { book_id: newBookId.value, sort: newBookSort.value ?? 0 });
  newBookId.value = null;
  newBookSort.value = 0;
  await select(current.value);
}
async function onRemoveItem(it: AdminFeaturedItem) {
  await featuredApi.removeItem(it.id);
  if (current.value) await select(current.value);
}

onMounted(reload);
</script>

<style scoped>
.active { background: #fff7f5; }
.danger { color: #d4380d; }
</style>

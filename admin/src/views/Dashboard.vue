<template>
  <div>
    <a-row :gutter="16">
      <a-col :span="4" v-for="card in cards" :key="card.key">
        <a-card :bordered="false">
          <a-statistic :title="card.title" :value="card.value" :precision="card.precision || 0" />
        </a-card>
      </a-col>
    </a-row>

    <a-row :gutter="16" style="margin-top: 16px">
      <a-col :span="12">
        <a-card title="近 7 日新增用戶" :bordered="false">
          <div ref="userChartRef" style="height: 260px"></div>
        </a-card>
      </a-col>
      <a-col :span="12">
        <a-card title="近 7 日訂單金額" :bordered="false">
          <div ref="revenueChartRef" style="height: 260px"></div>
        </a-card>
      </a-col>
    </a-row>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import * as echarts from 'echarts';
import { dashboardApi } from '../api/admin';

const summary = ref<any>({});
const userPoints = ref<any[]>([]);
const revenuePoints = ref<any[]>([]);
const userChartRef = ref<HTMLElement>();
const revenueChartRef = ref<HTMLElement>();

const cards = computed(() => [
  { key: 'b', title: '書籍', value: summary.value.bookCount ?? 0 },
  { key: 'c', title: '章節', value: summary.value.chapterCount ?? 0 },
  { key: 'u', title: '用戶', value: summary.value.userCount ?? 0 },
  { key: 's', title: '書架收藏', value: summary.value.shelfCount ?? 0 },
  { key: 'o', title: '已支付訂單', value: summary.value.paidOrders ?? 0 },
  { key: 'r', title: '累計收入（元）', value: Number(summary.value.revenueYuan ?? 0), precision: 2 },
]);

onMounted(async () => {
  summary.value = await dashboardApi.summary();
  userPoints.value = await dashboardApi.userTrend();
  revenuePoints.value = await dashboardApi.revenueTrend();

  const uc = echarts.init(userChartRef.value!);
  uc.setOption({
    grid: { left: 36, right: 16, top: 24, bottom: 28 },
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: userPoints.value.map((p) => p.date) },
    yAxis: { type: 'value' },
    series: [{ data: userPoints.value.map((p) => p.count), type: 'bar', color: '#8B3A2E', barMaxWidth: 28 }],
  });

  const rc = echarts.init(revenueChartRef.value!);
  rc.setOption({
    grid: { left: 44, right: 16, top: 24, bottom: 28 },
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: revenuePoints.value.map((p) => p.date) },
    yAxis: { type: 'value' },
    series: [
      {
        data: revenuePoints.value.map((p) => p.amount),
        type: 'line',
        smooth: true,
        areaStyle: { opacity: 0.18 },
        color: '#8B3A2E',
      },
    ],
  });
});
</script>

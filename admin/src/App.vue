<template>
  <a-config-provider :theme="theme">
    <router-view />
  </a-config-provider>
</template>

<script setup lang="ts">
import { theme as antdTheme } from 'ant-design-vue';
const theme = {
  token: {
    colorPrimary: '#8B3A2E',
    colorLink: '#8B3A2E',
    colorBgLayout: '#F4F1EB',
    borderRadius: 6,
  },
  algorithm: antdTheme.defaultAlgorithm,
};
</script>

<style>
html, body, #app { height: 100%; margin: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, "PingFang TC", "Helvetica Neue", Arial, sans-serif; }
</style>

/// <reference types="vite/client" />

declare module '*.vue' {
  import type { DefineComponent } from 'vue';
  const component: DefineComponent<{}, {}, any>;
  export default component;
}

// 防止某些版本下 ant-design-vue 的 message 子模塊類型解析失敗
declare module 'ant-design-vue';

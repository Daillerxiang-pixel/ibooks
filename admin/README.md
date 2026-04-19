# iBooks 管理後台 (admin)

参考 [vue-vben-admin](https://github.com/vbenjs/vue-vben-admin) / [ant-design-pro](https://github.com/ant-design/ant-design-pro) 的目录结构与交互习惯，做了一个轻量 MVP：

| 模块 | 路径 |
|------|------|
| 仪表盘 | `/dashboard`：书籍/章节/用户/书架/订单/收入 + 7 日趋势图 |
| 书籍管理 | `/books`：列表 / 新增 / 编辑 / 上下架 / 删除 |
| 章节管理 | `/books/:id/chapters`：单章 CRUD / 单章定价 / **批量定价** / OSS 加密配置 |
| 分类管理 | `/categories` |
| 书城推荐 | `/featured`：栏位 + 栏位内书籍 |
| 充值套餐 | `/coin-packages` |
| 优惠券 | `/coupons`：抵扣 / 折扣两种类型，有效期、用量、上下架 |
| 用户管理 | `/users`：搜索、调整余额（±100 快捷键）、删除 |

## 技术栈
- **Vue 3 + TypeScript + Vite**
- **Ant Design Vue 4**（中文管理后台首选）
- **Pinia**（认证状态）
- **Vue Router 4**
- **Axios**（统一拦截：携带 Bearer，401 自动登出）
- **ECharts 5**（仪表盘图表）

## 本地开发

```bash
cd ibooks/server && npm run start:dev   # 后端：默认 http://127.0.0.1:8081
cd ibooks/admin  && npm install && npm run dev
# 浏览器打开 http://localhost:5180
```

默认管理员（首次启动后端时种子）：`admin / admin123`

## 后端接口前缀
所有接口在 `/api/admin/*`：`/api/admin/auth/login` 公开；其它都需 `Authorization: Bearer <admin-jwt>`。

## 部署
```bash
cd ibooks/admin
npm run build
# 产物：admin/dist —— 用 Nginx 静态托管即可，前端通过 `/api` 反代到 NestJS 后端。
```

参考 Nginx：

```nginx
server {
  server_name admin.book.kanashortplay.com;
  root /var/www/ibooks/admin/dist;
  location / { try_files $uri $uri/ /index.html; }
  location /api/ {
    proxy_pass http://127.0.0.1:8081;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

## 后续可扩展
- 数据统计：转化漏斗 / 留存 / 章节阅读分布（已有 dashboard 趋势接口可复用）
- 操作审计 (audit log)
- RBAC：admin role 已在 token 内（`super` / `operator`），仅需在前后端按权限筛选菜单
- 富文本编辑章节正文 / OSS 文件上传 (PUT presigned URL)
- 多语言（i18n）

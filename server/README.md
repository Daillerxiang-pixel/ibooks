# iBooks 后端 API 文档

**生产环境部署（服务器路径、PM2、Nginx、Git 等）见仓库根目录 [docs/DEPLOY.md](../docs/DEPLOY.md)。**

## 项目信息
- **技术栈**: Node.js + NestJS + TypeORM + SQLite
- **端口**: 8081
- **API 前缀**: `/api`

## API 端点

### 认证 API (`/api/auth`)

| 方法 | 路径 | 说明 | 参数 |
|------|------|------|------|
| POST | /register | 注册 | `{phone, password, nickname?}` |
| POST | /login | 登录 | `{phone, password}` |
| POST | /sms | 发送验证码 | `{phone}` |

### 书籍 API (`/api/books`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | / | 书籍列表 | 否 |
| GET | /:id | 书籍详情 | 否 |
| GET | /:id/chapters | 章节列表 | 否 |

### 章节 API (`/api/chapters`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | /:id | 章节内容（见下「交付模式」） | 可选 |
| POST | /:id/read | 记录进度 | 是 |

#### 章节正文交付模式（与 Flutter `docs/BACKEND_CHAPTER_CONTENT.md` 一致）

- **OSS 模式**（`chapters` 表配置了 `content_oss_urls` JSON 数组）  
  - 库内**不再**返回完整正文，返回 `ossUrls`；客户端自行下载 JSON。  
  - **免费章**：返回 `ossUrls`，`isEncrypted`；明文 OSS 时 `contentKeyBase64` 为 `null`。  
  - **付费章**：未购买仅返回 `preview`（可用库内 `content` 试读片段）；**已购买**返回 `ossUrls` + `isEncrypted` +（若加密）`contentKeyBase64`。  
- **inline 模式**（未配置 OSS 时兼容旧数据）：仍返回 `data.content` 正文字符串。

成功响应 `data` 字段示例（OSS + 已购付费加密章）：

```json
{
  "deliveryMode": "oss",
  "id": 1,
  "title": "第6章 …",
  "ossUrls": ["https://cdn.example.com/.../chapter-6.json"],
  "isEncrypted": true,
  "contentKeyBase64": "<仅已购且加密时返回>"
}
```

### 订单 API (`/api/orders`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | /create | 创建订单 | 是 |
| POST | /notify | 支付回调 | 否 |

### 书架 API (`/api/shelf`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | / | 我的书架 | 是 |
| POST | /:bookId | 添加收藏 | 是 |
| DELETE | /:bookId | 取消收藏 | 是 |

### 用户 API (`/api/user`)

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | / | 用户信息 | 是 |

## 启动方式

```bash
cd server
npm install
npm run seed  # 初始化测试数据
npm start     # 启动服务
```

## 数据库表

| 表名 | 说明 |
|------|------|
| users | 用户 |
| books | 书籍 |
| chapters | 章节（含 `content_oss_urls`、`content_is_encrypted`、`content_unlock_key_base64`；`content` 可为空） |
| orders | 订单 |
| user_purchases | 已购章节 |
| user_shelf | 用户书架 |
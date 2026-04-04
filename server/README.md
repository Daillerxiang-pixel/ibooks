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
| GET | /:id | 章节内容 | 可选 |
| POST | /:id/read | 记录进度 | 是 |

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
| chapters | 章节 |
| orders | 订单 |
| user_purchases | 已购章节 |
| user_shelf | 用户书架 |
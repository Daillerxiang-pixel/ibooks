# 书籍内容入库与 OSS / 密钥规则

本文约定 **测试服** 与 **内容入库** 流程，与后端实现（`server/src/entities/chapter.entity.ts`、`server/src/modules/chapters/chapters.service.ts`）及客户端 `novel_reader/docs/BACKEND_CHAPTER_CONTENT.md` 一致。

---

## 1. 测试服接口地址（当前）

| 项 | 值 |
|----|-----|
| 域名 | `book.kanashortplay.com` |
| **API 根路径** | **`https://book.kanashortplay.com/api`**（全局前缀 `/api`，与仓库 `server` 一致） |
| 说明 | 客户端、脚本请求时 **Base URL** 填 `https://book.kanashortplay.com`，路径以 `/api/...` 开头。 |

示例：

- 书籍列表：`GET https://book.kanashortplay.com/api/books`
- 章节内容：`GET https://book.kanashortplay.com/api/chapters/:id`（需携带登录态时按现有鉴权规则）

### 域名解析（自检）

解析是否生效请以运维侧 DNS 控制台为准；本机可用 `nslookup book.kanashortplay.com` 或 `ping` 自查。  
文档编写时曾解析到 **39.102.100.123**（仅作参考，**以实际解析结果为准**）。

HTTPS 证书、Nginx 反代到本机 **8081** 等由运维配置，不在本文展开。

---

## 2. 总原则

| 存储位置 | 存放内容 |
|----------|----------|
| **数据库** | 书/章元数据、`content_oss_urls`（OSS 地址列表 JSON 字符串）、`content_is_encrypted`、密钥字段（见下）、订单与已购关系；**正文不长期以整书形式堆在 `content` 里**（新数据一律走 OSS）。 |
| **OSS** | 章节正文 JSON：**免费**为明文 JSON；**付费**为加密包 JSON（与 `BACKEND_CHAPTER_CONTENT.md` 外壳格式一致）。 |

入库顺序建议：**先上传 OSS 成功 → 再更新数据库**，避免库里有 URL 但对象不存在。

---

## 3. 数据库字段（`chapters` 表）

| 字段 | 含义 |
|------|------|
| `title` | 章标题 |
| `price` | 价格；`0` 表示免费章 |
| `content` | **可选**；旧版整段正文；新数据可为 `NULL`，或仅保留**付费试读摘要**供锁章提示 |
| `content_oss_urls` | **JSON 字符串数组**，如 `["https://.../ch1.json"]`；多个 URL 时按产品约定顺序使用 |
| `content_is_encrypted` | `true` 表示 OSS 上为加密包，客户端需用密钥解密 |
| `content_unlock_key_base64` | AES-256 密钥的 Base64（**测试/演示**可直存；**生产**建议改为 KMS 封装或密钥 ID，购后再由服务解密下发） |

---

## 4. 免费章（明文 OSS）

1. 生成明文章节 JSON（字段与客户端 `ChapterBody` / 文档约定一致：`title`、`paragraphs` 等）。  
2. 上传到 OSS，得到可访问 URL（或私有桶 + 签名 URL，由网关/后端统一生成）。  
3. 更新该章记录：  
   - `content_oss_urls = ["<url>"]`  
   - `content_is_encrypted = false`  
   - `content_unlock_key_base64 = null`  
   - `content = null`（推荐）  

---

## 5. 付费章（加密 OSS + 密钥）

1. 生成随机 **DEK**（32 字节，AES-256）。  
2. 将「明文章节 JSON」加密为约定外壳（`format`、`algorithm`、`ivBase64`、`cipherTextBase64`）。  
3. 将加密文件上传 OSS。  
4. 更新该章记录：  
   - `content_oss_urls = ["<加密文件 url>"]`  
   - `content_is_encrypted = true`  
   - `content_unlock_key_base64 = <DEK 的 Base64>`（或按生产策略仅存 KMS 密文/密钥引用）  
   - `content` 可存短**试读**文案，供未购买用户展示 `preview`  

用户 **支付成功** 写入 `user_purchases` 后，接口在已购场景返回 `ossUrls` + `contentKeyBase64`（与当前 Nest 实现一致）。

---

## 6. 与接口的对应关系

- 章列表：`GET /api/books/:id/chapters` — 返回含 `delivery_mode`（`oss` / `inline`）、`is_encrypted` 等，**不**下发密钥。  
- 单章阅读：`GET /api/chapters/:id` — OSS 模式下返回 `deliveryMode`、`ossUrls`、`isEncrypted`、（已购且加密时）`contentKeyBase64`。  

详见 **`server/README.md`** 中「章节正文交付模式」一节。

---

## 7. 变更记录

| 日期 | 说明 |
|------|------|
| 2026-04-17 | 初稿：测试域名 `book.kanashortplay.com`、API `.../api`、入库与 OSS/密钥规则 |

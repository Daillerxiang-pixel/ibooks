# 章節內容：OSS + 加密（後端與客戶端約定）

## 原則

- **資料庫不存放章節正文**，只存元數據與資源引用。
- 每章正文以 **JSON 文件** 存放在 **OSS**（可 CDN）；一個章節可對應 **多個 URL**（例如分片、多語、或灰度），由列表順序或 `role` 字段區分（產品自定）。
- **付費章節**：OSS 上的 JSON 為 **密文**；資料庫保存 **解鎖密鑰**（或密鑰 ID + 由權限服務下發實際密鑰）。
- 用戶 **購買成功** 後，後端在 **權限／訂單結果** 中返回該章（或該書）的 **內容密鑰**；客戶端 **下載 OSS JSON → 用密鑰解密 → 解析正文**。

## 資料庫（章節表建議字段）

| 字段 | 說明 |
|------|------|
| `id` | 章節 ID |
| `book_id` | 書籍 ID |
| `chapter_index` / `sort_order` | 排序 |
| `title` | 章節名稱（列表展示） |
| `is_free` | 是否免費試讀 |
| `content_oss_urls` | JSON 數組字符串，例如 `["https://cdn.../chap001.json"]` |
| `content_key_enc` | 可選：密鑰以 KMS 加密存儲；或只存 `key_id` |
| `cipher_meta` | 可選：算法版本、IV 是否外置等（若全部在 OSS 文件內則可空） |

付費章節：`content_oss_urls` 指向 **加密包**；免費章節可指向 **明文 JSON**（或同樣結構但不加密）。

## OSS 上的 JSON 格式（加密章節）

與客戶端 `OssEncryptedChapterBundle` 對齊，建議：

```json
{
  "format": "ibooks-chapter-encrypted-v1",
  "algorithm": "AES-256-CBC-PKCS7",
  "ivBase64": "<IV base64>",
  "cipherTextBase64": "<密文 base64>"
}
```

解密後得到 **UTF-8 字符串**，再解析為 **明文章節 JSON**（見下節）。

## 明文章節 JSON（解密後）

```json
{
  "version": 1,
  "title": "第 1 章 起風了",
  "paragraphs": ["段落一……", "段落二……"]
}
```

後端生成加密前應與客戶端 `ChapterBody.fromJson` 字段一致。

## 購買成功後 API（示例）

響應中針對已購章節附加（字段名可統一為業務標準）：

```json
{
  "chapterId": "ch_001",
  "contentKeyBase64": "<AES-256 密鑰 32 bytes 的 base64>",
  "expiresAt": null
}
```

或返回 **臨時下載憑證 + 密鑰**：由後端統一設計；客戶端只負責：**拿到 key → 拉 OSS → 解密**。

## 安全注意

- 密鑰僅在 **HTTPS** 與 **登錄會話** 下下發；避免寫入日誌。
- OSS 文件建議 **私有桶 + 簽名 URL**；密鑰與 URL 分開獲取。
- 算法升級時通過 `format` / `algorithm` 版本號演進。

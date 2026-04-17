# novel_reader（Flutter）

繁體網文閱讀客戶端：**UI 嚴格對齊** `../design/ibooks-trad-ui-prototype.html`（書架 / 書城 / 分類 / 我的、搜尋、分類列表、詳情、目錄、閱讀器、會員與書幣相關子頁）。主題色、底部 Tab、頂欄與子頁堆疊與交互稿一致。

章節正文技術約定見 **`docs/BACKEND_CHAPTER_CONTENT.md`**（OSS JSON + 付費加密）；實作位於 `lib/src/data/`。

## 本地環境

1. 安裝 [Flutter](https://docs.flutter.dev/get-started/install)（含 `dart`）。
2. 在本目錄執行（若尚無 `android/`、`ios/` 等）：

```bash
cd novel_reader
flutter create . --project-name novel_reader
flutter pub get
flutter run
```

`flutter create .` 會補齊平台工程且不覆蓋現有 `lib/`。

## 後端 API（已接入）

- **預設 API 根**：`https://book.kanashortplay.com/api`（與 Nest 全局前綴 `/api` 一致）。
- **覆寫**：`flutter run --dart-define=API_BASE=https://你的域名/api`
- **已對接**：`GET /books`、`GET /books/:id`、`GET /books/:id/chapters`、`GET /chapters/:id`（需 **Bearer JWT**）、`POST /auth/login`、`POST /auth/register`。
- Token 存於本機 `SharedPreferences`；閱讀章節前若未登入會引導 `/login`。

### 編譯測試 APK

```bash
cd novel_reader
flutter pub get
flutter build apk --release
# 產物：build/app/outputs/flutter-apk/app-release.apk
```

如需指定測試服：

```bash
flutter build apk --release --dart-define=API_BASE=https://book.kanashortplay.com/api
```

## 目錄說明

| 路徑 | 說明 |
|------|------|
| `lib/router/app_router.dart` | `go_router` 路由（含詳情、目錄、閱讀器、我的子頁） |
| `lib/shell/main_shell.dart` | 主殼：頂欄 + IndexedStack + 底部四 Tab（max 420px） |
| `lib/theme/` | 交互稿色板與 `google_fonts` Noto Sans TC |
| `lib/screens/tabs/` | 書架 / 書城 / 分類 / 我的 |
| `lib/screens/` | 搜尋、分類列表、詳情、目錄、閱讀器、會員/書幣等 |
| `docs/BACKEND_CHAPTER_CONTENT.md` | 後端 OSS / 密鑰約定 |
| `lib/src/data/` | 章節解密與 HTTP 倉庫（接 API 時使用） |

## 後端要點（摘要）

- 庫表存：**章節名**、`content_oss_urls`、**解鎖密鑰**；正文在 OSS。
- 購買成功下發 **contentKeyBase64**；客戶端下載 JSON 後解密（見 `chapter_decryptor.dart`）。

## 測試

```bash
flutter test
```

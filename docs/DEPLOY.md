# iBooks 服务器部署说明

> 本文档由 `workspace-devops` 中与 iBooks 相关的脚本整理而来，便于项目内长期保存；部署以 **NestJS 编译产物 `dist/main.js`** 为准。

**当前阶段**：iBooks 仍处于 **测试阶段**，**尚未**建立独立「正式环境」与测试/生产的拆分说明；下文为当前在用的一套部署约定，若后续上正式环境再单独补充文档与流程。

---

## 1. 服务器目录与进程

| 项 | 值 |
|----|-----|
| 应用根目录 | `/var/www/ibooks` |
| 后端目录 | `/var/www/ibooks/server` |
| 前端目录（若部署 H5） | `/var/www/ibooks/app` |
| PM2 进程名 | `ibooks-server` |
| 监听端口 | **8081**（与 `server/src/main.ts`、`app/vite` 开发代理一致） |
| 全局 API 前缀 | `/api` |

---

## 2. 数据库与日志

| 项 | 值 |
|----|-----|
| SQLite 文件 | `server/data/ibooks.db`（相对仓库：`server/data/ibooks.db`；运行时 cwd 为 `server` 目录则落在 **`/var/www/ibooks/server/data/ibooks.db`**） |
| PM2 错误日志 | `/var/log/ibooks/error.log` |
| PM2 标准输出 | `/var/log/ibooks/out.log` |

部署前在服务器执行：`mkdir -p /var/log/ibooks`（若尚未创建）。

---

## 3. 环境变量（生产示例）

以下为 devops 脚本中曾使用的示例，**生产环境请改为强随机 `JWT_SECRET` 并妥善保管**：

```env
PORT=8081
NODE_ENV=production
JWT_SECRET=ibooks-jwt-secret-2026
# APPLE_SHARED_SECRET=...（若接苹果内购再填）
```

`.env` 可放在 **`/var/www/ibooks/server`**（与 `dotenv` / 进程 cwd 一致），以实际代码加载路径为准。

---

## 4. 推荐部署流程（与 `workspace-devops/scripts/deploy-ibooks.sh` 一致）

在服务器 **`/var/www/ibooks`** 为 Git 克隆目录的前提下：

1. **拉代码**（分支以实际为准，脚本示例为 `master`）  
   `cd /var/www/ibooks && git fetch origin && git reset --hard origin/master && git clean -fd`

2. **安装依赖并编译后端**  
   ```bash
   cd /var/www/ibooks/server
   npm install
   npm run build
   ```

3. **重启 PM2（使用编译后的入口）**  
   ```bash
   pm2 delete ibooks-server 2>/dev/null || true
   cd /var/www/ibooks/server
   NODE_ENV=production pm2 start dist/main.js --name ibooks-server
   pm2 save
   ```

4. **健康检查**  
   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8081/api/books
   ```  
   期望为 **200**（需已有书籍数据或接口允许空列表仍返回 200）。

5. **前端静态资源（可选）**  
   若存在 `app/`：  
   ```bash
   cd /var/www/ibooks/app
   npm install
   npm run build
   ```  
   产物在 `app/dist/`，由 Nginx 等指向该目录。

---

## 5. PM2 生态系统文件（可选）

devops 中 `gen-eco.mjs` 生成的配置要点：

- `script`: **`dist/main.js`**
- `cwd`: **`/var/www/ibooks/server`**
- `env.PORT`: **8081**
- 日志：`/var/log/ibooks/error.log`、`/var/log/ibooks/out.log`

使用方式：`pm2 start ecosystem.config.js`（文件需放在合适路径，且 `cwd` 与 `script` 与上表一致）。

**注意**：`workspace-devops/deploy-ibooks.sh`（根目录）旧版曾写 `script: 'src/main.js'`、`cwd: '/var/www/ibooks'`，与当前 **TypeScript 编译到 `dist/`** 的 Nest 项目不一致；**以本节与 `scripts/deploy-ibooks.sh` 为准**。

---

## 6. Git 远程（内网 Gitea 示例）

`ibooks_check.sh` 中使用的克隆地址示例：

```text
https://test.kanashortplay.com:8443/aihuantu/ibooks.git
```

实际以你服务器/内网 Gitea 上的仓库 URL 为准。

---

## 7. 与本地开发的对应关系

| 环境 | 前端 | 后端 |
|------|------|------|
| 本地 | `app`: `npm run dev` → 常为 **3000**，Vite 将 `/api` 代理到 **8081** | `server`: `npm run dev` → **8081** |
| 生产 | `app` 构建后由 Web 服务器静态托管 | PM2 运行 **`dist/main.js`**，端口 **8081**，Nginx 反代 `/api` |

---

## 8. 来源文件索引（workspace-devops）

便于日后回溯（路径相对于 `workspace-devops` 仓库）：

- `deploy-ibooks.sh` — 根目录 PM2 + `.env` 示例（需与 `dist/main.js` 对齐）
- `scripts/deploy-ibooks.sh` — **推荐**：`git pull` + `npm run build` + `pm2 start dist/main.js` + 前端 `npm run build`
- `gen-eco.mjs` — PM2 ecosystem 片段（base64 生成用）
- `ibooks_check.sh` — 克隆仓库结构检查、Git 地址示例
- `gen-fix*.mjs`、`gen-fix64.*` 等 — 线上问题修复时的临时脚本（实体/编译相关），非标准部署流程

---

## 9. 与 ai-face-swap 测试环境同机（39.102.100.123）

同一台公网服务器 **`39.102.100.123`** 上可能同时运行：

| 服务 | 目录 | PM2 进程名 | 本机端口 | 对外域名（示例） |
|------|------|------------|----------|------------------|
| **iBooks**（本节） | `/var/www/ibooks` | `ibooks-server` | **8081** | 以实际 Nginx `server_name` 为准 |
| **AI 换图测试** | `/var/www/ai-face-swap-test` | `ai-face-swap-test` | **8082** | `test1.kanashortplay.com` |

**运维注意**：

- 更新 **iBooks** 时，不要停止或修改 **`ai-face-swap-test`** 的 PM2 配置；反之亦然。
- **不要**将 ai-face-swap 测试实例监听在 **8081**，以免与 iBooks 冲突。
- Nginx 为各域名使用独立 `server` / 站点文件；新增站点时不应删除或覆盖其他项目的 `sites-enabled` 配置。

ai-face-swap 测试环境权威说明见同工作区仓库 **`ai-face-swap`** 内文档：`docs/SERVER-DEPLOY.md`（§3 测试服务器）。

---

**文档更新说明**：若部署目录、分支名、域名或 Nginx 配置变更，请同步修改本节，并保留变更日期。

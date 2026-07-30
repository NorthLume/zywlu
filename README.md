# ZYWLU

ZYWLU 是一个面向正式发布的主页项目。项目采用静态优先架构，在保持高性能、良好 SEO
和无障碍体验的同时，为后续交互功能保留渐进扩展空间。

## 当前状态

项目处于工程初始化阶段。基础规范、代码质量工具、最小页面骨架和生产构建流程已经建立；
视觉设计、正式文案、域名与业务功能将在后续迭代中确定。

## 技术栈

- Astro：静态站点构建与按需交互岛。
- TypeScript：严格模式。
- 原生 CSS：设计令牌、响应式布局和渐进增强。
- Vitest：单元测试。
- ESLint 与 Prettier：静态检查和格式统一。
- Nginx：生产环境静态资源与 HTTPS 入口。
- npm：唯一包管理器。

技术选择的背景与边界参见
[`docs/decisions/0001-static-first-astro.md`](docs/decisions/0001-static-first-astro.md)。

## 环境要求

- Node.js `22.12.0` 或更高的受支持偶数版本。
- npm `10` 或更高版本。

推荐使用 `.nvmrc` 切换项目 Node.js 版本。

## 快速开始

```bash
npm ci
npm run dev
```

开发服务器默认监听 `http://localhost:4321`。

## 项目命令

| 命令                   | 用途                           |
| ---------------------- | ------------------------------ |
| `npm run dev`          | 启动本地开发服务器             |
| `npm run format`       | 格式化受支持的项目文件         |
| `npm run format:check` | 检查格式                       |
| `npm run lint`         | 执行 ESLint                    |
| `npm run typecheck`    | 执行 Astro 与 TypeScript 检查  |
| `npm run test`         | 运行单元测试                   |
| `npm run build`        | 生成生产静态产物到 `dist/`     |
| `npm run preview`      | 本地预览生产构建               |
| `npm run check`        | 依次执行全部质量门槛与生产构建 |

## 目录结构

```text
src/
├─ config/              站点级配置
├─ layouts/             页面布局
├─ pages/               文件路由页面
└─ styles/              全局样式与设计令牌
tests/                  单元与集成测试
docs/decisions/         架构决策记录
infra/                  后续加入的生产配置模板
public/                 后续加入的直接发布资源
```

目录按真实需求扩展，避免仅为占位建立空目录。

## 开发流程

1. 阅读根目录 `AGENTS.md` 和相关 ADR。
2. 从最新 `main` 创建聚焦单一目的的分支。
3. 完成最小完整变更，并补充对应测试。
4. 执行 `npm run check`。
5. 审阅完整 diff 后提交。

## 构建与部署

`npm run build` 生成 `dist/`。生产环境由 Ubuntu 24.04 LTS 上的 Nginx 托管该目录。
部署脚本和 Nginx 模板将在 `infra/` 中版本化，并遵循以下流程：

1. 从已验证提交构建产物。
2. 上传到新的版本目录。
3. 切换当前版本链接。
4. 执行 HTTP 健康检查。
5. 保留上一健康版本用于快速回退。

服务器地址、账号、域名和凭据通过部署环境注入，不进入仓库。

## 文档

- [`AGENTS.md`](AGENTS.md)：项目长期工程约定与完成定义。
- [`docs/decisions/`](docs/decisions/)：关键技术决策及其背景。

# JUJU Schedule 官网

纯静态产品网站：介绍 JUJU、展示功能、提供 Android APK 下载、展示更新日志。

没有后端、没有账号、没有数据库。当前部署在腾讯云 CloudBase 静态网站托管。

网站放在 App 仓库的 `/website` 目录，**不会修改 Flutter App 代码**。

## 文件结构

```
website/
├── index.html              首页
├── changelog.html          更新日志
├── faq.html                常见问题
├── feedback.html           用户反馈
├── privacy.html            隐私政策
├── 404.html
├── deploy.ps1              CloudBase 增量发版脚本
├── css/style.css
├── js/
│   ├── config.js           ★ 发新版主要改这里
│   ├── i18n.js             中英文文案
│   └── main.js
├── downloads/              APK 本地副本（*.apk 已被 git 忽略）
├── assets/
│   ├── logo.png
│   └── og-image.png
├── robots.txt
├── sitemap.xml
├── _headers                Cloudflare Pages 缓存头
└── .nojekyll               GitHub Pages 需要
```

页面结构（首页）：

1. Hero：名称、介绍、下载 / 了解 JUJU、概念界面
2. 功能卡片：日程 & Todo、Timeline、Reminder、Focus、Statistics、本地数据
3. 数据说明：你的数据，由你自己掌握
4. App 展示：4 个概念设计图
5. 下载：Android APK + iOS Coming Soon
6. 最近更新
7. FAQ
8. Footer

## 本地如何运行

官网是普通 HTML，**不需要构建**。

任选一种：

```bash
cd website
python -m http.server 4173
```

或用 VS Code / Cursor 的 Live Preview、或直接用浏览器打开 `website/index.html`。

然后访问：http://localhost:4173

## 如何构建

不需要 npm、不需要打包。上传 `website/` 里的文件即可。

## 如何部署

### Cloudflare Pages（推荐）

1. 把本仓库推到 GitHub（或单独把 `website/` 做成一个仓库）
2. 打开 [Cloudflare Pages](https://pages.cloudflare.com/) → Create project → 连接 GitHub
3. 构建设置：
   - Framework preset: `None`
   - Build command: 留空
   - Build output directory: `website`（如果整个仓库就是网站，填 `/`）
4. Deploy

### GitHub Pages

**方式 A：网站在本仓库的 `/website`**

1. 仓库 Settings → Pages
2. Source 选 GitHub Actions，或把 `website` 设为发布目录（视仓库 Pages 设置而定）
3. 如果 Pages 只支持 `/docs` 或根目录，可以把 `website/` 的内容拷到 `docs/`，或使用下面的 Action

示例 Action（`.github/workflows/pages.yml`，需要时再加）：

```yaml
name: Deploy site
on:
  push:
    branches: [main]
    paths: ["website/**"]
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  deploy:
    environment:
      name: github-pages
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/upload-pages-artifact@v3
        with:
          path: website
      - uses: actions/deploy-pages@v4
```

**方式 B：单独仓库 `JUJU-Website`**

把 `website/` 目录里的文件作为仓库根目录推送，然后：

- Pages → Deploy from branch → `main` / root

## 如何绑定自己的域名

### Cloudflare Pages

1. Pages 项目 → Custom domains → 添加域名
2. 按提示在 DNS 里加 CNAME（例如 `@` 或 `www` → `your-project.pages.dev`）

### GitHub Pages

1. Pages 设置里填写 Custom domain
2. 在域名 DNS 添加：
   - `www` CNAME → `你的用户名.github.io`
   - 或 A 记录指向 GitHub Pages IP（按 GitHub 当前文档）
3. 仓库根目录可放 `CNAME` 文件，内容是你的域名

绑定域名后，建议再改两处 SEO：

1. `js/config.js` 里的 `siteUrl`，例如 `"https://your.domain"`
2. 各 HTML 里的 `og:image`、`canonical` 改成绝对地址，例如  
   `https://your.domain/assets/og-image.png`  
   （微信 / 小红书分享图通常需要绝对 URL）
3. `robots.txt` 和 `sitemap.xml` 里的地址同样改成绝对 URL

## 以后如何发布新 Android 版本

不要在 CloudBase 控制台里重新上传整个 `website` 文件夹。使用增量脚本，只上传新 APK 和 `js/config.js`，旧版 APK 会保留。

### 准备

1. 已安装 CloudBase CLI 并登录：

```powershell
npm i -g @cloudbase/cli
tcb login
```

2. 在项目根目录打好 Release APK：

```powershell
flutter build apk --release
```

产物路径必须是：`build/app/outputs/flutter-apk/app-release.apk`

### 发布

在仓库根目录执行：

```powershell
.\website\deploy.ps1 -Version 2.6.5
```

或在 `website` 目录执行：

```powershell
.\deploy.ps1 -Version 2.6.5
```

脚本会：

1. 检查上述 APK 是否存在
2. 复制为 `website/downloads/JUJUSchedule-v2.6.5.apk`
3. 写入 `js/config.js` 的 `version` 和 `downloads.beta`
4. 把 APK 上传到 CloudBase `/downloads/`
5. 把 `js/config.js` 上传到 CloudBase `/js/config.js`

下载地址会变成：

`https://juju-d7g3aezw61b68afe8-1358899741.tcloudbaseapp.com/downloads/JUJUSchedule-v2.6.5.apk`

未登录 CLI、环境 ID 不对、或找不到 APK 时，脚本会立刻停止，**不会改线上文件**。

更新日志不会自动写。每次上传新 APK 前，在 `js/config.js` 的 `changelog` 最前面加一行（版本号 + 一句话）。小改动如果没发安装包，这里可以跳版本。脚本仍只会上传 APK 和这份 `config.js`。

当前环境 ID：`juju-d7g3aezw61b68afe8`

## 以后如何更新版本号和更新日志

日常发版用 `deploy.ps1` 即可改版本号和 APK 地址。更新日志仍在 `js/config.js`：

| 要改的内容 | 字段 |
| --- | --- |
| 版本号 | `version` |
| APK / 内测地址 | `downloads.beta` |
| 更新日志 | `changelog`（只写实际上传的 APK，一行一句，新版本插到最前面） |
| GitHub | `links.github`（有了再填，空的会自动隐藏） |
| 小红书 | `links.xiaohongshu`（同上） |
| 反馈表单 | `links.feedbackZh` / `feedbackEn` |

## 以后如何扩展

在 `js/config.js` 里已经预留：

- `downloads.beta`（内测入口）
- Android / 鸿蒙 Coming Soon
- 中英文切换（`js/i18n.js`，以后可再加韩语等）

首页手机框是概念设计图，不需要换成真实截图。

## 注意

- 不要修改仓库里 Flutter App 的代码来做官网
- APK 放在 `website/downloads/`，由 `deploy.ps1` 上传；不要把 `*.apk` 提交进 git
- GitHub / 小红书链接暂时为空，页脚会自动隐藏

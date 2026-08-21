/**
 * ============================================================
 * JUJU Schedule 官网配置
 * ============================================================
 *
 * 以后发新版，优先运行 website/deploy.ps1，它会改这里的 version 和 downloads.beta，
 * 并只把新 APK 与本文件上传到 CloudBase。
 *   1. version              → 当前版本号（会显示在下载区、页脚等）
 *   2. downloads.beta       → Android APK 直链
 *   3. changelog            → 更新日志（只写实际上传过的 APK，新版本插到最前面）
 *   4. links                → GitHub / 小红书（有了再填，空字符串会自动隐藏）
 *   5. siteUrl              → 绑定域名后填写，用于 SEO 规范地址
 *
 * APK 放在 website/downloads/，由 deploy.ps1 上传到 CloudBase /downloads/。
 * 不要把 APK 提交进 git（仓库已忽略 *.apk）。
 */
window.JUJU_CONFIG = {
  appName: "JUJU Schedule",
  appNameZh: "JUJU日常",
  taglineZh: "让每天的安排，简单一点。",
  taglineEn: "Make every day a little simpler.",

  /** 当前对外版本号，显示为 v2.6.4 */
  version: "2.6.4",

  /**
   * 绑定自定义域名后填写，不要末尾斜杠。
   * 例如 "https://juju.example.com"
   * 留空时不影响页面浏览，但社交分享图建议绑定域名后再填。
   */
  siteUrl: "",

  /**
   * 下载入口。
   * beta：内测已开启，填问卷、群或 APK 直链。
   * 正式版 Android / 鸿蒙目前展示为 Coming Soon。
   */
  downloads: {
    beta: "https://juju-d7g3aezw61b68afe8-1358899741.tcloudbaseapp.com/downloads/JUJUSchedule-v2.6.4.apk",
  },

  platforms: {
    android: { comingSoon: true },
    harmonyos: { comingSoon: true },
  },

  /**
   * 外链。空字符串 = 页脚自动隐藏对应入口。
   * 反馈表单沿用 App 内现有的金数据表单。
   */
  links: {
    github: "",
    xiaohongshu: "",
    feedbackZh: "https://nacrsidy.jsjform.com/f/uUxISO",
    feedbackEn: "https://nacrsidy.jsjform.com/f/fsJ48Y",
  },

  /**
   * 官网更新日志：只记录实际上传到网页的 APK。
   * 小改动如果没发安装包，这里可以跳版本。
   * 每条一行：version + zh / en。新版本插到数组最前面。
   */
  changelog: [
    { version: "2.6.4", zh: "通知设置增加各品牌手机的自启动指引", en: "Autostart guides for more phone brands" },
    { version: "2.6.0", zh: "统一应用名称，备份可保存外观与专注预设", en: "Unified app name; backups include appearance and focus presets" },
    { version: "2.5.5", zh: "专注模式支持普通 / 严格", en: "Focus mode now supports Normal and Strict" },
    { version: "2.5.3", zh: "支持用一句话快速创建任务", en: "Create a task by typing one sentence" },
    { version: "2.4.2", zh: "新增 Android 桌面小组件", en: "Android home screen widgets" },
    { version: "2.4.0", zh: "提醒更可靠，增加自启动说明", en: "More reliable reminders and autostart guidance" },
  ],
};

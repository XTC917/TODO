(() => {
  const cfg = window.JUJU_CONFIG || {};
  const i18n = window.JUJU_I18N;
  if (!i18n) return;

  const storageKey = "juju-lang";

  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

  const readStore = () => {
    try {
      return localStorage.getItem(storageKey);
    } catch {
      return null;
    }
  };

  const writeStore = (value) => {
    try {
      localStorage.setItem(storageKey, value);
    } catch {
      /* some previews block storage */
    }
  };

  const queryLang = new URLSearchParams(location.search).get("lang");
  const storedLang = readStore();
  let lang =
    queryLang === "en" || queryLang === "zh"
      ? queryLang
      : storedLang === "en" || storedLang === "zh"
        ? storedLang
        : "zh";

  const t = (key) => (i18n[lang] && i18n[lang][key]) || i18n.zh[key] || key;

  const applyI18n = () => {
    $$("[data-i18n]").forEach((el) => {
      el.textContent = t(el.dataset.i18n);
    });
    $$("[data-i18n-aria]").forEach((el) => {
      el.setAttribute("aria-label", t(el.dataset.i18nAria));
    });
    document.documentElement.lang = lang === "en" ? "en" : "zh-CN";
    $$(".lang-toggle button").forEach((btn) => {
      btn.setAttribute(
        "aria-pressed",
        String(btn.getAttribute("data-lang") === lang),
      );
    });
    $$("[data-lang-block]").forEach((el) => {
      el.hidden = el.dataset.langBlock !== lang;
    });
    renderChangelog();
    applyDownloads();
    applyLinks();
  };

  const applyVersion = () => {
    $$("[data-version]").forEach((el) => {
      el.textContent = `v${cfg.version || ""}`;
    });
  };

  const applyDownloads = () => {
    const url = (cfg.downloads && cfg.downloads.beta) || "";
    $$("[data-download='beta']").forEach((el) => {
      if (url) {
        el.href = url;
        el.target = "_blank";
        el.rel = "noopener noreferrer";
      } else {
        el.href = "#download";
        el.removeAttribute("target");
        el.removeAttribute("rel");
      }
    });
  };

  const applyLinks = () => {
    const links = cfg.links || {};
    const setLink = (name, href) => {
      $$("[data-link='" + name + "']").forEach((el) => {
        if (href) {
          el.href = href;
          el.classList.remove("is-hidden");
          el.hidden = false;
        } else {
          el.classList.add("is-hidden");
          el.hidden = true;
        }
      });
    };

    setLink("github", links.github);
    setLink("xiaohongshu", links.xiaohongshu);
    setLink("feedback-form", lang === "en" ? links.feedbackEn : links.feedbackZh);
  };

  const changeNote = (entry) =>
    (lang === "en" ? entry.en : entry.zh) || "";

  const renderChangelog = () => {
    const full = $("[data-changelog='full']");
    const preview = $("[data-changelog='preview']");
    if (!cfg.changelog) return;

    const render = (target, items) => {
      if (!target) return;
      target.innerHTML = items
        .map(
          (entry) => `<div class="change-item">
            <span class="change-ver">v${escapeHtml(entry.version)}</span>
            <span class="change-note">${escapeHtml(changeNote(entry))}</span>
          </div>`,
        )
        .join("");
    };

    render(full, cfg.changelog);
    render(preview, cfg.changelog.slice(0, 3));
  };

  const escapeHtml = (value) =>
    String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");

  const bindLang = () => {
    document.addEventListener("click", (event) => {
      const btn = event.target.closest(".lang-toggle [data-lang]");
      if (!btn) return;
      event.preventDefault();
      lang = btn.getAttribute("data-lang") === "en" ? "en" : "zh";
      writeStore(lang);
      applyI18n();
    });
  };

  const bindMenu = () => {
    const btn = $(".menu-btn");
    const drawer = $(".nav-drawer");
    if (!btn || !drawer) return;
    btn.addEventListener("click", () => {
      const open = drawer.classList.toggle("open");
      btn.setAttribute("aria-expanded", String(open));
    });
    $$(".nav-drawer a").forEach((a) => {
      a.addEventListener("click", () => {
        drawer.classList.remove("open");
        btn.setAttribute("aria-expanded", "false");
      });
    });
  };

  const year = $("[data-year]");
  if (year) year.textContent = String(new Date().getFullYear());

  bindLang();
  bindMenu();
  applyVersion();
  applyI18n();
})();

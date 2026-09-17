(() => {
  "use strict";

  const prefs = vivaldi.prefs;
  if (!prefs || typeof prefs.get !== "function" || typeof prefs.set !== "function") {
    throw new Error("vivaldi.prefs API unavailable");
  }

  const USER_THEMES = "vivaldi.themes.user";
  const SYSTEM_THEMES = "vivaldi.themes.system";
  const CURRENT_THEME = "vivaldi.themes.current";
  const SCHEDULE_ENABLED = "vivaldi.theme.schedule.enabled";
  const THEME_ID = "omarchy-synced";
  const THEME_NAME = "Omarchy";
  const POLL_INTERVAL = 1000;
  const MAX_RESPONSE_BYTES = 4096;
  const PALETTE_KEYS = ["background", "foreground", "accent", "highlight"];

  let appliedPalette;
  let activated = false;
  let reportedError = false;

  function report(error) {
    if (reportedError) return;
    reportedError = true;
    const message = String(error && error.message ? error.message : error).slice(0, 200);
    console.error("[omarchy-theme]", message);
  }

  async function readResponseText(response) {
    const contentLength = Number(
      response.headers && response.headers.get && response.headers.get("content-length"),
    );
    if (Number.isFinite(contentLength) && contentLength > MAX_RESPONSE_BYTES) {
      throw new Error("palette response is too large");
    }

    if (!response.body || typeof response.body.getReader !== "function") {
      const text = await response.text();
      if (new TextEncoder().encode(text).byteLength > MAX_RESPONSE_BYTES) {
        throw new Error("palette response is too large");
      }
      return text;
    }

    const reader = response.body.getReader();
    const chunks = [];
    let byteLength = 0;
    try {
      while (true) {
        const chunk = await reader.read();
        if (chunk.done) break;
        byteLength += chunk.value.byteLength;
        if (byteLength > MAX_RESPONSE_BYTES) {
          await reader.cancel();
          throw new Error("palette response is too large");
        }
        chunks.push(chunk.value);
      }
    } finally {
      reader.releaseLock();
    }

    const bytes = new Uint8Array(byteLength);
    let offset = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, offset);
      offset += chunk.byteLength;
    }
    return new TextDecoder().decode(bytes);
  }

  async function readPalette() {
    const response = await fetch("omarchy-palette/colors.json", { cache: "no-store" });
    if (response.ok === false) throw new Error(`palette request failed (${response.status})`);
    const parsed = JSON.parse(await readResponseText(response));
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      throw new Error("palette must be an object");
    }

    const keys = Object.keys(parsed);
    if (keys.length !== PALETTE_KEYS.length || !PALETTE_KEYS.every((key) => keys.includes(key))) {
      throw new Error("palette must contain exactly four colors");
    }
    for (const key of PALETTE_KEYS) {
      if (typeof parsed[key] !== "string" || !/^#[0-9a-fA-F]{6}$/.test(parsed[key])) {
        throw new Error("palette contains an invalid color");
      }
    }

    return {
      background: parsed.background,
      foreground: parsed.foreground,
      accent: parsed.accent,
      highlight: parsed.highlight,
    };
  }

  function paletteKey(palette) {
    return PALETTE_KEYS.map((key) => palette[key]).join("|");
  }

  function themeWithPalette(theme, palette) {
    const nextTheme = {
      ...theme,
      id: THEME_ID,
      name: THEME_NAME,
      colorBg: palette.background,
      colorFg: palette.foreground,
      colorAccentBg: palette.accent,
      colorHighlightBg: palette.highlight,
      accentFromPage: false,
      preferSystemAccent: false,
      backgroundImage: "",
      colorWindowBg: "",
    };
    if ("defaultBackground" in nextTheme) nextTheme.defaultBackground = "";
    return nextTheme;
  }

  async function applyPalette(palette) {
    const systemResult = await prefs.get(SYSTEM_THEMES);
    const userResult = await prefs.get(USER_THEMES);
    const userThemes = Array.isArray(userResult.value) ? userResult.value : [];
    const existingIndex = userThemes.findIndex(
      (theme) => theme && typeof theme === "object" && theme.id === THEME_ID,
    );
    let nextThemes;

    if (existingIndex !== -1) {
      nextThemes = userThemes.slice();
      nextThemes[existingIndex] = themeWithPalette(userThemes[existingIndex], palette);
    } else {
      const systemThemes = Array.isArray(systemResult.value) ? systemResult.value : [];
      const systemDefault =
        systemThemes.find((theme) => theme && theme.id === "Vivaldi1") || systemThemes[0];
      if (!systemDefault || typeof systemDefault !== "object" || Array.isArray(systemDefault)) {
        throw new Error("installed system default theme unavailable");
      }
      nextThemes = userThemes.concat(themeWithPalette(systemDefault, palette));
    }

    await prefs.set({ path: USER_THEMES, value: nextThemes });
    if (!activated) {
      await prefs.set({ path: CURRENT_THEME, value: THEME_ID });
      await prefs.set({ path: SCHEDULE_ENABLED, value: "off" });
      activated = true;
    }
  }

  async function poll() {
    try {
      const palette = await readPalette();
      const key = paletteKey(palette);
      if (key !== appliedPalette) {
        await applyPalette(palette);
        appliedPalette = key;
      }
    } catch (error) {
      report(error);
    }
  }

  // Only one window per profile publishes theme preferences.
  void navigator.locks.request("omarchy-theme-sync", async () => {
    while (true) {
      await poll();
      await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL));
    }
  }).catch(report);
})();

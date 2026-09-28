#!/usr/bin/env node
/**
 * Playwright recordVideo helper for optional UI backup clips (no microphone).
 *
 * Env:
 *   ACCESS_URL  — page to open (required)
 *   OUT_FILE    — absolute path under Videos media root (required), e.g.
 *                 /home/fmeneses/Videos/kcd-ba-demo-backup/kcd-ba-05-ui-a.webm
 *   HOLD_MS     — how long to keep the page open (default 8000)
 *   IGNORE_HTTPS_ERRORS — set "1" for self-signed observer
 *
 * Requires: npm i -D playwright && npx playwright install chromium (host).
 */
import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";

const require = createRequire(import.meta.url);

const ACCESS_URL = process.env.ACCESS_URL || "";
const OUT_FILE = process.env.OUT_FILE || "";
const HOLD_MS = Number(process.env.HOLD_MS || "8000");
const IGNORE_HTTPS = process.env.IGNORE_HTTPS_ERRORS === "1";
const MEDIA_PREFIX = "/home/fmeneses/Videos/kcd-ba-demo-backup";

function fail(msg) {
  console.error(`error: ${msg}`);
  process.exit(1);
}

if (!ACCESS_URL) fail("ACCESS_URL is required");
if (!OUT_FILE) fail("OUT_FILE is required");
if (!path.isAbsolute(OUT_FILE)) fail("OUT_FILE must be an absolute path");
if (!OUT_FILE.startsWith(MEDIA_PREFIX + "/") && OUT_FILE !== MEDIA_PREFIX) {
  fail(`OUT_FILE must be under ${MEDIA_PREFIX}`);
}

const outDir = path.dirname(OUT_FILE);
fs.mkdirSync(outDir, { recursive: true });

let chromium;
try {
  ({ chromium } = require("playwright"));
} catch {
  fail(
    'playwright not installed — run: npm i -D playwright && npx playwright install chromium (from a host temp dir or this repo)',
  );
}

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  ignoreHTTPSErrors: IGNORE_HTTPS,
  recordVideo: {
    dir: outDir,
    size: { width: 1280, height: 720 },
  },
  // No permissions that imply mic/camera.
  permissions: [],
});

const page = await context.newPage();
try {
  await page.goto(ACCESS_URL, { waitUntil: "domcontentloaded", timeout: 60_000 });
  await new Promise((r) => setTimeout(r, HOLD_MS));
} catch (err) {
  console.error(`warn: navigation/hold issue: ${err.message}`);
}

await context.close();
await browser.close();

// Playwright names the video itself; rename/move to OUT_FILE.
const videos = fs
  .readdirSync(outDir)
  .filter((f) => f.endsWith(".webm"))
  .map((f) => path.join(outDir, f))
  .sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);

if (videos.length === 0) fail("no .webm produced by recordVideo");

const newest = videos[0];
if (path.resolve(newest) !== path.resolve(OUT_FILE)) {
  fs.renameSync(newest, OUT_FILE);
}

console.log(`wrote ${OUT_FILE}`);

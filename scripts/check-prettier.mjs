#!/usr/bin/env node

import { execFileSync, spawnSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import * as prettier from "prettier";

const MAX_BUFFER = 64 * 1024 * 1024;
const ZERO_SHA = /^0+$/;
const mode = process.argv[2];

if (!["--staged", "--push", "--all"].includes(mode)) {
  console.error("Usage: node scripts/check-prettier.mjs --staged|--push|--all");
  process.exit(2);
}

function git(args, encoding = "utf8") {
  return execFileSync("git", args, { encoding, maxBuffer: MAX_BUFFER });
}

function nulSeparated(args) {
  const output = git(args, "buffer");
  return output.toString("utf8").split("\0").filter(Boolean);
}

function pushedTips() {
  const input = readFileSync(0, "utf8").trim();
  if (!input) {
    const sha = git(["rev-parse", "HEAD"]).trim();
    return [{ label: `HEAD (${sha.slice(0, 12)})`, sha }];
  }

  const tips = new Map();
  for (const line of input.split("\n")) {
    const [localRef, localSha] = line.trim().split(/\s+/, 4);
    if (!localRef || !localSha || ZERO_SHA.test(localSha)) continue;
    tips.set(localSha, { label: `${localRef} (${localSha.slice(0, 12)})`, sha: localSha });
  }
  return [...tips.values()];
}

function snapshotsForMode() {
  if (mode === "--staged") {
    return [
      {
        label: "staged snapshot",
        files: nulSeparated(["diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z"]),
        read: (file) => git(["show", `:${file}`]),
      },
    ];
  }

  if (mode === "--all") {
    return [
      {
        label: "working tree",
        files: nulSeparated(["ls-files", "-z"]).filter(existsSync),
        read: (file) => readFileSync(file, "utf8"),
      },
    ];
  }

  return pushedTips().map(({ label, sha }) => ({
    label,
    files: nulSeparated(["ls-tree", "-r", "--name-only", "-z", sha]),
    read: (file) => git(["show", `${sha}:${file}`]),
  }));
}

function diffFor(file, before, after) {
  const temporary = mkdtempSync(join(tmpdir(), "iopl-prettier-"));
  const beforePath = join(temporary, "a", file);
  const afterPath = join(temporary, "b", file);

  try {
    mkdirSync(dirname(beforePath), { recursive: true });
    mkdirSync(dirname(afterPath), { recursive: true });
    writeFileSync(beforePath, before);
    writeFileSync(afterPath, after);

    const result = spawnSync(
      "git",
      ["diff", "--no-index", "--no-color", "--unified=3", "--no-prefix", "--", `a/${file}`, `b/${file}`],
      { cwd: temporary, encoding: "utf8", maxBuffer: MAX_BUFFER },
    );
    if (result.status !== 0 && result.status !== 1) {
      throw result.error ?? new Error(result.stderr || `git diff exited with status ${result.status}`);
    }
    return result.stdout.trimEnd();
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
}

function shellQuote(value) {
  return `'${value.replaceAll("'", "'\\''")}'`;
}

function errorDetails(error) {
  return error instanceof Error ? (error.stack ?? error.message) : String(error);
}

const mismatches = [];
const processingErrors = [];

for (const snapshot of snapshotsForMode()) {
  for (const file of snapshot.files) {
    try {
      const info = await prettier.getFileInfo(file, {
        ignorePath: ".prettierignore",
        withNodeModules: false,
      });
      if (info.ignored || info.inferredParser === null) continue;

      const source = snapshot.read(file);
      const options = (await prettier.resolveConfig(file, { editorconfig: true })) ?? {};
      const formatted = await prettier.format(source, { ...options, filepath: file });
      if (source !== formatted) {
        mismatches.push({ snapshot: snapshot.label, file, diff: diffFor(file, source, formatted) });
      }
    } catch (error) {
      processingErrors.push({ snapshot: snapshot.label, file, details: errorDetails(error) });
    }
  }
}

if (mismatches.length === 0 && processingErrors.length === 0) {
  const scope = mode === "--staged" ? "staged files" : mode === "--push" ? "pushed ref tips" : "tracked files";
  console.log(`Prettier check passed for ${scope}.`);
  process.exit(0);
}

console.error("\nPrettier check failed.\n");

for (const mismatch of mismatches) {
  console.error(`FORMAT ERROR: ${mismatch.file}`);
  console.error(`Snapshot: ${mismatch.snapshot}`);
  console.error("Prettier would make the following changes:");
  console.error(mismatch.diff);
  console.error("");
}

for (const failure of processingErrors) {
  console.error(`PRETTIER ERROR: ${failure.file}`);
  console.error(`Snapshot: ${failure.snapshot}`);
  console.error("Prettier could not parse or format this file:");
  console.error(failure.details);
  console.error("");
}

const affectedFiles = [...new Set([...mismatches, ...processingErrors].map(({ file }) => file))];
if (mode === "--staged") {
  console.error("Commit blocked: staged content is not Prettier-clean.");
  console.error("Fix and re-stage the reported files, then retry:");
  console.error(`  corepack yarn prettier --write -- ${affectedFiles.map(shellQuote).join(" ")}`);
  console.error(`  git add -- ${affectedFiles.map(shellQuote).join(" ")}`);
} else if (mode === "--push") {
  console.error("Push blocked: at least one ref tip being pushed is not Prettier-clean.");
  console.error("Format the files, commit the result, then retry the push:");
  console.error("  corepack yarn fix");
  console.error(`  git add -- ${affectedFiles.map(shellQuote).join(" ")}`);
  console.error("  git commit");
  console.error("  git push");
} else {
  console.error("Tracked files are not Prettier-clean.");
  console.error("Fix them with:");
  console.error("  corepack yarn fix");
}

process.exit(processingErrors.length > 0 ? 2 : 1);

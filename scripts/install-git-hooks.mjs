#!/usr/bin/env node

import { spawnSync } from "node:child_process";

const insideWorkTree = spawnSync("git", ["rev-parse", "--is-inside-work-tree"], {
  encoding: "utf8",
  stdio: ["ignore", "pipe", "ignore"],
});

if (insideWorkTree.status !== 0 || insideWorkTree.stdout.trim() !== "true") {
  console.log("Git hooks were not installed because this is not a Git worktree.");
  process.exit(0);
}

const configured = spawnSync("git", ["config", "--local", "core.hooksPath", ".githooks"], {
  encoding: "utf8",
  stdio: "inherit",
});

if (configured.status !== 0) {
  console.error("Could not configure core.hooksPath; Git hooks were not installed.");
  process.exit(configured.status ?? 1);
}

console.log("Installed repository Git hooks from .githooks (pre-commit and pre-push).");

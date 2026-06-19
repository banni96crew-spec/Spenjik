import { readFile, stat } from "node:fs/promises";
import path from "node:path";

import { createResult, STATUS } from "../lib/output.mjs";
import { isPathInside, normalizePath } from "../lib/repository.mjs";

const LOWERCASE_SNAKE_CASE = /^[a-z0-9]+(?:_[a-z0-9]+)*\.tres$/;
const HEADER_PATTERN = /^\[gd_resource(?:\s+[^\]]+)?\]$/;
const FORMAT_PATTERN = /\bformat\s*=\s*3\b/;
const RUNTIME_PROPERTY_PATTERN =
  /^\s*(runtime_state|active_state|current_owner|owner_player_id|owned_by|cooldown_remaining|market_state|random_state|contract_progress|current_progress|current_round|current_phase|combat_log|owned_cards|player_hand)\s*=/i;

function normalizedRelativePath(repositoryRoot, filePath) {
  return path.relative(repositoryRoot, filePath).split(path.sep).join("/");
}

function lineNumberAt(content, offset) {
  let line = 1;
  for (let index = 0; index < offset; index += 1) {
    if (content[index] === "\n") {
      line += 1;
    }
  }
  return line;
}

function firstContentLine(content) {
  const lines = content.replace(/^\uFEFF/, "").split(/\r\n|\n|\r/);
  const index = lines.findIndex((line) => line.trim() !== "");
  return index < 0 ? null : { line: index + 1, text: lines[index].trim() };
}

function stripGodotComments(content) {
  return content
    .split(/\r\n|\n|\r/)
    .map((line) => {
      let quote = null;

      for (let index = 0; index < line.length; index += 1) {
        const character = line[index];
        const next = line[index + 1] ?? "";

        if (quote) {
          if (character === "\\") {
            index += next === "" ? 0 : 1;
          } else if (character === quote) {
            quote = null;
          }
          continue;
        }

        if (character === '"' || character === "'") {
          quote = character;
        } else if (character === ";" || character === "#") {
          return line.slice(0, index);
        }
      }

      return line;
    })
    .join("\n");
}

function collectResourcePaths(content) {
  const references = [];
  const pattern = /["'](res:\/\/[^"'\r\n]*)["']/g;

  for (const match of content.matchAll(pattern)) {
    references.push({
      value: match[1],
      line: lineNumberAt(content, match.index),
    });
  }

  return references;
}

function collectAbsolutePaths(content) {
  const findings = [];
  const quotedValuePattern = /["']([^"'\r\n]*)["']/g;

  for (const match of content.matchAll(quotedValuePattern)) {
    const value = match[1];
    const isWindowsPath = /^[A-Za-z]:[\\/]/.test(value);
    const isUncPath = /^\\{2,}[^\\/]+[\\/]/.test(value);
    const isLinuxPath = /^\//.test(value);

    if (isWindowsPath || isUncPath || isLinuxPath) {
      findings.push({
        value,
        line: lineNumberAt(content, match.index),
      });
    }
  }

  return findings;
}

function collectRuntimeProperties(content) {
  const findings = [];
  const lines = content.split(/\r\n|\n|\r/);

  for (let index = 0; index < lines.length; index += 1) {
    const match = lines[index].match(RUNTIME_PROPERTY_PATTERN);
    if (match) {
      findings.push({ property: match[1], line: index + 1 });
    }
  }

  return findings;
}

async function isFile(candidate) {
  try {
    return (await stat(candidate)).isFile();
  } catch {
    return false;
  }
}

async function validateReferences(references, repositoryRoot, relativePath) {
  const errors = [];
  const checked = new Set();

  for (const reference of references) {
    const repositoryRelative = reference.value.slice("res://".length);
    const resolved = normalizePath(repositoryRelative, repositoryRoot);

    if (!resolved || !isPathInside(repositoryRoot, resolved)) {
      errors.push(
        `${relativePath}:${reference.line}: reference escapes the project root: ${reference.value}.`,
      );
      continue;
    }

    const key =
      process.platform === "win32" ? resolved.toLowerCase() : resolved;
    if (checked.has(key)) {
      continue;
    }
    checked.add(key);

    if (!(await isFile(resolved))) {
      errors.push(
        `${relativePath}:${reference.line}: referenced file does not exist: ${reference.value}.`,
      );
    }
  }

  return errors;
}

export async function resourceIntegrityValidator(context) {
  if (path.extname(context.filePath).toLowerCase() !== ".tres") {
    return createResult(STATUS.PASS, "Edited file is not a .tres Resource.");
  }

  let content;
  try {
    content = await readFile(context.filePath, "utf8");
  } catch (error) {
    return createResult(
      STATUS.SKIP,
      `Unable to read changed Resource file: ${error.message}`,
    );
  }

  const relativePath = normalizedRelativePath(
    context.repositoryRoot,
    context.filePath,
  );
  const errors = [];
  const warnings = [];
  const header = firstContentLine(content);

  if (!header || !HEADER_PATTERN.test(header.text)) {
    errors.push(
      `${relativePath}: first non-empty line must be a [gd_resource ...] header.`,
    );
  } else if (!FORMAT_PATTERN.test(header.text)) {
    errors.push(
      `${relativePath}:${header.line}: Godot 4 Resource header must declare format=3.`,
    );
  }

  if (!LOWERCASE_SNAKE_CASE.test(path.basename(context.filePath))) {
    errors.push(
      `${relativePath}: Resource filename must be a lowercase snake_case ID.`,
    );
  }

  const sourceWithoutComments = stripGodotComments(content);
  const references = collectResourcePaths(sourceWithoutComments);
  errors.push(
    ...(await validateReferences(
      references,
      context.repositoryRoot,
      relativePath,
    )),
  );

  for (const finding of collectAbsolutePaths(sourceWithoutComments)) {
    errors.push(
      `${relativePath}:${finding.line}: absolute local path is forbidden: ${finding.value}.`,
    );
  }

  for (const finding of collectRuntimeProperties(sourceWithoutComments)) {
    errors.push(
      `${relativePath}:${finding.line}: Resource contains probable runtime-state property "${finding.property}"; runtime state belongs in Dictionary snapshots.`,
    );
  }

  if (errors.length > 0) {
    return createResult(
      STATUS.ERROR,
      `Resource integrity errors found in ${relativePath}.`,
      [...errors, ...warnings],
    );
  }

  if (warnings.length > 0) {
    return createResult(
      STATUS.WARN,
      `Resource integrity warnings found in ${relativePath}.`,
      warnings,
    );
  }

  return createResult(
    STATUS.PASS,
    `Resource integrity checks passed: ${relativePath}.`,
  );
}

import { execFile } from "node:child_process";
import { access, readFile, stat } from "node:fs/promises";
import path from "node:path";
import { promisify } from "node:util";

import { createResult, STATUS } from "../lib/output.mjs";

const execFileAsync = promisify(execFile);
const TEST_ROOTS = ["tests/unit/", "tests/integration/", "tests/replay/", "tests/static/"];
const PRODUCTION_ROOTS = ["autoload/", "logic/", "data/", "scenes/"];
const MUTATOR_NAME =
  /^(?:add|advance|apply|attack|buy|cancel|choose|claim|commit|complete|consume|create|discard|end|execute|finish|grant|initialize|mark|pay|purchase|remove|reset|resolve|select|sell|set|skip|spend|start|take|transition|unlock|update|use)_/;
const SELECTOR_NAME =
  /^(?:get|preview|can|is|has|list|find|valid|available|build_view|make_view|disabled_reason)_|(?:_view|_preview|_selector|_targets|_availability)$/;

async function exists(candidate) {
  try {
    await access(candidate);
    return true;
  } catch {
    return false;
  }
}

async function isFile(candidate) {
  try {
    return (await stat(candidate)).isFile();
  } catch {
    return false;
  }
}

async function isDirectory(candidate) {
  try {
    return (await stat(candidate)).isDirectory();
  } catch {
    return false;
  }
}

function normalizeGitPath(value) {
  return value.replaceAll("\\", "/").replace(/^\.\//, "");
}

function isUnder(filePath, roots) {
  const comparable =
    process.platform === "win32" ? filePath.toLowerCase() : filePath;
  return roots.some((root) =>
    comparable.startsWith(
      process.platform === "win32" ? root.toLowerCase() : root,
    ),
  );
}

async function runGit(repositoryRoot, args) {
  const { stdout } = await execFileAsync(
    "git",
    ["-C", repositoryRoot, ...args],
    {
      encoding: "utf8",
      maxBuffer: 8 * 1024 * 1024,
      windowsHide: true,
    },
  );
  return stdout;
}

function parseNameList(output) {
  return output
    .split(/\r?\n/)
    .map((entry) => normalizeGitPath(entry.trim()))
    .filter(Boolean);
}

function parseUntracked(statusOutput) {
  const files = [];
  const records = statusOutput.split("\0").filter(Boolean);

  for (let index = 0; index < records.length; index += 1) {
    const record = records[index];
    const status = record.slice(0, 2);
    let filePath = record.slice(3);

    if (status.includes("R") || status.includes("C")) {
      filePath = records[index + 1] ?? filePath;
      index += 1;
    }

    if (status === "??") {
      files.push(normalizeGitPath(filePath));
    }
  }

  return files;
}

async function changedFiles(repositoryRoot) {
  const [working, staged, workingDeleted, stagedDeleted, status] =
    await Promise.all([
      runGit(repositoryRoot, [
        "diff",
        "--name-only",
        "--diff-filter=ACMRTUXB",
      ]),
      runGit(repositoryRoot, [
        "diff",
        "--cached",
        "--name-only",
        "--diff-filter=ACMRTUXB",
      ]),
      runGit(repositoryRoot, ["diff", "--name-only", "--diff-filter=D"]),
      runGit(repositoryRoot, [
        "diff",
        "--cached",
        "--name-only",
        "--diff-filter=D",
      ]),
      runGit(repositoryRoot, [
        "status",
        "--porcelain=v1",
        "-z",
        "--untracked-files=all",
      ]),
    ]);

  const deleted = new Set([
    ...parseNameList(workingDeleted),
    ...parseNameList(stagedDeleted),
  ]);

  return {
    files: [
      ...new Set([
        ...parseNameList(working),
        ...parseNameList(staged),
        ...deleted,
        ...parseUntracked(status),
      ]),
    ],
    deleted,
  };
}

function parseChangedNewLines(patch) {
  const changedLines = new Set();
  let newLine = 0;

  for (const line of patch.split(/\r?\n/)) {
    const header = line.match(/^@@\s+-\d+(?:,\d+)?\s+\+(\d+)(?:,(\d+))?\s+@@/);
    if (header) {
      newLine = Number(header[1]);
      continue;
    }

    if (line.startsWith("+++")) {
      continue;
    }
    if (line.startsWith("+")) {
      changedLines.add(newLine);
      newLine += 1;
    } else if (!line.startsWith("-") && !line.startsWith("\\")) {
      newLine += 1;
    }
  }

  return changedLines;
}

function changedRemovedFunctionNames(patch) {
  const names = [];
  for (const line of patch.split(/\r?\n/)) {
    const match = line.match(/^-\s*(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/);
    if (match) {
      names.push(match[1]);
    }
  }
  return names;
}

async function filePatch(repositoryRoot, filePath) {
  const [staged, working] = await Promise.all([
    runGit(repositoryRoot, ["diff", "--cached", "--unified=0", "--", filePath]),
    runGit(repositoryRoot, ["diff", "--unified=0", "--", filePath]),
  ]);

  if (staged !== "" || working !== "") {
    return `${staged}\n${working}`;
  }

  const absolutePath = path.join(repositoryRoot, ...filePath.split("/"));
  if (await exists(absolutePath)) {
    const lines = (await readFile(absolutePath, "utf8")).split(/\r?\n/);
    return [
      `@@ -0,0 +1,${lines.length} @@`,
      ...lines.map((line) => `+${line}`),
    ].join("\n");
  }

  return "";
}

function functionRanges(content) {
  const lines = content.split(/\r?\n/);
  const ranges = [];

  for (let index = 0; index < lines.length; index += 1) {
    const match = lines[index].match(
      /^(\s*)(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/,
    );
    if (!match) {
      continue;
    }

    const indent = match[1].replaceAll("\t", "    ").length;
    let endLine = lines.length;
    for (let cursor = index + 1; cursor < lines.length; cursor += 1) {
      if (lines[cursor].trim() === "") {
        continue;
      }
      const currentIndent =
        (lines[cursor].match(/^\s*/)?.[0] ?? "").replaceAll("\t", "    ").length;
      if (currentIndent <= indent) {
        endLine = cursor;
        break;
      }
    }

    ranges.push({ name: match[2], startLine: index + 1, endLine });
  }

  return ranges;
}

async function impactedFunctions(repositoryRoot, filePath, patch) {
  const absolutePath = path.join(repositoryRoot, ...filePath.split("/"));
  let content = "";
  try {
    content = await readFile(absolutePath, "utf8");
  } catch {
    return changedRemovedFunctionNames(patch);
  }

  const changedLines = parseChangedNewLines(patch);
  const names = functionRanges(content)
    .filter((range) =>
      [...changedLines].some(
        (line) => line >= range.startLine && line <= range.endLine,
      ),
    )
    .map((range) => range.name);

  return [...new Set([...names, ...changedRemovedFunctionNames(patch)])];
}

function snakeCase(value) {
  return value
    .replace(/([a-z0-9])([A-Z])/g, "$1_$2")
    .replace(/[^A-Za-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .toLowerCase();
}

function sourceStem(filePath) {
  return snakeCase(path.basename(filePath, ".gd"))
    .replace(
      /_(?:logic|engine|controller|validator|resolver|manager|catalog|definition)$/,
      "",
    );
}

function isCorrespondingTest(sourcePath, testPath) {
  const testName = snakeCase(path.basename(testPath, ".gd")).replace(/^test_/, "");
  const stem = sourceStem(sourcePath);

  if (stem.length >= 3 && (testName.includes(stem) || stem.includes(testName))) {
    return true;
  }

  if (sourcePath.startsWith("autoload/GameStateManager") && testName.includes("game_state_manager")) {
    return true;
  }
  if (sourcePath.startsWith("scenes/ui/") && testPath.startsWith("tests/static/")) {
    return /(?:ui|architecture|boundar)/.test(testName);
  }
  if (
    sourcePath.startsWith("logic/random/") &&
    (testPath.startsWith("tests/replay/") ||
      /random|determin|seeded/.test(testName))
  ) {
    return true;
  }

  return false;
}

function containsSemanticTest(content, kind) {
  const normalized = content.toLowerCase();

  if (kind === "random") {
    return /replay|determin|random_step|seeded_random|seeded_picker|same_seed/.test(
      normalized,
    );
  }
  if (kind === "selector") {
    return (
      /no[_ -]?mutation|does_not_mutate|unchanged|read[_ -]?only/.test(normalized) &&
      /selector|preview|view|random_step|state/.test(normalized)
    );
  }
  if (kind === "mutator") {
    return (
      /failed|failure|invalid|reject/.test(normalized) &&
      /no[_ -]?mutation|does_not_mutate|unchanged|before|snapshot/.test(normalized)
    );
  }

  return false;
}

async function changedTestContent(repositoryRoot, testFiles) {
  const chunks = [];
  for (const testPath of testFiles) {
    const absolutePath = path.join(repositoryRoot, ...testPath.split("/"));
    try {
      chunks.push(await readFile(absolutePath, "utf8"));
    } catch {
      chunks.push(await filePatch(repositoryRoot, testPath));
    }
  }
  return chunks.join("\n");
}

export async function testImpactValidator(context) {
  const projectFile = path.join(context.repositoryRoot, "project.godot");
  const testsDirectory = path.join(context.repositoryRoot, "tests");

  if (!(await isFile(projectFile)) || !(await isDirectory(testsDirectory))) {
    return createResult(
      STATUS.SKIP,
      "Test impact skipped: project.godot or tests/ is not present.",
    );
  }

  let changeSet;
  try {
    changeSet = await changedFiles(context.repositoryRoot);
  } catch (error) {
    return createResult(
      STATUS.SKIP,
      `Test impact skipped: unable to inspect git diff (${error.message}).`,
    );
  }

  const productionFiles = changeSet.files.filter(
    (filePath) =>
      filePath.endsWith(".gd") &&
      isUnder(filePath, PRODUCTION_ROOTS) &&
      !isUnder(filePath, ["tests/", "addons/"]),
  );
  const testFiles = changeSet.files.filter(
    (filePath) =>
      filePath.endsWith(".gd") &&
      isUnder(filePath, TEST_ROOTS) &&
      !changeSet.deleted.has(filePath),
  );

  if (productionFiles.length === 0) {
    return createResult(
      STATUS.PASS,
      "Test impact: no production GDScript changes detected.",
    );
  }

  const impacted = {
    random: false,
    selector: false,
    mutator: false,
    facade: productionFiles.includes("autoload/GameStateManager.gd"),
  };

  for (const sourcePath of productionFiles) {
    const patch = await filePatch(context.repositoryRoot, sourcePath);
    const functions = await impactedFunctions(
      context.repositoryRoot,
      sourcePath,
      patch,
    );
    const patchText = patch.toLowerCase();

    if (
      sourcePath.startsWith("logic/random/") ||
      /seededrandom|seededpicker|state\s*\[\s*["']random["']\s*\]|random_step|randf\s*\(|randi\s*\(/i.test(
        patch,
      )
    ) {
      impacted.random = true;
    }
    if (functions.some((name) => SELECTOR_NAME.test(name))) {
      impacted.selector = true;
    }
    if (functions.some((name) => MUTATOR_NAME.test(name))) {
      impacted.mutator = true;
    }
    if (
      sourcePath === "autoload/GameStateManager.gd" &&
      /func\s+[a-z_][a-z0-9_]*\s*\(/.test(patchText)
    ) {
      impacted.facade = true;
    }
  }

  const warnings = [];
  const correspondingTests = testFiles.filter((testPath) =>
    productionFiles.some((sourcePath) =>
      isCorrespondingTest(sourcePath, testPath),
    ),
  );
  const testContent = await changedTestContent(
    context.repositoryRoot,
    testFiles,
  );

  if (testFiles.length === 0) {
    warnings.push(
      `Production gameplay GDScript changed without tests: ${productionFiles.join(", ")}.`,
    );
  } else if (correspondingTests.length === 0) {
    warnings.push(
      `Changed tests do not appear to correspond to production files: ${productionFiles.join(", ")}.`,
    );
  }

  if (
    impacted.random &&
    !(
      testFiles.some((filePath) => filePath.startsWith("tests/replay/")) ||
      containsSemanticTest(testContent, "random")
    )
  ) {
    warnings.push(
      "Random-sensitive code changed without replay/determinism test changes.",
    );
  }

  if (
    impacted.selector &&
    !containsSemanticTest(testContent, "selector")
  ) {
    warnings.push(
      "Selector/preview code changed without an explicit no-mutation test.",
    );
  }

  if (impacted.mutator && !containsSemanticTest(testContent, "mutator")) {
    warnings.push(
      "Mutator code changed without an explicit failed-validation/no-mutation test.",
    );
  }

  if (
    impacted.facade &&
    !testFiles.some(
      (filePath) =>
        filePath.includes("game_state_manager") ||
        filePath.startsWith("tests/integration/"),
    )
  ) {
    warnings.push(
      "Public GameStateManager facade changed without API or integration test changes.",
    );
  }

  if (warnings.length === 0) {
    return createResult(
      STATUS.PASS,
      `Test impact checks passed for ${productionFiles.length} production file(s).`,
    );
  }

  return createResult(
    STATUS.WARN,
    "Test impact warnings found.",
    warnings,
  );
}

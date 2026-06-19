import { readFile } from "node:fs/promises";
import path from "node:path";

import { createResult, STATUS } from "../lib/output.mjs";

const RANDOM_DOCUMENT = "docs/prd/14_DETERMINISTIC_RANDOM.md";
const TEST_JUSTIFICATION =
  /\b(?:OQ-[A-Za-z0-9_-]+|test[- ]only|static random scan|static scan fixture|intentional(?:ly)? nondeterministic|nondeterministic fixture|determinism fixture)\b/i;

const FORBIDDEN_PATTERNS = Object.freeze([
  { pattern: /\brandf\s*\(/g, label: "randf()" },
  { pattern: /\brandi\s*\(/g, label: "randi()" },
  { pattern: /\brandomize\s*\(/g, label: "randomize()" },
  {
    pattern: /\bRandomNumberGenerator\b/g,
    label: "RandomNumberGenerator",
  },
]);

const SYSTEM_TIME_PATTERNS = Object.freeze([
  {
    pattern:
      /\bTime\s*\.\s*(?:get_unix_time_from_system|get_datetime_dict_from_system|get_datetime_string_from_system|get_date_dict_from_system|get_time_dict_from_system|get_time_string_from_system|get_ticks_msec|get_ticks_usec)\s*\(/g,
    label: "Time/system-time API",
  },
  {
    pattern:
      /\bOS\s*\.\s*(?:get_unix_time|get_system_time|get_ticks_msec|get_ticks_usec)\s*\(/g,
    label: "OS/system-time API",
  },
]);

const LOCAL_STREAM_PATTERNS = Object.freeze([
  {
    pattern: /\b(?:SeededRandom|SeededPicker)\s*\.\s*new\s*\(/g,
    label: "local SeededRandom/SeededPicker instance",
  },
  {
    pattern: /\bSeededRandom\s*\.\s*seeded_random\s*\(/g,
    label: "direct seeded_random() stream outside logic/random",
  },
]);

function normalizedRelativePath(repositoryRoot, filePath) {
  return path.relative(repositoryRoot, filePath).split(path.sep).join("/");
}

function comparablePath(value) {
  return process.platform === "win32" ? value.toLowerCase() : value;
}

function isUnder(relativePath, directory) {
  return comparablePath(relativePath).startsWith(comparablePath(directory));
}

function maskStringsAndComments(content) {
  let result = "";
  let state = "code";
  let quote = "";

  for (let index = 0; index < content.length; index += 1) {
    const character = content[index];
    const next = content[index + 1] ?? "";
    const third = content[index + 2] ?? "";

    if (state === "comment") {
      if (character === "\n" || character === "\r") {
        state = "code";
        result += character;
      } else {
        result += " ";
      }
      continue;
    }

    if (state === "string") {
      if (character === "\\") {
        result += " ";
        if (next !== "") {
          result += next === "\n" || next === "\r" ? next : " ";
          index += 1;
        }
      } else if (character === quote) {
        result += " ";
        state = "code";
      } else {
        result += character === "\n" || character === "\r" ? character : " ";
      }
      continue;
    }

    if (state === "triple_string") {
      if (character === quote && next === quote && third === quote) {
        result += "   ";
        index += 2;
        state = "code";
      } else {
        result += character === "\n" || character === "\r" ? character : " ";
      }
      continue;
    }

    if (character === "#") {
      result += " ";
      state = "comment";
      continue;
    }

    if (character === "'" || character === '"') {
      quote = character;
      if (next === character && third === character) {
        result += "   ";
        index += 2;
        state = "triple_string";
      } else {
        result += " ";
        state = "string";
      }
      continue;
    }

    result += character;
  }

  return result;
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

function collectMatches(code, patterns, kind) {
  const findings = [];

  for (const entry of patterns) {
    for (const match of code.matchAll(entry.pattern)) {
      findings.push({
        line: lineNumberAt(code, match.index),
        kind,
        label: entry.label,
      });
    }
  }

  return findings;
}

function nearbyTestJustification(lines, lineNumber) {
  const start = Math.max(0, lineNumber - 3);
  const end = Math.min(lines.length, lineNumber + 1);
  return lines.slice(start, end).some((line) => TEST_JUSTIFICATION.test(line));
}

function formatProductionFinding(relativePath, finding) {
  return `${relativePath}:${finding.line}: ${finding.label} violates the shared state["random"] contract. Use SeededRandom.gd or SeededPicker.gd. See ${RANDOM_DOCUMENT}.`;
}

function formatTestFinding(relativePath, finding, justified, fixture) {
  const reason = fixture
    ? "nondeterministic test fixture detected"
    : justified
      ? "explicitly justified test-only random usage"
      : "test random usage lacks an explicit test-only/static-scan justification";

  return `${relativePath}:${finding.line}: ${reason}: ${finding.label}. See ${RANDOM_DOCUMENT}.`;
}

function isBlockingContext(context) {
  return (
    context.blocking === true ||
    context.eventName === "commitGate" ||
    context.eventName === "beforeCommit"
  );
}

export async function deterministicRandomValidator(context) {
  if (path.extname(context.filePath).toLowerCase() !== ".gd") {
    return createResult(STATUS.PASS, "Edited file is not GDScript.");
  }

  const relativePath = normalizedRelativePath(
    context.repositoryRoot,
    context.filePath,
  );

  if (isUnder(relativePath, "docs/")) {
    return createResult(STATUS.PASS, "Documentation is excluded from random checks.");
  }

  const isTest = isUnder(relativePath, "tests/");
  const isRandomOwner = isUnder(relativePath, "logic/random/");
  const isProductionGameplay =
    isUnder(relativePath, "logic/") ||
    isUnder(relativePath, "autoload/") ||
    isUnder(relativePath, "data/");

  if (!isTest && !isProductionGameplay) {
    return createResult(
      STATUS.PASS,
      "Edited file is outside production gameplay and test random checks.",
    );
  }

  let content;
  try {
    content = await readFile(context.filePath, "utf8");
  } catch (error) {
    return createResult(
      STATUS.SKIP,
      `Unable to read changed GDScript file: ${error.message}`,
    );
  }

  const code = maskStringsAndComments(content);
  const findings = [
    ...collectMatches(code, FORBIDDEN_PATTERNS, "forbidden_api"),
    ...collectMatches(code, SYSTEM_TIME_PATTERNS, "system_time"),
  ];

  if (!isRandomOwner) {
    findings.push(...collectMatches(code, LOCAL_STREAM_PATTERNS, "local_stream"));
  }

  findings.sort((left, right) => left.line - right.line);
  if (findings.length === 0) {
    return createResult(
      STATUS.PASS,
      `Deterministic random checks passed: ${relativePath}.`,
    );
  }

  if (isTest) {
    const lines = content.split(/\r\n|\n|\r/);
    const fixture = isUnder(relativePath, "tests/fixtures/");
    const details = findings.map((finding) =>
      formatTestFinding(
        relativePath,
        finding,
        nearbyTestJustification(lines, finding.line),
        fixture,
      ),
    );

    return createResult(
      STATUS.WARN,
      `Test-only nondeterministic random usage found in ${relativePath}.`,
      details,
    );
  }

  const details = findings.map((finding) =>
    formatProductionFinding(relativePath, finding),
  );
  const status = isBlockingContext(context) ? STATUS.BLOCK : STATUS.ERROR;

  return createResult(
    status,
    `Forbidden production gameplay random usage found in ${relativePath}.`,
    details,
  );
}

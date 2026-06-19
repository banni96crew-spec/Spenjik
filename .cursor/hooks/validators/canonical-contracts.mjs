import { readFile } from "node:fs/promises";
import path from "node:path";

import { createResult, STATUS } from "../lib/output.mjs";

const OPEN_QUESTIONS_DOCUMENT = "docs/prd/21_OPEN_QUESTIONS_AND_FIXES.md";
const IDS_DOCUMENT = "docs/prd/03_IDS_AND_CONSTANTS.md";
const AMBIGUITY_MARKER = /\b(?:TODO|TBD|FIXME)\b|\?\?\?/i;
const OPEN_QUESTION = /\bOQ-[A-Za-z0-9_-]+\b/i;
const TEXT_EXTENSIONS = new Set([
  ".cfg",
  ".gd",
  ".json",
  ".md",
  ".tres",
  ".tscn",
  ".txt",
]);
const MUTATOR_VERBS =
  /^(?:add|advance|apply|attack|buy|cancel|choose|claim|commit|complete|consume|create|discard|end|execute|finish|grant|initialize|mark|pay|purchase|remove|reset|resolve|select|sell|set|skip|spend|start|take|transition|unlock|update|use)_/;

function normalizedRelativePath(repositoryRoot, filePath) {
  return path.relative(repositoryRoot, filePath).split(path.sep).join("/");
}

function comparablePath(value) {
  return process.platform === "win32" ? value.toLowerCase() : value;
}

function isUnder(relativePath, directory) {
  return comparablePath(relativePath).startsWith(comparablePath(directory));
}

function isExactPath(relativePath, expected) {
  return comparablePath(relativePath) === comparablePath(expected);
}

function hasNearbyOpenQuestion(lines, index) {
  const start = Math.max(0, index - 1);
  const end = Math.min(lines.length - 1, index + 1);

  for (let current = start; current <= end; current += 1) {
    if (OPEN_QUESTION.test(lines[current])) {
      return true;
    }
  }

  return false;
}

function ambiguityFindings(content, relativePath, edits) {
  if (isExactPath(relativePath, OPEN_QUESTIONS_DOCUMENT)) {
    return [];
  }

  const source =
    path.extname(relativePath).toLowerCase() === ".gd"
      ? content
      : addedText(edits);
  if (source === "") {
    return [];
  }

  const lines = source.split(/\r\n|\n|\r/);
  const findings = [];

  for (let index = 0; index < lines.length; index += 1) {
    if (
      AMBIGUITY_MARKER.test(lines[index]) &&
      !hasNearbyOpenQuestion(lines, index)
    ) {
      findings.push(
        `${relativePath}:${index + 1}: TODO/TBD/FIXME/??? requires an OQ-* reference on the same or adjacent line.`,
      );
    }
  }

  return findings;
}

function stripComment(line) {
  let result = "";
  let quote = null;

  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];
    const next = line[index + 1] ?? "";

    if (quote) {
      result += character;
      if (character === "\\") {
        if (next !== "") {
          result += next;
          index += 1;
        }
      } else if (character === quote) {
        quote = null;
      }
      continue;
    }

    if (character === "'" || character === '"') {
      quote = character;
      result += character;
      continue;
    }

    if (character === "#") {
      break;
    }

    result += character;
  }

  return result;
}

function indentation(line) {
  const prefix = line.match(/^[\t ]*/)?.[0] ?? "";
  return [...prefix].reduce(
    (total, character) => total + (character === "\t" ? 4 : 1),
    0,
  );
}

function findFunctionBodies(content) {
  const rawLines = content.split(/\r\n|\n|\r/);
  const codeLines = rawLines.map(stripComment);
  const functions = [];

  for (let index = 0; index < codeLines.length; index += 1) {
    const match = codeLines[index].match(
      /^(\s*)(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\([^)]*\)\s*(?:->\s*([A-Za-z_][A-Za-z0-9_.\[\], ]*))?\s*:/,
    );
    if (!match) {
      continue;
    }

    const functionIndent = indentation(match[1]);
    let end = codeLines.length;
    for (let cursor = index + 1; cursor < codeLines.length; cursor += 1) {
      if (
        codeLines[cursor].trim() !== "" &&
        indentation(codeLines[cursor]) <= functionIndent
      ) {
        end = cursor;
        break;
      }
    }

    functions.push({
      name: match[2],
      returnType: match[3]?.trim() ?? "",
      startLine: index + 1,
      lines: codeLines.slice(index + 1, end),
    });
    index = end - 1;
  }

  return functions;
}

function collectReturnDictionaries(functionInfo) {
  const dictionaries = [];

  for (let index = 0; index < functionInfo.lines.length; index += 1) {
    const line = functionInfo.lines[index];
    const returnIndex = line.search(/\breturn\s*\{/);
    if (returnIndex < 0) {
      continue;
    }

    let text = line.slice(returnIndex);
    let depth = 0;
    let quote = null;
    let completed = false;

    for (
      let lineIndex = index;
      lineIndex < functionInfo.lines.length;
      lineIndex += 1
    ) {
      const currentLine =
        lineIndex === index
          ? functionInfo.lines[lineIndex].slice(returnIndex)
          : functionInfo.lines[lineIndex];

      if (lineIndex !== index) {
        text += `\n${currentLine}`;
      }

      for (let characterIndex = 0; characterIndex < currentLine.length; characterIndex += 1) {
        const character = currentLine[characterIndex];
        const next = currentLine[characterIndex + 1] ?? "";

        if (quote) {
          if (character === "\\") {
            characterIndex += next === "" ? 0 : 1;
          } else if (character === quote) {
            quote = null;
          }
          continue;
        }

        if (character === "'" || character === '"') {
          quote = character;
        } else if (character === "{") {
          depth += 1;
        } else if (character === "}") {
          depth -= 1;
          if (depth === 0) {
            completed = true;
            break;
          }
        }
      }

      if (completed) {
        dictionaries.push({
          line: functionInfo.startLine + index + 1,
          text,
        });
        index = lineIndex;
        break;
      }
    }
  }

  return dictionaries;
}

function dictionaryKeys(dictionaryText) {
  return new Set(
    [...dictionaryText.matchAll(/["']([A-Za-z_][A-Za-z0-9_]*)["']\s*:/g)].map(
      (match) => match[1],
    ),
  );
}

function mutatorShapeFindings(content, relativePath) {
  if (path.extname(relativePath).toLowerCase() !== ".gd") {
    return { errors: [], warnings: [] };
  }

  const errors = [];
  const warnings = [];

  for (const functionInfo of findFunctionBodies(content)) {
    const isLikelyMutator =
      MUTATOR_VERBS.test(functionInfo.name) &&
      functionInfo.returnType === "Dictionary";
    if (!isLikelyMutator) {
      continue;
    }

    const dictionaries = collectReturnDictionaries(functionInfo);
    if (dictionaries.length === 0) {
      continue;
    }

    for (const dictionary of dictionaries) {
      const keys = dictionaryKeys(dictionary.text);
      const containsContractKey =
        keys.has("ok") || keys.has("error") || keys.has("state");

      if (!containsContractKey) {
        warnings.push(
          `${relativePath}:${dictionary.line}: ${functionInfo.name} appears to be a mutator but returns a Dictionary without canonical result keys; verify its owner PRD.`,
        );
        continue;
      }

      const missingCore = ["ok", "error", "state"].filter(
        (key) => !keys.has(key),
      );
      const successfulResult =
        /["']ok["']\s*:\s*true\b/.test(dictionary.text);
      const missingLogEntries = successfulResult && !keys.has("log_entries");

      if (missingCore.length > 0 || missingLogEntries) {
        const missing = [
          ...missingCore,
          ...(missingLogEntries ? ["log_entries"] : []),
        ];
        errors.push(
          `${relativePath}:${dictionary.line}: mutator ${functionInfo.name} result is missing canonical keys: ${missing.join(", ")}.`,
        );
      }
    }
  }

  return { errors, warnings };
}

function stringErrorFindings(content, relativePath) {
  if (
    path.extname(relativePath).toLowerCase() !== ".gd" ||
    isUnder(relativePath, "data/ids/") ||
    (!isUnder(relativePath, "logic/") && !isUnder(relativePath, "autoload/"))
  ) {
    return [];
  }

  const findings = [];
  const patterns = [
    /["']error["']\s*:\s*["']([^"']*)["']/g,
    /\[\s*["']error["']\s*\]\s*=\s*["']([^"']*)["']/g,
  ];

  for (const pattern of patterns) {
    for (const match of content.matchAll(pattern)) {
      const line =
        content.slice(0, match.index).split(/\r\n|\n|\r/).length;
      findings.push(
        `${relativePath}:${line}: suspicious string error code "${match[1]}"; use a ValidationErrors constant.`,
      );
    }
  }

  return findings;
}

function addedText(edits) {
  return edits
    .map((edit) =>
      edit && typeof edit.new_string === "string" ? edit.new_string : "",
    )
    .filter(Boolean)
    .join("\n");
}

function stableIdWarnings(content, relativePath, edits) {
  if (
    path.extname(relativePath).toLowerCase() !== ".gd" ||
    isUnder(relativePath, "data/ids/")
  ) {
    return [];
  }

  const candidateText = addedText(edits);
  if (candidateText === "") {
    return [];
  }

  const warnings = [];
  const pattern =
    /^\s*const\s+((?:CARD|ROLE|CONTRACT|CONTACT|STREET_DEAL|AI_PROFILE|TURF_LEVEL|PHASE|ATTACK_MODE|VALIDATION_ERROR|LOG_EVENT)_[A-Z0-9_]+|[A-Z][A-Z0-9_]*(?:_ID|_IDS|_ERROR|_ERRORS))\s*(?::[^=]+)?(?::=|=)\s*["']([A-Za-z0-9_.:-]+)["']/gm;

  for (const match of candidateText.matchAll(pattern)) {
    warnings.push(
      `${relativePath}: new stable-looking constant ${match[1]} = "${match[2]}" was added outside data/ids/; verify ownership in ${IDS_DOCUMENT}.`,
    );
  }

  return warnings;
}

export async function canonicalContractsValidator(context) {
  const relativePath = normalizedRelativePath(
    context.repositoryRoot,
    context.filePath,
  );
  const extension = path.extname(relativePath).toLowerCase();

  if (!TEXT_EXTENSIONS.has(extension)) {
    return createResult(
      STATUS.PASS,
      "Edited file is outside canonical contract checks.",
    );
  }

  let content;
  try {
    content = await readFile(context.filePath, "utf8");
  } catch (error) {
    return createResult(
      STATUS.SKIP,
      `Unable to read changed file for canonical checks: ${error.message}`,
    );
  }

  const errors = [
    ...ambiguityFindings(content, relativePath, context.edits ?? []),
    ...stringErrorFindings(content, relativePath),
  ];
  const shapeFindings = mutatorShapeFindings(content, relativePath);
  errors.push(...shapeFindings.errors);

  const warnings = [
    ...shapeFindings.warnings,
    ...stableIdWarnings(content, relativePath, context.edits ?? []),
  ];

  if (
    isExactPath(relativePath, IDS_DOCUMENT) ||
    isUnder(relativePath, "data/ids/")
  ) {
    warnings.push(
      `${relativePath}: canonical IDs or error contracts changed; review compatibility, owner PRDs, and dependent tests explicitly.`,
    );
  }

  if (errors.length > 0) {
    return createResult(
      STATUS.ERROR,
      `Canonical contract errors found in ${relativePath}.`,
      [
        ...errors,
        ...warnings,
        `If behavior or ownership is unclear, check ${OPEN_QUESTIONS_DOCUMENT}.`,
      ],
    );
  }

  if (warnings.length > 0) {
    return createResult(
      STATUS.WARN,
      `Canonical contract warnings found in ${relativePath}.`,
      [
        ...warnings,
        `Do not infer gameplay rules; check ${OPEN_QUESTIONS_DOCUMENT} when uncertain.`,
      ],
    );
  }

  return createResult(
    STATUS.PASS,
    `Canonical contract checks passed: ${relativePath}.`,
  );
}

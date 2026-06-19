import { readFile } from "node:fs/promises";
import path from "node:path";

import { createResult, STATUS } from "../lib/output.mjs";

const MAX_SOURCE_LINES = 249;
const PASCAL_CASE = /^[A-Z][A-Za-z0-9]*$/;
const OPEN_QUESTION = /\bOQ-[A-Za-z0-9_-]+\b/i;
const AMBIGUITY_MARKER = /\b(?:TODO|TBD|FIXME)\b|\?\?\?/i;

function lineCount(content) {
  if (content === "") {
    return 0;
  }

  const lines = content.split(/\r\n|\n|\r/);
  return /(?:\r\n|\n|\r)$/.test(content) ? lines.length - 1 : lines.length;
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
        state = "code";
        result += " ";
      } else {
        result += character === "\n" || character === "\r" ? character : " ";
      }
      continue;
    }

    if (state === "triple_string") {
      if (character === quote && next === quote && third === quote) {
        state = "code";
        result += "   ";
        index += 2;
      } else {
        result += character === "\n" || character === "\r" ? character : " ";
      }
      continue;
    }

    if (character === "#") {
      state = "comment";
      result += " ";
      continue;
    }

    if (character === "'" || character === '"') {
      quote = character;
      if (next === character && third === character) {
        state = "triple_string";
        result += "   ";
        index += 2;
      } else {
        state = "string";
        result += " ";
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

function findClassNames(code) {
  const declarations = [];
  const pattern = /^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)\b/gm;

  for (const match of code.matchAll(pattern)) {
    declarations.push({
      name: match[1],
      line: lineNumberAt(code, match.index),
    });
  }

  return declarations;
}

function splitTopLevelParameters(parameters) {
  const parts = [];
  let current = "";
  let squareDepth = 0;
  let roundDepth = 0;
  let curlyDepth = 0;

  for (const character of parameters) {
    if (character === "[") squareDepth += 1;
    if (character === "]") squareDepth = Math.max(0, squareDepth - 1);
    if (character === "(") roundDepth += 1;
    if (character === ")") roundDepth = Math.max(0, roundDepth - 1);
    if (character === "{") curlyDepth += 1;
    if (character === "}") curlyDepth = Math.max(0, curlyDepth - 1);

    if (
      character === "," &&
      squareDepth === 0 &&
      roundDepth === 0 &&
      curlyDepth === 0
    ) {
      parts.push(current.trim());
      current = "";
    } else {
      current += character;
    }
  }

  if (current.trim() !== "") {
    parts.push(current.trim());
  }

  return parts;
}

function hasParameterType(parameter) {
  const declaration = parameter.split("=", 1)[0].trim();
  return declaration === "" || declaration.includes(":");
}

function findUntypedPublicFunctions(code) {
  const findings = [];
  const pattern =
    /^\s*(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([\s\S]*?)\)\s*(?:->\s*([A-Za-z_][A-Za-z0-9_.[\], ]*))?\s*:/gm;

  for (const match of code.matchAll(pattern)) {
    const functionName = match[1];
    if (functionName.startsWith("_")) {
      continue;
    }

    const parameters = splitTopLevelParameters(match[2]);
    const untypedParameters = parameters
      .filter((parameter) => !hasParameterType(parameter))
      .map((parameter) => parameter.split("=", 1)[0].trim())
      .filter(Boolean);
    const missingReturnType = !match[3];

    if (untypedParameters.length > 0 || missingReturnType) {
      const reasons = [];
      if (untypedParameters.length > 0) {
        reasons.push(`untyped parameters: ${untypedParameters.join(", ")}`);
      }
      if (missingReturnType) {
        reasons.push("missing return type");
      }

      findings.push({
        line: lineNumberAt(code, match.index),
        name: functionName,
        reason: reasons.join("; "),
      });
    }
  }

  return findings;
}

function findUntrackedAmbiguityMarkers(content) {
  const findings = [];
  const lines = content.split(/\r\n|\n|\r/);

  for (let index = 0; index < lines.length; index += 1) {
    const nearbyLines = lines.slice(
      Math.max(0, index - 1),
      Math.min(lines.length, index + 2),
    );
    if (
      AMBIGUITY_MARKER.test(lines[index]) &&
      !nearbyLines.some((line) => OPEN_QUESTION.test(line))
    ) {
      findings.push(index + 1);
    }
  }

  return findings;
}

function findDebugStatements(code) {
  const findings = [];
  const lines = code.split(/\r\n|\n|\r/);

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const statements = [];

    if (/\bprint\s*\(/.test(line)) statements.push("print()");
    if (/\bpush_error\s*\(/.test(line)) statements.push("push_error()");
    if (/^\s*breakpoint\s*$/.test(line)) statements.push("breakpoint");

    if (statements.length > 0) {
      findings.push({
        line: index + 1,
        statements,
      });
    }
  }

  return findings;
}

function relativeDisplayPath(repositoryRoot, filePath) {
  const relative = path.relative(repositoryRoot, filePath);
  return relative === "" ? path.basename(filePath) : relative.split(path.sep).join("/");
}

export async function gdscriptQualityValidator(context) {
  if (path.extname(context.filePath).toLowerCase() !== ".gd") {
    return createResult(STATUS.PASS, "Edited file is not GDScript.");
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

  const displayPath = relativeDisplayPath(
    context.repositoryRoot,
    context.filePath,
  );
  const errors = [];
  const warnings = [];
  const totalLines = lineCount(content);
  const code = maskStringsAndComments(content);
  const classNames = findClassNames(code);

  if (totalLines > MAX_SOURCE_LINES) {
    errors.push(
      `${displayPath}: ${totalLines} lines; source files must be shorter than 250 lines.`,
    );
  }

  if (classNames.length > 1) {
    errors.push(
      `${displayPath}: multiple class_name declarations at lines ${classNames
        .map((declaration) => declaration.line)
        .join(", ")}.`,
    );
  }

  for (const declaration of classNames) {
    if (!PASCAL_CASE.test(declaration.name)) {
      errors.push(
        `${displayPath}:${declaration.line}: class_name ${declaration.name} is not PascalCase.`,
      );
    }
  }

  const ambiguityLines = findUntrackedAmbiguityMarkers(content);
  for (const line of ambiguityLines) {
    errors.push(
      `${displayPath}:${line}: TODO/TBD/FIXME/??? requires an OQ-* reference on the same or adjacent line.`,
    );
  }

  if (content !== "" && !content.endsWith("\n")) {
    errors.push(`${displayPath}: file must end with a newline.`);
  }

  const untypedFunctions = findUntypedPublicFunctions(code);
  for (const finding of untypedFunctions) {
    warnings.push(
      `${displayPath}:${finding.line}: public function ${finding.name} may be insufficiently typed (${finding.reason}).`,
    );
  }

  const debugStatements = findDebugStatements(code);
  for (const finding of debugStatements) {
    warnings.push(
      `${displayPath}:${finding.line}: temporary debug statement detected: ${finding.statements.join(", ")}.`,
    );
  }

  if (errors.length > 0) {
    return createResult(
      STATUS.ERROR,
      `GDScript quality errors found in ${displayPath}.`,
      [...errors, ...warnings],
    );
  }

  if (warnings.length > 0) {
    return createResult(
      STATUS.WARN,
      `GDScript quality warnings found in ${displayPath}.`,
      warnings,
    );
  }

  return createResult(STATUS.PASS, `GDScript quality checks passed: ${displayPath}.`);
}

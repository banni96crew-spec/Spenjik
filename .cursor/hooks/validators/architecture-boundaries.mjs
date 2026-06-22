import { readFile } from "node:fs/promises";
import path from "node:path";

import { createResult, STATUS } from "../lib/output.mjs";

const ARCHITECTURE_DOCUMENT = "docs/prd/15_GODOT_ARCHITECTURE.md";
const LOGIC_UI_TYPES =
  /\b(?:Node|Node2D|Node3D|Control|Button|Label|TextureRect|Panel|PanelContainer)\b/;
const SCENE_TREE_ACCESS =
  /\b(?:get_tree|get_node|get_node_or_null|find_child|find_children)\s*\(|\$(?:[A-Za-z_%])/;
const LOW_LEVEL_GAMEPLAY_MODULE =
  /\b(?:GameStateFactory|GameStateValidator|GamePhaseController|WinnerResolver|IncomeLogic|MarketLogic|PriceLogic|PurchaseValidator|PurchaseResolver|CombatEngine|AttackValidator|DefenseResolver|CombatLogBuilder|RoleLogic|ContractLogic|StreetDealLogic|DebtLogic|ContactLogic|TurfLevelLogic|AIBotController|AIPurchaseLogic|AITargetLogic|AIFallbackLogic|AIActionLogic|SeededRandom|SeededPicker)\s*\.\s*[A-Za-z_][A-Za-z0-9_]*\s*\(/;

function normalizedRelativePath(repositoryRoot, filePath) {
  return path.relative(repositoryRoot, filePath).split(path.sep).join("/");
}

function isUnder(relativePath, directory) {
  const left = process.platform === "win32" ? relativePath.toLowerCase() : relativePath;
  const right = process.platform === "win32" ? directory.toLowerCase() : directory;
  return left.startsWith(right);
}

function analyzeLexicalContext(content) {
  const codeMask = [];
  const codePositions = [];
  let state = "code";
  let quote = "";

  for (let index = 0; index < content.length; index += 1) {
    const character = content[index];
    const next = content[index + 1] ?? "";
    const third = content[index + 2] ?? "";

    if (state === "comment") {
      codePositions[index] = false;
      if (character === "\n" || character === "\r") {
        state = "code";
        codeMask[index] = character;
      } else {
        codeMask[index] = " ";
      }
      continue;
    }

    if (state === "string") {
      codePositions[index] = false;
      codeMask[index] =
        character === "\n" || character === "\r" ? character : " ";

      if (character === "\\") {
        if (next !== "") {
          codePositions[index + 1] = false;
          codeMask[index + 1] =
            next === "\n" || next === "\r" ? next : " ";
          index += 1;
        }
      } else if (character === quote) {
        state = "code";
      }
      continue;
    }

    if (state === "triple_string") {
      codePositions[index] = false;
      codeMask[index] =
        character === "\n" || character === "\r" ? character : " ";

      if (character === quote && next === quote && third === quote) {
        codePositions[index + 1] = false;
        codePositions[index + 2] = false;
        codeMask[index + 1] = " ";
        codeMask[index + 2] = " ";
        index += 2;
        state = "code";
      }
      continue;
    }

    if (character === "#") {
      codePositions[index] = false;
      codeMask[index] = " ";
      state = "comment";
      continue;
    }

    if (character === "'" || character === '"') {
      codePositions[index] = false;
      codeMask[index] = " ";
      quote = character;

      if (next === character && third === character) {
        codePositions[index + 1] = false;
        codePositions[index + 2] = false;
        codeMask[index + 1] = " ";
        codeMask[index + 2] = " ";
        index += 2;
        state = "triple_string";
      } else {
        state = "string";
      }
      continue;
    }

    codePositions[index] = true;
    codeMask[index] = character;
  }

  return {
    codeMask: codeMask.join(""),
    codePositions,
  };
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

function matchesInCode(content, codePositions, pattern) {
  const findings = [];
  for (const match of content.matchAll(pattern)) {
    if (codePositions[match.index]) {
      findings.push(match);
    }
  }
  return findings;
}

function addFinding(findings, seen, filePath, line, boundary, evidence) {
  const key = `${line}:${boundary}:${evidence}`;
  if (seen.has(key)) {
    return;
  }

  seen.add(key);
  findings.push(
    `${filePath}:${line}: ${boundary}; found ${evidence}. See ${ARCHITECTURE_DOCUMENT}.`,
  );
}

function inspectLogic(
  content,
  codeMask,
  codePositions,
  relativePath,
  findings,
  seen,
) {
  const uiImports = matchesInCode(
    content,
    codePositions,
    /\b(?:preload|load)\s*\(\s*["']res:\/\/scenes\/ui\/[^"']*["']\s*\)/gi,
  );
  for (const match of uiImports) {
    addFinding(
      findings,
      seen,
      relativePath,
      lineNumberAt(content, match.index),
      "logic -> UI dependency is forbidden",
      match[0].trim(),
    );
  }

  for (const match of codeMask.matchAll(/\bGameStateManager\b/g)) {
    const boundary = isUnder(relativePath, "logic/ai/")
      ? "AI logic must use owner validators/resolvers and must not call GameStateManager"
      : "logic -> GameStateManager facade dependency is forbidden";
    addFinding(
      findings,
      seen,
      relativePath,
      lineNumberAt(codeMask, match.index),
      boundary,
      "GameStateManager",
    );
  }

  const lines = codeMask.split(/\r\n|\n|\r/);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const typeMatch = line.match(LOGIC_UI_TYPES);
    if (typeMatch) {
      addFinding(
        findings,
        seen,
        relativePath,
        index + 1,
        "logic modules must be non-Node and independent of UI types",
        typeMatch[0],
      );
    }

    const sceneTreeMatch = line.match(SCENE_TREE_ACCESS);
    if (sceneTreeMatch) {
      addFinding(
        findings,
        seen,
        relativePath,
        index + 1,
        "logic modules must not depend on the scene tree",
        sceneTreeMatch[0],
      );
    }
  }
}

function inspectResourceSchema(
  content,
  codePositions,
  relativePath,
  findings,
  seen,
) {
  const runtimeImports = matchesInCode(
    content,
    codePositions,
    /\b(?:preload|load)\s*\(\s*["']res:\/\/(?:logic|autoload)\/[^"']*["']\s*\)/gi,
  );

  for (const match of runtimeImports) {
    addFinding(
      findings,
      seen,
      relativePath,
      lineNumberAt(content, match.index),
      "Resource schema -> runtime logic dependency is forbidden",
      match[0].trim(),
    );
  }
}

function inspectUi(
  content,
  codeMask,
  codePositions,
  relativePath,
  findings,
  seen,
) {
  const directFacadeMutations = matchesInCode(
    content,
    codePositions,
    /\bGameStateManager\s*\.\s*state\s*(?:\[[^\n;]+?\]\s*(?:=|\+=|-=|\*=|\/=)|\[[^\n;]+?\]\s*\.\s*(?:append|erase|clear|assign|merge|push_back|pop_back)\s*\()/gi,
  );
  for (const match of directFacadeMutations) {
    addFinding(
      findings,
      seen,
      relativePath,
      lineNumberAt(content, match.index),
      "UI -> active gameplay state mutation is forbidden",
      match[0].trim(),
    );
  }

  const gameplayFieldMutations = matchesInCode(
    content,
    codePositions,
    /\b(?:player|state|working_state)\s*\[\s*["'](?:nal|vp|hand|purchased_this_round|combat_log|phase|contracts|contacts|debts)["']\s*\]\s*(?:=|\+=|-=|\*=|\/=|\.\s*(?:append|erase|clear|assign|merge|push_back|pop_back)\s*\()/gi,
  );
  for (const match of gameplayFieldMutations) {
    addFinding(
      findings,
      seen,
      relativePath,
      lineNumberAt(content, match.index),
      "UI-owned gameplay state mutation is forbidden",
      match[0].trim(),
    );
  }

  const logicImports = matchesInCode(
    content,
    codePositions,
    /\b(?:preload|load)\s*\(\s*["']res:\/\/logic\/[^"']*["']\s*\)/gi,
  );
  for (const match of logicImports) {
    addFinding(
      findings,
      seen,
      relativePath,
      lineNumberAt(content, match.index),
      "UI -> low-level logic dependency bypasses GameStateManager",
      match[0].trim(),
    );
  }

  const lines = codeMask.split(/\r\n|\n|\r/);
  for (let index = 0; index < lines.length; index += 1) {
    const moduleCall = lines[index].match(LOW_LEVEL_GAMEPLAY_MODULE);
    if (moduleCall) {
      addFinding(
        findings,
        seen,
        relativePath,
        index + 1,
        "gameplay logic inside UI is forbidden; UI must call GameStateManager",
        moduleCall[0].trim(),
      );
    }
  }
}

export async function architectureBoundariesValidator(context) {
  if (path.extname(context.filePath).toLowerCase() !== ".gd") {
    return createResult(STATUS.PASS, "Edited file is not GDScript.");
  }

  const relativePath = normalizedRelativePath(
    context.repositoryRoot,
    context.filePath,
  );
  const isLogic = isUnder(relativePath, "logic/");
  const isUi =
    isUnder(relativePath, "scenes/ui/") ||
    isUnder(relativePath, "scenes/game/") ||
    isUnder(relativePath, "scenes/main/");
  const isResourceSchema =
    isUnder(relativePath, "data/resources/") ||
    isUnder(relativePath, "resources/");

  if (!isLogic && !isUi && !isResourceSchema) {
    return createResult(
      STATUS.PASS,
      "Edited GDScript file is outside checked architecture boundaries.",
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

  const { codeMask, codePositions } = analyzeLexicalContext(content);
  const findings = [];
  const seen = new Set();

  if (isLogic) {
    inspectLogic(
      content,
      codeMask,
      codePositions,
      relativePath,
      findings,
      seen,
    );
  }
  if (isResourceSchema) {
    inspectResourceSchema(
      content,
      codePositions,
      relativePath,
      findings,
      seen,
    );
  }
  if (isUi) {
    inspectUi(
      content,
      codeMask,
      codePositions,
      relativePath,
      findings,
      seen,
    );
  }

  if (findings.length === 0) {
    return createResult(
      STATUS.PASS,
      `Architecture boundary checks passed: ${relativePath}.`,
    );
  }

  return createResult(
    STATUS.ERROR,
    `Architecture boundary violations found in ${relativePath}.`,
    findings,
  );
}

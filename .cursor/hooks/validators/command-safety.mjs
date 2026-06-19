import os from "node:os";
import path from "node:path";

import { createResult, STATUS } from "../lib/output.mjs";
import { isPathInside, normalizePath } from "../lib/repository.mjs";

const SHELL_OPERATORS = new Set([";", "&&", "||", "|", "(", ")", "\n"]);
const REDIRECTION_OPERATORS = new Set([">", ">>", "1>", "1>>", "2>", "2>>", "*>", "*>>"]);
const SHELL_LAUNCHERS = new Set([
  "bash",
  "bash.exe",
  "cmd",
  "cmd.exe",
  "pwsh",
  "pwsh.exe",
  "sh",
  "sh.exe",
  "powershell",
  "powershell.exe",
]);
const DELETE_COMMANDS = new Set([
  "del",
  "erase",
  "rd",
  "rmdir",
  "rm",
  "remove-item",
]);
const COPY_MOVE_COMMANDS = new Set([
  "copy",
  "copy-item",
  "cp",
  "move",
  "move-item",
  "mv",
]);
const CREATE_COMMANDS = new Set([
  "md",
  "mkdir",
  "new-item",
  "ni",
  "touch",
]);
const CONTENT_COMMANDS = new Set([
  "add-content",
  "out-file",
  "set-content",
  "tee-object",
]);
const DANGEROUS_APPROVAL_FLAGS = new Set([
  "--always-approve",
  "--dangerously-bypass-approvals-and-sandbox",
  "--dangerously-skip-permissions",
  "--yolo",
]);

function commandName(token = "") {
  return token.replace(/^&$/, "").replaceAll("\\", "/").split("/").at(-1).toLowerCase();
}

function lowerTokens(tokens) {
  return tokens.map((token) => token.toLowerCase());
}

function flushToken(tokens, current) {
  if (current.value !== "") {
    tokens.push(current.value);
    current.value = "";
  }
}

export function tokenizeShell(command) {
  const tokens = [];
  const current = { value: "" };
  let quote = null;

  for (let index = 0; index < command.length; index += 1) {
    const character = command[index];
    const next = command[index + 1] ?? "";

    if (quote === "'") {
      if (character === "'" && next === "'") {
        current.value += "'";
        index += 1;
      } else if (character === "'") {
        quote = null;
      } else {
        current.value += character;
      }
      continue;
    }

    if (quote === '"') {
      if (character === '"' ) {
        quote = null;
      } else if (character === "`" && next !== "") {
        current.value += next;
        index += 1;
      } else if (character === "\\" && ['"', "\\"].includes(next)) {
        current.value += next;
        index += 1;
      } else {
        current.value += character;
      }
      continue;
    }

    if (character === "'" || character === '"') {
      quote = character;
      continue;
    }

    if (
      character === "\\" &&
      next !== "" &&
      (/[\s'"\\]/.test(next) || [";", "|", "&", ">"].includes(next))
    ) {
      current.value += next;
      index += 1;
      continue;
    }

    if (character === "`" && next !== "") {
      current.value += next;
      index += 1;
      continue;
    }

    if (character === "\r") {
      continue;
    }

    if (character === "\n") {
      flushToken(tokens, current);
      tokens.push("\n");
      continue;
    }

    if (/\s/.test(character)) {
      flushToken(tokens, current);
      continue;
    }

    if (character === "&" && next === "&") {
      flushToken(tokens, current);
      tokens.push("&&");
      index += 1;
      continue;
    }

    if (character === "|" && next === "|") {
      flushToken(tokens, current);
      tokens.push("||");
      index += 1;
      continue;
    }

    if (character === ";" || character === "|") {
      flushToken(tokens, current);
      tokens.push(character);
      continue;
    }

    if (character === "(" || character === ")") {
      flushToken(tokens, current);
      tokens.push(character);
      continue;
    }

    if (character === ">") {
      let operator = ">";
      if (/^[12*]$/.test(current.value)) {
        operator = `${current.value}>`;
        current.value = "";
      } else {
        flushToken(tokens, current);
      }
      if (next === ">") {
        operator += ">";
        index += 1;
      }
      tokens.push(operator);
      continue;
    }

    current.value += character;
  }

  flushToken(tokens, current);
  return tokens;
}

function splitSegments(tokens) {
  const segments = [];
  let segment = [];

  for (const token of tokens) {
    if (SHELL_OPERATORS.has(token)) {
      if (segment.length > 0) {
        segments.push(segment);
        segment = [];
      }
    } else {
      segment.push(token);
    }
  }

  if (segment.length > 0) {
    segments.push(segment);
  }

  return segments;
}

function findCommandIndex(tokens, names) {
  return tokens.findIndex((token) => names.has(commandName(token)));
}

function findGitInvocation(tokens) {
  const gitIndex = tokens.findIndex((token) => ["git", "git.exe"].includes(commandName(token)));
  if (gitIndex < 0) {
    return null;
  }

  const args = tokens.slice(gitIndex + 1);
  let subcommandIndex = 0;

  while (subcommandIndex < args.length) {
    const token = args[subcommandIndex].toLowerCase();
    if (["-c", "-C", "--git-dir", "--work-tree", "--namespace"].includes(args[subcommandIndex])) {
      subcommandIndex += 2;
    } else if (token.startsWith("--git-dir=") || token.startsWith("--work-tree=")) {
      subcommandIndex += 1;
    } else if (token.startsWith("-")) {
      subcommandIndex += 1;
    } else {
      break;
    }
  }

  if (subcommandIndex >= args.length) {
    return null;
  }

  return {
    subcommand: args[subcommandIndex].toLowerCase(),
    args: args.slice(subcommandIndex + 1),
  };
}

function hasShortFlag(tokens, flag) {
  return tokens.some((token) => {
    if (!/^-[^-]/.test(token)) {
      return false;
    }
    return token.slice(1).toLowerCase().includes(flag.toLowerCase());
  });
}

function checkGit(tokens) {
  const invocation = findGitInvocation(tokens);
  if (!invocation) {
    return null;
  }

  const args = lowerTokens(invocation.args);
  if (
    invocation.subcommand === "reset" &&
    args.some((token) => token === "--hard" || token.startsWith("--hard="))
  ) {
    return "git reset --hard discards working-tree and index changes";
  }

  if (
    invocation.subcommand === "clean" &&
    !hasShortFlag(invocation.args, "n") &&
    !args.includes("--dry-run") &&
    (hasShortFlag(invocation.args, "f") || args.includes("--force")) &&
    (hasShortFlag(invocation.args, "d") ||
      args.includes("--dirs") ||
      args.includes("--directories"))
  ) {
    return "git clean with force and directory removal deletes untracked files";
  }

  if (invocation.subcommand === "checkout") {
    const separatorIndex = invocation.args.indexOf("--");
    if (separatorIndex >= 0 && separatorIndex < invocation.args.length - 1) {
      return "git checkout -- <files> discards working-tree changes";
    }
  }

  if (invocation.subcommand === "restore") {
    const stagedOnly = args.includes("--staged") && !args.includes("--worktree");
    const pathArgs = invocation.args.filter(
      (token) => token !== "--" && !token.startsWith("-"),
    );
    if (!stagedOnly && pathArgs.length > 0) {
      return "git restore targets the working tree and can discard user changes";
    }
  }

  if (
    invocation.subcommand === "push" &&
    (hasShortFlag(invocation.args, "f") ||
      invocation.args.some((token) => {
        const lower = token.toLowerCase();
        return (
          lower === "--force" ||
          lower.startsWith("--force=") ||
          lower === "--force-with-lease" ||
          lower.startsWith("--force-with-lease=") ||
          lower === "--force-if-includes"
        );
      }))
  ) {
    return "force push can overwrite remote history";
  }

  return null;
}

function checkApprovalBypass(tokens) {
  const optionBoundary = tokens.indexOf("--");
  const optionTokens = optionBoundary >= 0 ? tokens.slice(0, optionBoundary) : tokens;

  for (const token of optionTokens) {
    const lower = token.toLowerCase();
    if (
      DANGEROUS_APPROVAL_FLAGS.has(lower) ||
      (/^--/.test(lower) &&
        ((lower.includes("bypass") && lower.includes("approval")) ||
          lower.includes("always-approve")))
    ) {
      return `approval or sandbox bypass flag detected: ${token}`;
    }
  }

  return null;
}

function isStaticPath(candidate) {
  return (
    typeof candidate === "string" &&
    candidate !== "" &&
    candidate !== "-" &&
    !candidate.startsWith("-") &&
    !/[$%*?{}[\]`]/.test(candidate) &&
    !candidate.includes("://")
  );
}

function resolveCommandPath(candidate, cwd) {
  if (typeof candidate !== "string" || candidate === "") {
    return null;
  }

  let expanded = candidate;
  const environmentMatch =
    expanded.match(/^\$env:([A-Za-z_][A-Za-z0-9_]*)(.*)$/i) ??
    expanded.match(/^\$\{([A-Za-z_][A-Za-z0-9_]*)\}(.*)$/) ??
    expanded.match(/^%([A-Za-z_][A-Za-z0-9_]*)%(.*)$/);
  const simpleEnvironmentMatch = expanded.match(
    /^\$(PWD|HOME|USERPROFILE)(.*)$/i,
  );
  const variableMatch = environmentMatch ?? simpleEnvironmentMatch;

  if (variableMatch) {
    const variableName = variableMatch[1];
    const suffix = variableMatch[2] ?? "";
    const environmentKey = Object.keys(process.env).find(
      (key) => key.toLowerCase() === variableName.toLowerCase(),
    );
    const environmentValue =
      variableName.toLowerCase() === "pwd"
        ? cwd
        : environmentKey
          ? process.env[environmentKey]
          : null;
    if (!environmentValue) {
      return null;
    }
    expanded = `${environmentValue}${suffix}`;
  } else if (expanded === "~") {
    expanded = os.homedir();
  } else if (expanded.startsWith(`~${path.sep}`) || expanded.startsWith("~/")) {
    expanded = path.join(os.homedir(), expanded.slice(2));
  }

  if (!isStaticPath(expanded)) {
    return null;
  }

  return normalizePath(expanded, cwd);
}

function pathTargetsGitDirectory(candidate, cwd, repositoryRoot) {
  const rawSegments = candidate.replaceAll("\\", "/").split("/");
  if (
    rawSegments.some(
      (segment) =>
        segment.toLowerCase() === ".git" || /^\.git[*?]/i.test(segment),
    )
  ) {
    return true;
  }

  const resolved = resolveCommandPath(candidate, cwd);
  if (!resolved) {
    return false;
  }

  const relative = path.relative(repositoryRoot, resolved);
  return relative.split(path.sep).some((part) => part.toLowerCase() === ".git");
}

function optionValue(tokens, names) {
  const lowerNames = names.map((name) => name.toLowerCase());

  for (let index = 0; index < tokens.length; index += 1) {
    const token = tokens[index];
    const lower = token.toLowerCase();
    if (lowerNames.includes(lower)) {
      return tokens[index + 1] ?? null;
    }

    for (const name of lowerNames) {
      if (lower.startsWith(`${name}=`) || lower.startsWith(`${name}:`)) {
        return token.slice(name.length + 1);
      }
    }
  }

  return null;
}

function positionalArguments(tokens, commandIndex) {
  const values = [];
  for (let index = commandIndex + 1; index < tokens.length; index += 1) {
    const token = tokens[index];
    if (REDIRECTION_OPERATORS.has(token)) {
      index += 1;
    } else if (!token.startsWith("-") && !/^\/[a-z]+$/i.test(token)) {
      values.push(token);
    }
  }
  return values;
}

function checkDeletion(tokens, cwd, repositoryRoot) {
  const commandIndex = findCommandIndex(tokens, DELETE_COMMANDS);
  if (commandIndex < 0) {
    return null;
  }

  const command = commandName(tokens[commandIndex]);
  const args = tokens.slice(commandIndex + 1);
  const lower = lowerTokens(args);
  const recursive =
    hasShortFlag(args, "r") ||
    lower.includes("--recursive") ||
    lower.includes("-recurse") ||
    ((command === "rd" || command === "rmdir") &&
      (lower.includes("/s") || lower.includes("-s")));

  const namedPath = optionValue(args, ["-path", "-literalpath"]);
  const explicitPaths = namedPath
    ? [namedPath]
    : positionalArguments(tokens, commandIndex);

  if (explicitPaths.length === 0) {
    return null;
  }

  const gitPath = explicitPaths.find((candidate) =>
    pathTargetsGitDirectory(candidate, cwd, repositoryRoot),
  );
  if (gitPath) {
    return `command attempts to delete .git: ${gitPath}`;
  }

  if (!recursive) {
    return null;
  }

  for (const explicitPath of explicitPaths) {
    const resolved = resolveCommandPath(explicitPath, cwd);
    if (!resolved) {
      continue;
    }

    if (path.resolve(resolved) === path.resolve(repositoryRoot)) {
      return `recursive deletion targets the repository root: ${explicitPath}`;
    }

    if (!isPathInside(repositoryRoot, resolved)) {
      return `recursive deletion targets a directory outside the repository: ${explicitPath}`;
    }
  }

  return null;
}

function outsideRepository(candidate, cwd, repositoryRoot) {
  if (
    typeof candidate === "string" &&
    ["/dev/null", "nul", "\\\\.\\nul"].includes(candidate.toLowerCase())
  ) {
    return false;
  }

  const resolved = resolveCommandPath(candidate, cwd);
  return resolved ? !isPathInside(repositoryRoot, resolved) : false;
}

function checkRedirections(tokens, cwd, repositoryRoot) {
  for (let index = 0; index < tokens.length - 1; index += 1) {
    if (
      REDIRECTION_OPERATORS.has(tokens[index]) &&
      outsideRepository(tokens[index + 1], cwd, repositoryRoot)
    ) {
      return `output redirection writes outside the repository: ${tokens[index + 1]}`;
    }
  }

  return null;
}

function checkExplicitWrites(tokens, cwd, repositoryRoot) {
  const contentIndex = findCommandIndex(tokens, CONTENT_COMMANDS);
  if (contentIndex >= 0) {
    const args = tokens.slice(contentIndex + 1);
    const destination =
      optionValue(args, ["-path", "-literalpath", "-filepath"]) ??
      positionalArguments(tokens, contentIndex)[0];
    if (outsideRepository(destination, cwd, repositoryRoot)) {
      return `${commandName(tokens[contentIndex])} writes outside the repository: ${destination}`;
    }
  }

  const copyMoveIndex = findCommandIndex(tokens, COPY_MOVE_COMMANDS);
  if (copyMoveIndex >= 0) {
    const args = tokens.slice(copyMoveIndex + 1);
    const destination =
      optionValue(args, ["-destination"]) ??
      positionalArguments(tokens, copyMoveIndex).at(-1);
    if (outsideRepository(destination, cwd, repositoryRoot)) {
      return `${commandName(tokens[copyMoveIndex])} writes outside the repository: ${destination}`;
    }
  }

  const createIndex = findCommandIndex(tokens, CREATE_COMMANDS);
  if (createIndex >= 0) {
    const args = tokens.slice(createIndex + 1);
    const destinations = optionValue(args, ["-path"]) 
      ? [optionValue(args, ["-path"])]
      : positionalArguments(tokens, createIndex);
    const outside = destinations.find((candidate) =>
      outsideRepository(candidate, cwd, repositoryRoot),
    );
    if (outside) {
      return `${commandName(tokens[createIndex])} creates outside the repository: ${outside}`;
    }
  }

  return null;
}

function nestedShellCommands(tokens) {
  const nested = [];

  for (let index = 0; index < tokens.length; index += 1) {
    const launcher = commandName(tokens[index]);
    if (!SHELL_LAUNCHERS.has(launcher)) {
      continue;
    }

    const commandFlags =
      launcher.startsWith("cmd") ? ["/c", "/k"] : ["-c", "-command"];
    const flagIndex = tokens
      .slice(index + 1)
      .findIndex((token) => commandFlags.includes(token.toLowerCase()));

    if (flagIndex >= 0) {
      const valueIndex = index + 1 + flagIndex + 1;
      if (tokens[valueIndex]) {
        nested.push(tokens.slice(valueIndex).join(" "));
      }
    }
  }

  return nested;
}

function inspectCommand(command, context, depth = 0) {
  const tokens = tokenizeShell(command);
  const cwd = normalizePath(context.cwd, context.repositoryRoot) ?? context.repositoryRoot;

  for (const segment of splitSegments(tokens)) {
    const checks = [
      checkApprovalBypass(segment),
      checkGit(segment),
      checkDeletion(segment, cwd, context.repositoryRoot),
      checkRedirections(segment, cwd, context.repositoryRoot),
      checkExplicitWrites(segment, cwd, context.repositoryRoot),
    ];
    const violation = checks.find(Boolean);
    if (violation) {
      return violation;
    }
  }

  if (depth < 2) {
    for (const nestedCommand of nestedShellCommands(tokens)) {
      const violation = inspectCommand(nestedCommand, context, depth + 1);
      if (violation) {
        return `nested shell command: ${violation}`;
      }
    }
  }

  return null;
}

export function commandSafetyValidator(context) {
  if (typeof context.command !== "string" || context.command.trim() === "") {
    return createResult(STATUS.SKIP, "Shell command is missing.");
  }

  const violation = inspectCommand(context.command, context);
  if (violation) {
    return createResult(STATUS.BLOCK, `Blocked dangerous operation: ${violation}.`);
  }

  return createResult(STATUS.PASS, "Command safety checks passed.");
}

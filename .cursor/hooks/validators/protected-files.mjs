import path from "node:path";

import { createResult, STATUS } from "../lib/output.mjs";
import { isPathInside } from "../lib/repository.mjs";

const PROTECTED_AREAS = Object.freeze([
  {
    path: "addons/gut/",
    directory: true,
    message:
      "GUT internals must not be changed without a separate task for installing, updating, or modifying GUT.",
  },
  {
    path: "docs/prd/",
    directory: true,
    message:
      "docs/prd is the project source of truth; verify the owner PRD and dependent contracts.",
  },
  {
    path: "data/ids/",
    directory: true,
    message:
      "data/ids contains stable IDs and error contracts; changes can break compatibility and saved references.",
  },
  {
    path: "project.godot",
    directory: false,
    message:
      "project.godot affects Godot configuration, plugins, Autoloads, input mappings, and runtime behavior.",
  },
  {
    path: "AGENTS.MD",
    directory: false,
    message:
      "AGENTS.MD defines repository-wide instructions for Cursor and Codex agents.",
  },
  {
    path: ".cursor/docs/coding-standards.md",
    directory: false,
    message:
      ".cursor/docs/coding-standards.md defines project-wide implementation and verification rules.",
  },
  {
    path: ".cursor/docs/technical-preferences.md",
    directory: false,
    message:
      ".cursor/docs/technical-preferences.md records approved stack and architecture decisions.",
  },
]);

function comparisonPath(value) {
  return process.platform === "win32" ? value.toLowerCase() : value;
}

function repositoryRelativePath(repositoryRoot, filePath) {
  if (!isPathInside(repositoryRoot, filePath)) {
    return null;
  }

  return path.relative(repositoryRoot, filePath).split(path.sep).join("/");
}

function findProtectedArea(relativePath) {
  const comparablePath = comparisonPath(relativePath);

  return PROTECTED_AREAS.find((area) => {
    const protectedPath = comparisonPath(area.path);
    return area.directory
      ? comparablePath.startsWith(protectedPath)
      : comparablePath === protectedPath;
  });
}

export function protectedFilesValidator(context) {
  const relativePath = repositoryRelativePath(
    context.repositoryRoot,
    context.filePath,
  );

  if (!relativePath) {
    return createResult(STATUS.SKIP, "Edited file is outside the repository.");
  }

  const area = findProtectedArea(relativePath);
  if (!area) {
    return createResult(STATUS.PASS, "Edited file is not protected.");
  }

  return createResult(
    STATUS.WARN,
    `Protected file changed: ${relativePath}.`,
    [area.message, "Review the change scope; no files were reverted or blocked."],
  );
}

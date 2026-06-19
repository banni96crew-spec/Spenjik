import { access } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HOOKS_DIRECTORY = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT_REPOSITORY_CANDIDATE = path.resolve(
  HOOKS_DIRECTORY,
  "..",
  "..",
  "..",
);

async function exists(candidate) {
  try {
    await access(candidate);
    return true;
  } catch {
    return false;
  }
}

function uniquePaths(paths) {
  const seen = new Set();
  const result = [];

  for (const candidate of paths) {
    if (typeof candidate !== "string" || candidate.trim() === "") {
      continue;
    }

    const normalized = path.resolve(candidate);
    const key =
      process.platform === "win32" ? normalized.toLowerCase() : normalized;

    if (!seen.has(key)) {
      seen.add(key);
      result.push(normalized);
    }
  }

  return result;
}

async function findRootFrom(startPath) {
  let current = path.resolve(startPath);

  while (true) {
    if (await exists(path.join(current, ".cursor", "hooks.json"))) {
      return current;
    }

    const parent = path.dirname(current);
    if (parent === current) {
      return null;
    }

    current = parent;
  }
}

export function normalizePath(candidate, basePath = process.cwd()) {
  if (typeof candidate !== "string" || candidate.trim() === "") {
    return null;
  }

  return path.normalize(
    path.isAbsolute(candidate)
      ? path.resolve(candidate)
      : path.resolve(basePath, candidate),
  );
}

export function isPathInside(repositoryRoot, candidate) {
  const root = normalizePath(repositoryRoot);
  const target = normalizePath(candidate, root ?? process.cwd());

  if (!root || !target) {
    return false;
  }

  const relative = path.relative(root, target);
  return (
    relative === "" ||
    (!relative.startsWith(`..${path.sep}`) &&
      relative !== ".." &&
      !path.isAbsolute(relative))
  );
}

export function resolveRepositoryPath(repositoryRoot, candidate) {
  const resolved = normalizePath(candidate, repositoryRoot);
  return resolved && isPathInside(repositoryRoot, resolved) ? resolved : null;
}

export async function findRepositoryRoot(payload = {}) {
  const workspaceRoots = Array.isArray(payload.workspace_roots)
    ? payload.workspace_roots
    : [];
  const candidates = uniquePaths([
    payload.cwd,
    ...workspaceRoots,
    process.cwd(),
    SCRIPT_REPOSITORY_CANDIDATE,
  ]);

  for (const candidate of candidates) {
    const root = await findRootFrom(candidate);
    if (root) {
      return root;
    }
  }

  return null;
}

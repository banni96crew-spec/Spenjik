import { getString, readHookInput } from "./lib/input.mjs";
import {
  createResult,
  emitHookResult,
  runValidators,
  STATUS,
} from "./lib/output.mjs";
import {
  findRepositoryRoot,
  isPathInside,
  normalizePath,
} from "./lib/repository.mjs";
import { architectureBoundariesValidator } from "./validators/architecture-boundaries.mjs";
import { canonicalContractsValidator } from "./validators/canonical-contracts.mjs";
import { deterministicRandomValidator } from "./validators/deterministic-random.mjs";
import { gdscriptQualityValidator } from "./validators/gdscript-quality.mjs";
import { protectedFilesValidator } from "./validators/protected-files.mjs";
import { resourceIntegrityValidator } from "./validators/resource-integrity.mjs";

const validators = [
  protectedFilesValidator,
  gdscriptQualityValidator,
  architectureBoundariesValidator,
  deterministicRandomValidator,
  canonicalContractsValidator,
  resourceIntegrityValidator,
];

const input = await readHookInput();
if (input.error) {
  emitHookResult("afterFileEdit", createResult(STATUS.SKIP, input.error));
} else {
  const repositoryRoot = await findRepositoryRoot(input.payload);
  const filePath = normalizePath(getString(input.payload, "file_path"));

  let result;
  if (!repositoryRoot) {
    result = createResult(STATUS.SKIP, "Repository root not found.");
  } else if (!filePath || !isPathInside(repositoryRoot, filePath)) {
    result = createResult(
      STATUS.SKIP,
      "Edited file is missing or outside the repository.",
    );
  } else {
    result = await runValidators(validators, {
      eventName: "afterFileEdit",
      payload: input.payload,
      repositoryRoot,
      filePath,
      edits: Array.isArray(input.payload.edits) ? input.payload.edits : [],
    });
  }

  emitHookResult("afterFileEdit", result);
}

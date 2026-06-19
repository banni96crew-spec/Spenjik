import { getString, readHookInput } from "./lib/input.mjs";
import {
  createResult,
  emitHookResult,
  runValidators,
  STATUS,
} from "./lib/output.mjs";
import { findRepositoryRoot } from "./lib/repository.mjs";
import { commandSafetyValidator } from "./validators/command-safety.mjs";

const validators = [commandSafetyValidator];

const input = await readHookInput();
if (input.error) {
  emitHookResult(
    "beforeShellExecution",
    createResult(STATUS.SKIP, `${input.error} Shell command allowed fail-open.`),
  );
} else {
  const repositoryRoot = await findRepositoryRoot(input.payload);
  const context = {
    eventName: "beforeShellExecution",
    payload: input.payload,
    repositoryRoot,
    command: getString(input.payload, "command"),
    cwd: getString(input.payload, "cwd"),
  };

  const result = repositoryRoot
    ? await runValidators(validators, context)
    : createResult(STATUS.SKIP, "Repository root not found.");

  emitHookResult("beforeShellExecution", result);
}

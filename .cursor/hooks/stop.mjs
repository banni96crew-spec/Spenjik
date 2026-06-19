import { readHookInput } from "./lib/input.mjs";
import {
  createResult,
  emitHookResult,
  runValidators,
  STATUS,
} from "./lib/output.mjs";
import { findRepositoryRoot } from "./lib/repository.mjs";
import { testImpactValidator } from "./validators/test-impact.mjs";

const validators = [testImpactValidator];

const input = await readHookInput();
if (input.error) {
  emitHookResult("stop", createResult(STATUS.SKIP, input.error));
} else {
  const repositoryRoot = await findRepositoryRoot(input.payload);
  const result = repositoryRoot
    ? await runValidators(validators, {
        eventName: "stop",
        payload: input.payload,
        repositoryRoot,
        status:
          typeof input.payload.status === "string"
            ? input.payload.status
            : "unknown",
        loopCount: Number.isInteger(input.payload.loop_count)
          ? input.payload.loop_count
          : 0,
      })
    : createResult(STATUS.SKIP, "Repository root not found.");

  emitHookResult("stop", result);
}

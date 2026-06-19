export const STATUS = Object.freeze({
  PASS: "PASS",
  WARN: "WARN",
  ERROR: "ERROR",
  BLOCK: "BLOCK",
  SKIP: "SKIP",
});

const STATUS_PRIORITY = Object.freeze({
  [STATUS.PASS]: 0,
  [STATUS.SKIP]: 1,
  [STATUS.WARN]: 2,
  [STATUS.ERROR]: 3,
  [STATUS.BLOCK]: 4,
});

export function createResult(status, message, details = []) {
  if (!(status in STATUS_PRIORITY)) {
    throw new TypeError(`Unknown hook status: ${status}`);
  }

  return {
    status,
    message: typeof message === "string" ? message : "",
    details: Array.isArray(details)
      ? details.filter((item) => typeof item === "string")
      : [],
  };
}

export function mergeResults(results, fallbackMessage = "No validators registered.") {
  const validResults = results.filter(
    (result) => result && result.status in STATUS_PRIORITY,
  );

  if (validResults.length === 0) {
    return createResult(STATUS.PASS, fallbackMessage);
  }

  const selected = validResults.reduce((currentHighest, current) =>
    STATUS_PRIORITY[current.status] > STATUS_PRIORITY[currentHighest.status]
      ? current
      : currentHighest,
  );

  const additionalDetails = validResults
    .filter(
      (result) =>
        result !== selected &&
        result.status !== STATUS.PASS &&
        result.status !== STATUS.SKIP,
    )
    .flatMap((result) => [result.message, ...result.details])
    .filter(Boolean);

  return createResult(selected.status, selected.message, [
    ...selected.details,
    ...additionalDetails,
  ]);
}

export async function runValidators(validators, context) {
  const results = [];

  for (const validator of validators) {
    try {
      const result = await validator(context);
      if (result) {
        results.push(result);
      }
    } catch (error) {
      const validatorName = validator.name || "anonymous validator";
      results.push(
        createResult(
          STATUS.WARN,
          `${validatorName} failed open: ${error.message}`,
        ),
      );
    }
  }

  return mergeResults(results);
}

function conciseMessage(result) {
  const parts = [result.message, ...result.details].filter(Boolean);
  return parts.join(" ").slice(0, 1000);
}

export function emitHookResult(eventName, result) {
  const message = conciseMessage(result);
  if (result.status !== STATUS.PASS) {
    process.stderr.write(`[HOOK][${result.status}] ${message}\n`);
  }

  if (eventName === "beforeShellExecution") {
    const blocked = result.status === STATUS.BLOCK;
    const output = {
      permission: blocked ? "deny" : "allow",
    };

    if (blocked) {
      output.user_message = message || "Command blocked by project hook.";
      output.agent_message = message || "The project hook denied this command.";
    } else if (result.status === STATUS.WARN) {
      output.agent_message = message;
    }

    process.stdout.write(`${JSON.stringify(output)}\n`);
    return;
  }

  // afterFileEdit currently supports no output fields. stop accepts only an
  // optional followup_message, which this non-blocking skeleton never emits.
  process.stdout.write("{}\n");
}

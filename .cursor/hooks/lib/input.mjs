const DEFAULT_MAX_INPUT_BYTES = 1024 * 1024;

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

export async function readHookInput({
  stream = process.stdin,
  maxBytes = DEFAULT_MAX_INPUT_BYTES,
} = {}) {
  const chunks = [];
  let size = 0;

  try {
    for await (const chunk of stream) {
      const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
      size += buffer.length;

      if (size > maxBytes) {
        return {
          payload: {},
          error: `Hook input exceeds ${maxBytes} bytes.`,
        };
      }

      chunks.push(buffer);
    }
  } catch (error) {
    return {
      payload: {},
      error: `Unable to read hook input: ${error.message}`,
    };
  }

  const text = Buffer.concat(chunks).toString("utf8").trim();
  if (text === "") {
    return {
      payload: {},
      error: "Hook input is empty.",
    };
  }

  try {
    const payload = JSON.parse(text);
    if (!isRecord(payload)) {
      return {
        payload: {},
        error: "Hook input must be a JSON object.",
      };
    }

    return { payload, error: null };
  } catch (error) {
    return {
      payload: {},
      error: `Hook input is not valid JSON: ${error.message}`,
    };
  }
}

export function getString(payload, field, fallback = "") {
  const value = payload?.[field];
  return typeof value === "string" ? value : fallback;
}

export function getStringArray(payload, field) {
  const value = payload?.[field];
  if (!Array.isArray(value)) {
    return [];
  }

  return value.filter((item) => typeof item === "string");
}

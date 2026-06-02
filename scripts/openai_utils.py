import json
import os
import time
import urllib.error
import urllib.request


OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses"
RETRYABLE_HTTP_CODES = {408, 409, 429, 500, 502, 503, 504}


def require_env(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def read_error_body(error):
    body = error.read().decode("utf-8", errors="replace")
    try:
        parsed = json.loads(body)
    except json.JSONDecodeError:
        return body, {}
    return body, parsed.get("error", {})


def is_insufficient_quota(error_payload):
    return error_payload.get("code") == "insufficient_quota" or error_payload.get("type") == "insufficient_quota"


def retry_delay(error, attempt):
    retry_after = error.headers.get("Retry-After")
    if retry_after:
        try:
            return min(float(retry_after), 30.0)
        except ValueError:
            pass
    return min(2**attempt, 30)


def post_json(url, payload, headers):
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(url, data=data, headers=headers, method="POST")
    max_retries = int(os.environ.get("OPENAI_MAX_RETRIES", "3"))

    for attempt in range(max_retries + 1):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            body, error_payload = read_error_body(error)
            if is_insufficient_quota(error_payload):
                message = error_payload.get("message") or body
                raise RuntimeError(
                    "OpenAI API quota is exhausted for OPENAI_API_KEY. "
                    "Check the API key, project billing, and usage limits. "
                    f"API message: {message}"
                ) from error

            should_retry = error.code in RETRYABLE_HTTP_CODES and attempt < max_retries
            if not should_retry:
                raise RuntimeError(f"HTTP {error.code} from {url}: {body}") from error

            delay = retry_delay(error, attempt)
            print(f"OpenAI API HTTP {error.code}; retrying in {delay:.1f}s ({attempt + 1}/{max_retries})")
            time.sleep(delay)

    raise RuntimeError("OpenAI API request failed after retries")


def create_response(prompt, *, model=None, max_output_tokens=12000):
    text, _usage = create_response_with_usage(
        prompt,
        model=model,
        max_output_tokens=max_output_tokens,
    )
    return text


def create_response_with_usage(prompt, *, model=None, max_output_tokens=12000):
    api_key = require_env("OPENAI_API_KEY")
    selected_model = model or os.environ.get("OPENAI_MODEL", "gpt-4.1-mini")

    payload = {
        "model": selected_model,
        "input": prompt,
        "max_output_tokens": max_output_tokens,
    }

    response = post_json(
        OPENAI_RESPONSES_URL,
        payload,
        {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )
    return extract_output_text(response), response.get("usage", {})


def print_usage(label, usage):
    input_tokens = usage.get("input_tokens", 0)
    output_tokens = usage.get("output_tokens", 0)
    total_tokens = usage.get("total_tokens", input_tokens + output_tokens)
    print(f"{label} token usage:")
    print(f"- input_tokens: {input_tokens}")
    print(f"- output_tokens: {output_tokens}")
    print(f"- total_tokens: {total_tokens}")


def extract_output_text(response):
    if response.get("output_text"):
        return response["output_text"]

    parts = []
    for item in response.get("output", []):
        for content in item.get("content", []):
            text = content.get("text")
            if text:
                parts.append(text)
    if not parts:
        raise RuntimeError(f"OpenAI response did not contain text: {response}")
    return "\n".join(parts)


def parse_json_object(text):
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = stripped.strip("`")
        stripped = stripped.removeprefix("json").strip()

    try:
        return json.loads(stripped)
    except json.JSONDecodeError:
        start = stripped.find("{")
        end = stripped.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise
        return json.loads(stripped[start : end + 1])

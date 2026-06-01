import json
import os
import urllib.error
import urllib.request


OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses"


def require_env(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def post_json(url, payload, headers):
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(url, data=data, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {error.code} from {url}: {body}") from error


def create_response(prompt, *, model=None, max_output_tokens=12000):
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
    return extract_output_text(response)


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

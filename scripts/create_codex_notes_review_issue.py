import datetime as dt
import json
import os
import pathlib
import urllib.error
import urllib.request

from openai_utils import create_response_with_usage, print_usage, require_env


REVIEW_TARGETS = [
    "AGENTS.md",
    "README.md",
    "skills/pr-review/SKILL.md",
    "skills/spring-transaction-audit/SKILL.md",
    "skills/query-plan-review/SKILL.md",
    "skills/jpa-performance-review/SKILL.md",
    "skills/mybatis-xml-review/SKILL.md",
    "skills/test-generator/SKILL.md",
    "skills/logging-observability/SKILL.md",
    "skills/deploy-checklist/SKILL.md",
]


def read_targets(root):
    chunks = []
    for relative in REVIEW_TARGETS:
        path = root / relative
        if not path.exists():
            chunks.append(f"## {relative}\n파일 없음")
            continue
        text = path.read_text(encoding="utf-8")
        chunks.append(f"## {relative}\n```markdown\n{text[:12000]}\n```")
    return "\n\n".join(chunks)


def github_request(method, path, payload):
    token = require_env("GITHUB_TOKEN")
    repository = require_env("GITHUB_REPOSITORY")
    url = f"https://api.github.com/repos/{repository}{path}"
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"GitHub API HTTP {error.code}: {body}") from error


def build_prompt(today, repository_content):
    return f"""
codex-notes 저장소를 주간 점검하고 GitHub Issue 본문으로 사용할 리포트를 작성한다.

점검 기준:
- AGENTS.md가 Codex 작업 루프와 Java/Spring 백엔드 운영 관점에 맞는가.
- Skill description이 자동 트리거에 충분한 영어/한국어 키워드를 갖는가.
- Skill 본문이 한국어 사용자에게 읽기 쉽고, 너무 장황하지 않은가.
- README의 사용법, 자동화, Notion/GitHub Actions 안내가 현재 구조와 맞는가.
- TODO, 오래된 지침, 중복, 불명확한 운영 리스크가 있는가.
- 자동 수정하지 말고 개선 제안만 한다.

출력 형식:
# Weekly codex-notes Review - {today}

## 요약
...

## 발견 사항
- [우선순위] 파일: 내용

## 제안 수정
...

## 다음 액션
...

저장소 내용:
{repository_content}
""".strip()


def main():
    today = os.environ.get("REVIEW_DATE") or dt.date.today().isoformat()
    root = pathlib.Path.cwd()
    content = read_targets(root)
    report, usage = create_response_with_usage(build_prompt(today, content), max_output_tokens=10000)
    print_usage("codex-notes weekly review", usage)

    title = f"[Weekly Review] codex-notes 점검 - {today}"
    issue = github_request(
        "POST",
        "/issues",
        {
            "title": title,
            "body": report,
        },
    )
    print(f"Created issue: {issue.get('html_url')}")


if __name__ == "__main__":
    main()

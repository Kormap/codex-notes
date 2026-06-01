import datetime as dt
import json
import os
import urllib.error
import urllib.request

from openai_utils import create_response, parse_json_object, require_env


NOTION_API_BASE = "https://api.notion.com/v1"
NOTION_VERSION = "2022-06-28"


def notion_request(method, path, payload=None):
    token = require_env("NOTION_TOKEN")
    data = None
    if payload is not None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")

    request = urllib.request.Request(
        f"{NOTION_API_BASE}{path}",
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Notion-Version": NOTION_VERSION,
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            body = response.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Notion API HTTP {error.code}: {body}") from error


def rich_text(text):
    return [{"type": "text", "text": {"content": text[:2000]}}]


def paragraph(text):
    return {"object": "block", "type": "paragraph", "paragraph": {"rich_text": rich_text(text)}}


def heading(text, level=2):
    key = f"heading_{level}"
    return {"object": "block", "type": key, key: {"rich_text": rich_text(text)}}


def code_block(code, language="sql"):
    return {
        "object": "block",
        "type": "code",
        "code": {
            "language": language,
            "rich_text": rich_text(code),
        },
    }


def bullets(items):
    return [
        {
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": {"rich_text": rich_text(item)},
        }
        for item in items
    ]


def build_blocks(problem):
    blocks = [
        heading("상황"),
        paragraph(problem["context"]),
        heading("테이블 구조"),
        code_block(problem["schema"], "sql"),
        heading("느린 SQL"),
        code_block(problem["slow_sql"], "sql"),
        heading("실행계획 증상"),
        code_block(problem["plan_symptom"], "plain text"),
        heading("질문"),
        *bullets(problem["questions"]),
        heading("정답 / 해설"),
        paragraph(problem["answer"]),
        heading("운영 주의사항"),
        *bullets(problem["operational_cautions"]),
    ]
    return blocks[:100]


def create_notion_page(database_id, date, problem):
    properties = {
        "문제": {"title": [{"type": "text", "text": {"content": problem["title"]}}]},
        "회차일": {"date": {"start": date}},
        "DBMS": {"select": {"name": problem["dbms"]}},
        "난이도": {"select": {"name": problem["difficulty"]}},
        "주제": {"multi_select": [{"name": topic} for topic in problem["topics"]]},
        "상태": {"status": {"name": "시작 전"}},
        "예상 Rows": {"number": int(problem["estimated_rows"])},
        "트래픽 리스크": {"select": {"name": problem["traffic_risk"]}},
        "풀이 여부": {"checkbox": False},
        "포트폴리오 공개": {"checkbox": False},
    }

    return notion_request(
        "POST",
        "/pages",
        {
            "parent": {"database_id": database_id},
            "properties": properties,
            "children": build_blocks(problem),
        },
    )


def build_prompt(today):
    return f"""
Java/Spring 백엔드 개발자 학습용 SQL 튜닝 연습 문제를 생성한다.

요구사항:
- 정확히 5문제.
- Oracle, MySQL, PostgreSQL, 공통 예시를 현실적으로 섞는다.
- 주제는 pagination, join, count query, N+1 유사 접근, aggregation, 날짜 범위 필터링을 골고루 포함한다.
- 각 문제는 운영 기준으로 TPS 200+, 동시 접속 1,000+, 단일 테이블 1,000만 row, 트래픽 10배 증가 리스크를 고려한다.
- 답변은 JSON 객체만 출력한다. Markdown fence를 쓰지 않는다.

JSON 스키마:
{{
  "date": "{today}",
  "problems": [
    {{
      "title": "문제 제목",
      "dbms": "Oracle|MySQL|PostgreSQL|공통",
      "difficulty": "초급|중급|고급",
      "topics": ["인덱스", "실행계획"],
      "estimated_rows": 10000000,
      "traffic_risk": "낮음|중간|높음",
      "context": "서비스 맥락",
      "schema": "CREATE TABLE 또는 컬럼 설명",
      "slow_sql": "느린 SQL",
      "plan_symptom": "단순화한 실행계획 또는 증상",
      "questions": ["질문1", "질문2", "질문3"],
      "answer": "추천 인덱스 또는 쿼리 리라이트, tradeoff, 판단 근거",
      "operational_cautions": ["운영 주의사항1", "운영 주의사항2"]
    }}
  ]
}}
""".strip()


def main():
    database_id = require_env("NOTION_DATABASE_ID")
    today = os.environ.get("DRILL_DATE") or dt.date.today().isoformat()
    text = create_response(build_prompt(today), max_output_tokens=14000)
    payload = parse_json_object(text)

    problems = payload.get("problems", [])
    if len(problems) != 5:
        raise RuntimeError(f"Expected exactly 5 problems, got {len(problems)}")

    created_urls = []
    for problem in problems:
        page = create_notion_page(database_id, today, problem)
        created_urls.append(page.get("url", ""))

    print("Created Notion SQL tuning drill pages:")
    for url in created_urls:
        print(f"- {url}")


if __name__ == "__main__":
    main()

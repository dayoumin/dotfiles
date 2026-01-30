# 전역 개발 규칙

## 에러 해결 원칙 (3회 규칙)

**동일한 에러가 3회 연속 해결되지 않으면 반드시 검색 먼저:**

```
1회 실패 → 코드 수정 시도
2회 실패 → 다른 접근 시도
3회 실패 → STOP! 웹 검색 필수
```

**검색 순서:**
1. 에러 메시지 + 프레임워크 버전으로 웹 검색
2. GitHub Issues 확인
3. 공식 문서 확인

**원칙:** 추측으로 10번 시도 < 검색 1번

## Node.js / JavaScript / TypeScript
- **npm 대신 pnpm 사용**
- `npm install` → `pnpm install`
- `npm run` → `pnpm run`
- 새 프로젝트 생성 시 pnpm 사용 권장

## Python
- **pip 대신 uv 사용**
- `pip install` → `uv pip install`
- `python -m venv` → `uv venv`
- `pip freeze` → `uv pip freeze`

## 프로젝트 구조
- 관련 프로젝트는 모노레포(monorepo) 구조 권장
- pnpm workspace 활용
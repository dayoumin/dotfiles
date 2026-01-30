# Dotfiles

개발 환경 설정 파일 모음.

## 포함된 설정

| 파일 | 설명 |
|------|------|
| `.mcp.json` | MCP 서버 설정 (playwright-test) |
| `.claude/mcp.json` | Claude MCP 설정 (playwright, stitch) |
| `.claude/CLAUDE.md` | 전역 개발 규칙 |
| `.claude/agents/` | Playwright Test 에이전트 정의 |

## 설치

```bash
git clone https://github.com/USERNAME/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

## 새 설정 추가 시

1. `~/dotfiles/`에 파일 추가
2. `install.sh`에 심볼릭 링크 추가
3. commit & push

## 주의사항

- 민감한 정보(API 키, 비밀번호)는 `.gitignore`에 추가
- 절대 경로 대신 `$HOME` 또는 `~` 사용 권장

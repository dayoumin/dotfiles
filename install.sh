#!/bin/bash

# Dotfiles Installation Script
# Cross-platform: Windows (Git Bash), macOS, Linux

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "🚀 Dotfiles 설치를 시작합니다..."
echo "📁 Dotfiles 위치: $DOTFILES_DIR"

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

setup_symlink() {
    local source_file="$1"
    local target_file="$2"

    # 기존 파일/디렉토리가 존재하면 백업 (심볼릭 링크가 아닌 경우만)
    if [ -e "$target_file" ] && [ ! -L "$target_file" ]; then
        echo "📦 백업 생성: $target_file"
        mv "$target_file" "$BACKUP_DIR/"
    elif [ -L "$target_file" ]; then
        # 기존 심볼릭 링크 제거
        rm "$target_file"
    fi

    # 심볼릭 링크 생성
    ln -sf "$source_file" "$target_file"
    echo "✅ 연결 완료: $target_file -> $source_file"
}

# 1. ~/.mcp.json 연결
setup_symlink "$DOTFILES_DIR/.mcp.json" "$HOME/.mcp.json"

# 2. ~/.claude 디렉토리 준비
mkdir -p "$HOME/.claude"

# 3. ~/.claude/mcp.json 연결
setup_symlink "$DOTFILES_DIR/.claude/mcp.json" "$HOME/.claude/mcp.json"

# 4. ~/.claude/CLAUDE.md 연결
setup_symlink "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# 5. ~/.claude/agents 디렉토리 연결
if [ -d "$HOME/.claude/agents" ] && [ ! -L "$HOME/.claude/agents" ]; then
    echo "📦 백업 생성: $HOME/.claude/agents"
    mv "$HOME/.claude/agents" "$BACKUP_DIR/"
fi
setup_symlink "$DOTFILES_DIR/.claude/agents" "$HOME/.claude/agents"

# 백업 디렉토리가 비어있으면 삭제
if [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    rmdir "$BACKUP_DIR"
    echo "📁 백업할 파일이 없어 백업 디렉토리를 삭제했습니다."
else
    echo "📁 백업 위치: $BACKUP_DIR"
fi

echo ""
echo "✨ 모든 설정이 완료되었습니다!"
echo ""
echo "📋 설치된 항목:"
echo "   - ~/.mcp.json (MCP 서버 설정)"
echo "   - ~/.claude/mcp.json (Claude MCP 설정)"
echo "   - ~/.claude/CLAUDE.md (전역 개발 규칙)"
echo "   - ~/.claude/agents/ (에이전트 정의)"

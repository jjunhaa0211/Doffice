#!/bin/zsh
set -euo pipefail

title="Context Capsule"

notify() {
  local message="${1:-Done}"
  local safe_message="${message//\"/\\\"}"
  osascript -e "display notification \"$safe_message\" with title \"$title\"" >/dev/null 2>&1 || true
}

copy_to_clipboard() {
  local content="$1"
  if command -v pbcopy >/dev/null 2>&1; then
    printf "%s" "$content" | pbcopy
  fi
}

open_file() {
  local path="$1"
  if command -v open >/dev/null 2>&1; then
    open "$path" >/dev/null 2>&1 || true
  fi
}

project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$project_root"

project_name="$(basename "$project_root")"
git_branch="$(git branch --show-current 2>/dev/null || true)"
git_dirty="$(git status --short 2>/dev/null || true)"
git_dirty_count="$(printf "%s\n" "$git_dirty" | sed '/^$/d' | wc -l | tr -d ' ')"

top_dirs="$(find . -maxdepth 1 -type d ! -path . -print | sed 's#^\./##' | sort | head -n 10 | awk '{print "- `" $0 "`"}')"
if [[ -z "$top_dirs" ]]; then
  top_dirs="- 하위 디렉터리가 없습니다."
fi

manifest_list=""
for candidate in README.md package.json pnpm-workspace.yaml Project.swift Package.swift Podfile Gemfile pyproject.toml requirements.txt Cargo.toml go.mod; do
  if [[ -f "$candidate" ]]; then
    manifest_list="${manifest_list}- \`${candidate}\`
"
  fi
done
if [[ -z "$manifest_list" ]]; then
  manifest_list="- 주요 매니페스트 파일을 찾지 못했습니다."
fi

recent_commits="$(git log --pretty=format:'- %s' -n 5 2>/dev/null || true)"
if [[ -z "$recent_commits" ]]; then
  recent_commits="- Git 커밋 기록이 없습니다."
fi

git_snapshot="- Git 저장소가 아니거나 현재 브랜치를 읽지 못했습니다."
if [[ -n "$git_branch" ]]; then
  git_snapshot="- Branch: \`${git_branch}\`
- Working tree changes: ${git_dirty_count}"
fi

report_dir="$project_root/.doffice/reports"
mkdir -p "$report_dir"
report_path="$report_dir/context-capsule.md"

report="$(cat <<EOF
# Context Capsule

- Project: \`$project_name\`
- Path: \`$project_root\`

## Top-Level Directories
$top_dirs

## Key Project Files
$manifest_list

## Git Snapshot
$git_snapshot

## Recent Commits
$recent_commits
EOF
)"

printf "%s\n" "$report" > "$report_path"
copy_to_clipboard "$report"
open_file "$report_path"
notify "프로젝트 컨텍스트 스냅샷을 준비했습니다."

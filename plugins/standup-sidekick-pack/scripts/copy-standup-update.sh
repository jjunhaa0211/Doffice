#!/bin/zsh
set -euo pipefail

title="Standup Sidekick"

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

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  notify "Git 저장소에서 실행해 주세요."
  exit 1
fi

cd "$repo_root"

repo_name="$(basename "$repo_root")"
branch="$(git branch --show-current 2>/dev/null || true)"
if [[ -z "$branch" ]]; then
  branch="unknown-branch"
fi

recent_commits="$(git log --since='36 hours ago' --pretty=format:'- %s' -n 3 2>/dev/null || true)"
if [[ -z "$recent_commits" ]]; then
  recent_commits="$(git log --pretty=format:'- %s' -n 3 2>/dev/null || true)"
fi
if [[ -z "$recent_commits" ]]; then
  recent_commits="- 아직 기록된 커밋이 없습니다."
fi

status_lines="$(git status --short 2>/dev/null || true)"
changed_count="$(printf "%s\n" "$status_lines" | sed '/^$/d' | wc -l | tr -d ' ')"

changed_files="$(printf "%s\n" "$status_lines" | sed 's/^.. //' | sed 's/.* -> //' | sed '/^$/d' | head -n 6)"
if [[ -z "$changed_files" ]]; then
  changed_files="README.md"
fi

focus_areas="$(printf "%s\n" "$changed_files" | awk -F/ 'NF > 1 { print "- " $1; next } { print "- repo-root" }' | awk '!seen[$0]++' | head -n 3)"
top_files="$(printf "%s\n" "$changed_files" | awk '{print "- `" $0 "`"}')"

blocker_line="현재 blocker는 크게 보이지 않습니다."
if [[ "$changed_count" != "0" ]]; then
  blocker_line="변경 파일 ${changed_count}개에 대한 리뷰나 QA 확인이 남아 있을 수 있습니다."
fi

report_dir="$repo_root/.doffice/reports"
mkdir -p "$report_dir"
report_path="$report_dir/standup-update.md"

report="$(cat <<EOF
# Standup Update

- Repo: \`$repo_name\`
- Branch: \`$branch\`

## Yesterday
$recent_commits

## Today
- \`$branch\` 브랜치를 계속 밀고 필요한 마무리 작업을 진행합니다.
$focus_areas

## Touched Files
$top_files

## Blockers
- $blocker_line
EOF
)"

printf "%s\n" "$report" > "$report_path"
copy_to_clipboard "$report"
open_file "$report_path"
notify "스탠드업 초안을 클립보드와 보고서로 준비했습니다."

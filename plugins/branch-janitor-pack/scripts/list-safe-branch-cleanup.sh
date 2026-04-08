#!/bin/zsh
set -euo pipefail

title="Branch Janitor"

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

resolve_base_ref() {
  local remote_head
  remote_head="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [[ -n "$remote_head" ]]; then
    printf "%s" "$remote_head"
    return
  fi

  local candidate
  for candidate in main master develop dev origin/main origin/master; do
    if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
      printf "%s" "$candidate"
      return
    fi
  done

  printf "%s" "main"
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  notify "Git 저장소에서 실행해 주세요."
  exit 1
fi

cd "$repo_root"

current_branch="$(git branch --show-current 2>/dev/null || true)"
base_ref="$(resolve_base_ref)"
base_name="${base_ref##*/}"

merged_branches="$(git branch --format='%(refname:short)' --merged "$base_ref" 2>/dev/null | \
  sed '/^$/d' | \
  grep -vx "${current_branch}" | \
  grep -Ev '^(main|master|develop|dev|staging|release)$' || true)"

cleanup_commands=""
if [[ -n "$merged_branches" ]]; then
  cleanup_commands="$(printf "%s\n" "$merged_branches" | awk '{print "git branch -d " $0}')"
fi

stale_branches="$(git for-each-ref --sort=committerdate --format='%(refname:short)|%(committerdate:short)' refs/heads 2>/dev/null | \
  grep -Ev '^(main|master|develop|dev|staging|release)\|' | \
  grep -Ev "^${current_branch//./\\.}\\|" | \
  head -n 5 || true)"

if [[ -z "$cleanup_commands" ]]; then
  cleanup_commands="# No safe cleanup candidates found"
fi

report_dir="$repo_root/.doffice/reports"
mkdir -p "$report_dir"
report_path="$report_dir/branch-cleanup.md"

report="$(cat <<EOF
# Branch Cleanup

- Current branch: \`${current_branch:-unknown}\`
- Base branch: \`$base_name\`

## Safe Delete Candidates
$(if [[ -n "$merged_branches" ]]; then printf "%s\n" "$merged_branches" | awk '{print "- `" $0 "`"}'; else printf "%s\n" "- 정리 가능한 머지 완료 브랜치를 찾지 못했습니다."; fi)

## Suggested Commands
\`\`\`bash
$cleanup_commands
\`\`\`

## Oldest Local Branches
$(if [[ -n "$stale_branches" ]]; then printf "%s\n" "$stale_branches" | awk -F'|' '{print "- `" $1 "` last updated on " $2}'; else printf "%s\n" "- 오래된 브랜치 후보가 없습니다."; fi)
EOF
)"

printf "%s\n" "$report" > "$report_path"
copy_to_clipboard "$cleanup_commands"
open_file "$report_path"
notify "브랜치 정리 후보를 보고서와 클립보드로 준비했습니다."

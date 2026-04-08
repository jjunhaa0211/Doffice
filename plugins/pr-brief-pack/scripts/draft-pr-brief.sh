#!/bin/zsh
set -euo pipefail

title="PR Brief"

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

slug_to_words() {
  local text="$1"
  printf "%s" "$text" | tr '/_-' ' ' | sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//'
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

repo_name="$(basename "$repo_root")"
branch="$(git branch --show-current 2>/dev/null || true)"
if [[ -z "$branch" ]]; then
  branch="work-in-progress"
fi

base_ref="$(resolve_base_ref)"
base_name="${base_ref##*/}"

commits="$(git log --pretty=format:'- %s' "${base_ref}..HEAD" -n 8 2>/dev/null || true)"
if [[ -z "$commits" ]]; then
  commits="$(git log --pretty=format:'- %s' -n 5 2>/dev/null || true)"
fi
if [[ -z "$commits" ]]; then
  commits="- 아직 요약할 커밋이 없습니다."
fi

changed_files="$(git diff --name-only "${base_ref}...HEAD" 2>/dev/null || true)"
if [[ -z "$changed_files" ]]; then
  changed_files="$(git status --short 2>/dev/null | sed 's/^.. //' | sed 's/.* -> //' | sed '/^$/d' || true)"
fi

file_count="$(printf "%s\n" "$changed_files" | sed '/^$/d' | wc -l | tr -d ' ')"
review_areas="$(printf "%s\n" "$changed_files" | awk -F/ 'NF > 1 {print "- `" $1 "`"} NF == 1 {print "- `repo-root`"}' | awk '!seen[$0]++' | head -n 5)"
if [[ -z "$review_areas" ]]; then
  review_areas="- `repo-root`"
fi

branch_phrase="$(slug_to_words "${branch##*/}")"
if [[ -z "$branch_phrase" ]]; then
  branch_phrase="current branch updates"
fi

risk_note="- 범위가 비교적 작아서 빠른 리뷰가 가능합니다."
if [[ "${file_count:-0}" -gt 15 ]]; then
  risk_note="- 변경 파일 수가 많아서 단계별 리뷰가 더 안전합니다."
fi
if printf "%s\n" "$changed_files" | grep -Eq '(^|/)(Project\\.swift|Package\\.swift|Podfile|Gemfile)$'; then
  risk_note="$risk_note
- 빌드 또는 의존성 설정 파일이 바뀌었으니 설치/빌드 확인이 필요합니다."
fi

report_dir="$repo_root/.doffice/reports"
mkdir -p "$report_dir"
report_path="$report_dir/pr-brief.md"

report="$(cat <<EOF
# PR Brief

## Summary
- This branch focuses on ${branch_phrase}.
- It is being compared against \`${base_name}\`.

## What Changed
$commits

## Review Areas
$review_areas

## Risk Check
$risk_note

## Testing
- [ ] Run targeted tests for the touched area
- [ ] Smoke test the main user flow
- [ ] Confirm logs or warnings stayed clean
EOF
)"

printf "%s\n" "$report" > "$report_path"
copy_to_clipboard "$report"
open_file "$report_path"
notify "PR 브리프 초안을 클립보드와 보고서로 준비했습니다."

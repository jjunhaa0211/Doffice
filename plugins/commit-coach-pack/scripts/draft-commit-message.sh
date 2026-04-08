#!/bin/zsh
set -euo pipefail

title="Commit Coach"

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

changed_files="$(git diff --cached --name-only 2>/dev/null || true)"
change_source="staged changes"
if [[ -z "$changed_files" ]]; then
  changed_files="$(git diff --name-only 2>/dev/null || true)"
  change_source="working tree changes"
fi
if [[ -z "$changed_files" ]]; then
  changed_files="$(git ls-files --others --exclude-standard 2>/dev/null || true)"
  change_source="untracked files"
fi
if [[ -z "$changed_files" ]]; then
  notify "커밋 메시지를 만들 변경 사항이 없습니다."
  exit 1
fi

scope="$(printf "%s\n" "$changed_files" | awk -F/ 'NF > 1 { print $1; exit }')"
if [[ -z "$scope" ]]; then
  scope="$repo_name"
fi

branch_hint="${branch##*/}"
branch_phrase="$(slug_to_words "$branch_hint")"
if [[ -z "$branch_phrase" ]]; then
  branch_phrase="$scope workflow"
fi

target_summary="$(printf "%s\n" "$changed_files" | awk -F/ '{print $NF}' | awk '!seen[$0]++' | head -n 3 | paste -sd ', ' -)"
if [[ -z "$target_summary" ]]; then
  target_summary="current changes"
fi

type="feat"
lead="improve"
case "${branch:l}" in
  *fix*|*bug*|*hotfix*)
    type="fix"
    lead="stabilize"
    ;;
  *docs*|*readme*)
    type="docs"
    lead="document"
    ;;
  *refactor*|*cleanup*)
    type="refactor"
    lead="refine"
    ;;
  *test*|*qa*)
    type="test"
    lead="cover"
    ;;
  *ci*|*workflow*)
    type="ci"
    lead="align"
    ;;
  *chore*)
    type="chore"
    lead="tidy"
    ;;
esac

option1="${type}(${scope}): ${lead} ${branch_phrase}"
option2="${type}: update ${target_summary}"
option3="chore(${scope}): tidy follow-ups around ${scope}"

report_dir="$repo_root/.doffice/reports"
mkdir -p "$report_dir"
report_path="$report_dir/commit-message-options.md"

report="$(cat <<EOF
# Commit Message Options

- Repo: \`$repo_name\`
- Branch: \`$branch\`
- Source: $change_source

## Recommended
1. \`$option1\`
2. \`$option2\`
3. \`$option3\`

## Changed Files
$(printf "%s\n" "$changed_files" | awk '{print "- `" $0 "`"}')
EOF
)"

printf "%s\n" "$report" > "$report_path"
copy_to_clipboard "$option1"
open_file "$report_path"
notify "추천 커밋 메시지를 클립보드로 복사했습니다."

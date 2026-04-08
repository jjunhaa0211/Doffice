#!/bin/zsh
#
# l10n-check.sh — Verify localization key parity across languages and source trees.
# Exits non-zero if any language is missing keys that another has.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DRIFT=0

check_tree() {
    local label="$1"
    local base="$2"
    local langs=(en ko ja)
    local key_files=()

    echo "--- $label ---"

    for lang in "${langs[@]}"; do
        local file="$base/${lang}.lproj/Localizable.strings"
        if [[ ! -f "$file" ]]; then
            echo "  MISSING: $file"
            DRIFT=1
            continue
        fi
        key_files+=("$file")
        local count=$(grep -cE '^"[^"]+"' "$file" 2>/dev/null || echo 0)
        echo "  $lang: $count keys"
    done

    if [[ ${#key_files[@]} -lt 2 ]]; then
        return
    fi

    # Extract keys from each language and compare
    local ref_file="${key_files[1]}"
    local ref_lang="${langs[1]}"
    local ref_keys=$(grep -oE '^"[^"]+"' "$ref_file" | sort)

    for i in $(seq 2 ${#key_files[@]}); do
        local cmp_file="${key_files[$i]}"
        local cmp_lang="${langs[$i]}"
        local cmp_keys=$(grep -oE '^"[^"]+"' "$cmp_file" | sort)

        local missing_in_cmp=$(comm -23 <(echo "$ref_keys") <(echo "$cmp_keys") | wc -l | tr -d ' ')
        local missing_in_ref=$(comm -13 <(echo "$ref_keys") <(echo "$cmp_keys") | wc -l | tr -d ' ')

        if [[ "$missing_in_cmp" -gt 0 ]]; then
            echo "  DRIFT: $missing_in_cmp keys in $ref_lang but missing in $cmp_lang"
            DRIFT=1
        fi
        if [[ "$missing_in_ref" -gt 0 ]]; then
            echo "  DRIFT: $missing_in_ref keys in $cmp_lang but missing in $ref_lang"
            DRIFT=1
        fi
    done
}

echo "=== Localization Key Sync Check ==="
echo ""

check_tree "Projects/App" "$ROOT_DIR/Projects/App/Resources"
echo ""
check_tree "Doffice (legacy)" "$ROOT_DIR/Doffice/Resources"

# Cross-tree check
echo ""
echo "--- Cross-tree (Projects ↔ Doffice) ---"
PROJ_EN="$ROOT_DIR/Projects/App/Resources/en.lproj/Localizable.strings"
LEGACY_EN="$ROOT_DIR/Doffice/Resources/en.lproj/Localizable.strings"

if [[ -f "$PROJ_EN" && -f "$LEGACY_EN" ]]; then
    PROJ_KEYS=$(grep -oE '^"[^"]+"' "$PROJ_EN" | sort)
    LEG_KEYS=$(grep -oE '^"[^"]+"' "$LEGACY_EN" | sort)

    ONLY_PROJ=$(comm -23 <(echo "$PROJ_KEYS") <(echo "$LEG_KEYS") | wc -l | tr -d ' ')
    ONLY_LEG=$(comm -13 <(echo "$PROJ_KEYS") <(echo "$LEG_KEYS") | wc -l | tr -d ' ')

    if [[ "$ONLY_PROJ" -gt 0 ]]; then
        echo "  $ONLY_PROJ keys in Projects but missing in Doffice"
        DRIFT=1
    fi
    if [[ "$ONLY_LEG" -gt 0 ]]; then
        echo "  $ONLY_LEG keys in Doffice but missing in Projects"
        DRIFT=1
    fi
    if [[ "$ONLY_PROJ" -eq 0 && "$ONLY_LEG" -eq 0 ]]; then
        echo "  OK: All keys match"
    fi
fi

echo ""
if [[ "$DRIFT" -eq 1 ]]; then
    echo "FAIL: Localization drift detected."
    exit 1
else
    echo "OK: All localization keys are in sync."
    exit 0
fi

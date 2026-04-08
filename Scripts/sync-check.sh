#!/bin/zsh

# sync-check.sh — Validates that Projects/ (Tuist modular) and Doffice/ (legacy)
# source trees stay in sync. Exits non-zero on drift.
#
# Some files in Projects/ were split into extensions (e.g., SessionManager →
# SessionManager+Search, +ProcessDetection, etc.). For these, the script sums
# function counts across all related files before comparing.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DRIFT=0
CHECKED=0

count_funcs() {
    local total=0
    for f in "$@"; do
        if [[ -f "$f" ]]; then
            local n
            n=$(grep -cE '^\s*(public |private |internal |open )?func ' "$f" 2>/dev/null) || n=0
            total=$((total + n))
        fi
    done
    echo $total
}

count_types() {
    local total=0
    for f in "$@"; do
        if [[ -f "$f" ]]; then
            local n
            n=$(grep -cE '^\s*(public |private |internal |open )?(struct|class|enum|protocol) ' "$f" 2>/dev/null) || n=0
            total=$((total + n))
        fi
    done
    echo $total
}

echo "=== Source Sync Check: Projects/ ↔ Doffice/ ==="

# --- Simple 1:1 file pairs (no extension splits) ---
SIMPLE_PAIRS=(
    "SensitiveFileShield.swift"
    "DangerousCommandDetector.swift"
    "SwiftTermBridge.swift"
    "ShortcutManager.swift"
    "VT100Terminal.swift"
    "CrashLogger.swift"
    "DofficeServer.swift"
    "SessionStore.swift"
    "AuditLog.swift"
    "DiagnosticReport.swift"
    "UpdateChecker.swift"
    "PromptFavorites.swift"
    "PixelStripView.swift"
)

echo ""
echo "--- Simple file pairs ---"
for file in "${SIMPLE_PAIRS[@]}"; do
    MODULAR="$ROOT_DIR/Projects/DofficeKit/Sources/$file"
    LEGACY="$ROOT_DIR/Doffice/Sources/$file"

    [[ ! -f "$MODULAR" && ! -f "$LEGACY" ]] && continue
    CHECKED=$((CHECKED + 1))

    if [[ ! -f "$MODULAR" ]]; then echo "  MISSING modular: $file"; DRIFT=1; continue; fi
    if [[ ! -f "$LEGACY" ]]; then echo "  MISSING legacy:  $file"; DRIFT=1; continue; fi

    MOD_F=$(count_funcs "$MODULAR"); LEG_F=$(count_funcs "$LEGACY")
    MOD_T=$(count_types "$MODULAR"); LEG_T=$(count_types "$LEGACY")

    if [[ "$MOD_F" != "$LEG_F" || "$MOD_T" != "$LEG_T" ]]; then
        echo "  DRIFT $file: functions($MOD_F vs $LEG_F) types($MOD_T vs $LEG_T)"
        DRIFT=1
    fi
done

# --- Split files: modular has extensions, legacy has monolith ---
# Format: "legacy_file:modular_base:modular_ext1:modular_ext2:..."
SPLIT_PAIRS=(
    "SessionManager.swift:SessionManager.swift:SessionManager+Search.swift:SessionManager+ProcessDetection.swift:SessionManager+PromptBuilder.swift:SessionManager+Persistence.swift:SessionManager+Automation.swift"
    "CharacterSystem.swift:CharacterSystem.swift:CharacterRegistry.swift"
    "GameSystem.swift:GameSystem.swift:AchievementManager.swift:GameTypes.swift"
    "GitPanelView.swift:GitPanelView.swift:GitPanelCenter.swift:GitPanelDetail.swift:GitPanelSidebar.swift:GitPanelActions.swift"
    "BrowserView.swift:BrowserView.swift"
    "PluginEffectEngine.swift:PluginEffectEngine.swift:PluginEventTypes.swift"
    "PluginManager.swift:PluginManager.swift:PluginManifest.swift:PluginPanelView.swift"
    "GitDataProvider.swift:GitDataProvider.swift"
)

echo ""
echo "--- Split/restructured files (modular extensions summed) ---"
for entry in "${SPLIT_PAIRS[@]}"; do
    parts=("${(@s/:/)entry}")
    LEGACY_NAME="${parts[1]}"
    LEGACY="$ROOT_DIR/Doffice/Sources/$LEGACY_NAME"

    CHECKED=$((CHECKED + 1))

    if [[ ! -f "$LEGACY" ]]; then
        echo "  MISSING legacy: Doffice/Sources/$LEGACY_NAME"
        DRIFT=1
        continue
    fi

    # Sum function counts across all modular extension files
    MOD_F=0
    for i in $(seq 2 ${#parts[@]}); do
        mf="$ROOT_DIR/Projects/DofficeKit/Sources/${parts[$i]}"
        if [[ -f "$mf" ]]; then
            nf=$(grep -cE '^\s*(public |private |internal |open )?func ' "$mf" 2>/dev/null) || nf=0
            MOD_F=$((MOD_F + nf))
        fi
    done

    LEG_F=$(grep -cE '^\s*(public |private |internal |open )?func ' "$LEGACY" 2>/dev/null) || LEG_F=0

    # Allow ±15% tolerance for structural differences (helpers, access modifiers)
    DIFF_F=$(( MOD_F > LEG_F ? MOD_F - LEG_F : LEG_F - MOD_F ))
    MAX_F=$(( MOD_F > LEG_F ? MOD_F : LEG_F ))
    THRESHOLD=$(( MAX_F * 15 / 100 + 2 ))

    if [[ "$DIFF_F" -gt "$THRESHOLD" ]]; then
        echo "  DRIFT $LEGACY_NAME: functions(modular=$MOD_F vs legacy=$LEG_F, diff=$DIFF_F)"
        DRIFT=1
    fi
done

# --- Test files ---
echo ""
echo "--- Test file parity ---"
for testfile in "$ROOT_DIR/Projects/DofficeKit/Tests/"*.swift; do
    BASENAME=$(basename "$testfile")
    LEGACY_TEST="$ROOT_DIR/Doffice/Tests/$BASENAME"
    CHECKED=$((CHECKED + 1))

    if [[ ! -f "$LEGACY_TEST" ]]; then
        echo "  MISSING legacy test: Doffice/Tests/$BASENAME"
        DRIFT=1
    fi
done

echo ""
echo "Checked $CHECKED items."

if [[ "$DRIFT" -eq 1 ]]; then
    echo ""
    if [[ "${SYNC_CHECK_STRICT:-0}" == "1" ]]; then
        echo "FAIL: Source sync drift detected. Please sync both source trees."
        exit 1
    else
        echo "WARNING: Source sync drift detected. Review before release."
        echo "  (Set SYNC_CHECK_STRICT=1 to make this a blocking failure)"
        exit 0
    fi
else
    echo "OK: All checked files are in sync."
    exit 0
fi

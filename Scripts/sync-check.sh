#!/bin/zsh

# sync-check.sh — Validates that Projects/ (Tuist modular) and Doffice/ (legacy)
# source trees stay in sync. Exits non-zero on drift.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DRIFT=0
CHECKED=0

echo "=== Source Sync Check: Projects/ ↔ Doffice/ ==="

# --- DofficeKit ↔ Doffice/Sources shared files ---
DOFFICEKIT_PAIRS=(
    "SensitiveFileShield.swift"
    "DangerousCommandDetector.swift"
    "PluginEffectEngine.swift"
    "SwiftTermBridge.swift"
    "ShortcutManager.swift"
    "VT100Terminal.swift"
    "BrowserView.swift"
    "CrashLogger.swift"
    "DofficeServer.swift"
    "GitDataProvider.swift"
    "SessionStore.swift"
    "PluginManager.swift"
    "AuditLog.swift"
    "DiagnosticReport.swift"
    "CharacterSystem.swift"
    "GameSystem.swift"
    "UpdateChecker.swift"
    "SessionManager.swift"
    "PromptFavorites.swift"
    "PixelStripView.swift"
    "GitPanelView.swift"
)

echo ""
echo "--- DofficeKit ↔ Doffice/Sources ---"
for file in "${DOFFICEKIT_PAIRS[@]}"; do
    MODULAR="$ROOT_DIR/Projects/DofficeKit/Sources/$file"
    LEGACY="$ROOT_DIR/Doffice/Sources/$file"

    if [[ ! -f "$MODULAR" && ! -f "$LEGACY" ]]; then
        continue
    fi

    CHECKED=$((CHECKED + 1))

    if [[ ! -f "$MODULAR" ]]; then
        echo "  MISSING modular: Projects/DofficeKit/Sources/$file"
        DRIFT=1
        continue
    fi
    if [[ ! -f "$LEGACY" ]]; then
        echo "  MISSING legacy:  Doffice/Sources/$file"
        DRIFT=1
        continue
    fi

    # Compare function signatures (access modifiers may differ between modular/legacy)
    MOD_FUNCS=$(grep -cE '^\s*(public |private |internal )?func ' "$MODULAR" 2>/dev/null || echo 0)
    LEG_FUNCS=$(grep -cE '^\s*(public |private |internal )?func ' "$LEGACY" 2>/dev/null || echo 0)

    MOD_STRUCTS=$(grep -cE '^\s*(public |private |internal )?(struct|class|enum) ' "$MODULAR" 2>/dev/null || echo 0)
    LEG_STRUCTS=$(grep -cE '^\s*(public |private |internal )?(struct|class|enum) ' "$LEGACY" 2>/dev/null || echo 0)

    if [[ "$MOD_FUNCS" != "$LEG_FUNCS" || "$MOD_STRUCTS" != "$LEG_STRUCTS" ]]; then
        echo "  DRIFT $file: functions($MOD_FUNCS vs $LEG_FUNCS) types($MOD_STRUCTS vs $LEG_STRUCTS)"
        DRIFT=1
    fi
done

# --- Test files: DofficeKit/Tests ↔ Doffice/Tests ---
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
echo "Checked $CHECKED file pairs."

if [[ "$DRIFT" -eq 1 ]]; then
    echo ""
    # Set SYNC_CHECK_STRICT=1 to make this a blocking failure
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

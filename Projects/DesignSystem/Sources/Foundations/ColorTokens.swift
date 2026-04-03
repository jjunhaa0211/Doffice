import SwiftUI

// ═══════════════════════════════════════════════════════
// MARK: - Color Tokens
// ═══════════════════════════════════════════════════════
//
// 도피스 디자인 시스템 컬러 토큰
//
// 철학:
// - 개발 툴다운 차분함을 유지하면서 깔끔한 neutral gray 톤.
// - 무채색 graphite surface 위에 accent 컬러만 또렷하게.
// - 모든 계층은 depth와 분위기로 구분한다.
// - 텍스트는 오래 봐도 피로하지 않게 softened contrast를 유지한다.

public enum ColorTokens {
    // ── Background Surfaces (4-layer depth system) ──

    /// Layer 0: App background (deepest)
    public static func bg(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.bgHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "111111") : Color(hex: "F5F5F5")
    }

    /// Layer 1: Card / elevated panel
    public static func bgCard(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.bgCardHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "1A1A1A") : Color(hex: "FCFCFC")
    }

    /// Layer 2: Raised surface / nested element
    public static func bgSurface(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.bgSurfaceHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "232323") : Color(hex: "EBEBEB")
    }

    /// Layer 3: Tertiary surface (badges, code blocks)
    public static func bgTertiary(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.bgTertiaryHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "2D2D2D") : Color(hex: "E0E0E0")
    }

    // ── Functional backgrounds ──

    public static func bgTerminal(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.bgHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "0E0E0E") : Color(hex: "F8F8F8")
    }

    public static func bgInput(dark: Bool) -> Color { dark ? Color(hex: "161616") : Color(hex: "FFFFFF") }
    public static func bgHover(dark: Bool) -> Color { dark ? Color(hex: "252525") : Color(hex: "EDEDED") }
    public static func bgSelected(dark: Bool) -> Color { dark ? Color(hex: "2E2E2E") : Color(hex: "E2E2E2") }
    public static func bgPressed(dark: Bool) -> Color { dark ? Color(hex: "353535") : Color(hex: "D8D8D8") }
    public static func bgDisabled(dark: Bool) -> Color { dark ? Color(hex: "141414") : Color(hex: "F2F2F2") }
    public static func bgOverlay(dark: Bool) -> Color { dark ? Color(hex: "000000").opacity(0.74) : Color(hex: "000000").opacity(0.24) }

    // ── Borders (single-weight system: always 1px, vary opacity) ──

    public static func border(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.borderHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "333333") : Color(hex: "D5D5D5")
    }

    public static func borderStrong(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.borderStrongHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "4A4A4A") : Color(hex: "BEBEBE")
    }

    public static func borderActive(dark: Bool) -> Color { dark ? Color(hex: "888888") : Color(hex: "666666") }
    public static func borderSubtle(dark: Bool) -> Color { dark ? Color(hex: "262626") : Color(hex: "E8E8E8") }
    public static let focusRing = Color(hex: "1C80FF").opacity(0.42)

    // ── Text (5-step hierarchy) ──

    public static func textPrimary(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.textPrimaryHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "F0F0F0") : Color(hex: "1A1A1A")
    }

    public static func textSecondary(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.textSecondaryHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "B0B0B0") : Color(hex: "555555")
    }

    public static func textDim(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.textDimHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "808080") : Color(hex: "777777")
    }

    public static func textMuted(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.textMutedHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "5A5A5A") : Color(hex: "A0A0A0")
    }

    public static func textTerminal(dark: Bool) -> Color { dark ? Color(hex: "EEEEEE") : Color(hex: "1A1A1A") }

    // ── System ──

    public static func textOnAccent(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if custom?.accentHex != nil {
            return accent(dark: dark, custom: custom).contrastingTextColor
        }
        return .white
    }

    public static func overlay(dark: Bool) -> Color { dark ? .white : .black }
    public static func overlayBg(dark: Bool) -> Color { dark ? .black : .white }

    // ── Semantic Accents ──

    public static func accent(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.accentHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "4EA5FF") : Color(hex: "156FF7")
    }

    public static func green(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.greenHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "48D5A2") : Color(hex: "149D6D")
    }

    public static func red(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.redHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "FF6B6B") : Color(hex: "E04B55")
    }

    public static func yellow(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.yellowHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "F5C45B") : Color(hex: "C48B16")
    }

    public static func purple(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.purpleHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "9A7CFF") : Color(hex: "705EE8")
    }

    public static func orange(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.orangeHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "FF9B55") : Color(hex: "DB6B1F")
    }

    public static func cyan(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.cyanHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "3FD0E6") : Color(hex: "129DBB")
    }

    public static func pink(dark: Bool, custom: CustomThemeConfig? = nil) -> Color {
        if let hex = custom?.pinkHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "F170B6") : Color(hex: "D44794")
    }

    // ── Accent helpers ──

    public static func accentBg(_ color: Color, dark: Bool) -> Color { color.opacity(dark ? 0.18 : 0.12) }
    public static func accentBorder(_ color: Color, dark: Bool) -> Color { color.opacity(dark ? 0.34 : 0.24) }

    // ── WCAG Contrast Helpers ──

    /// Check if two colors meet WCAG AA contrast ratio (4.5:1 for normal text)
    public static func meetsContrastAA(foreground: Color, background: Color) -> Bool {
        contrastRatio(foreground, background) >= 4.5
    }

    /// Check if two colors meet WCAG AAA contrast ratio (7:1)
    public static func meetsContrastAAA(foreground: Color, background: Color) -> Bool {
        contrastRatio(foreground, background) >= 7.0
    }

    /// Calculate WCAG contrast ratio between two colors
    public static func contrastRatio(_ c1: Color, _ c2: Color) -> Double {
        let l1 = c1.luminance
        let l2 = c2.luminance
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    // ── Worker Colors (pixel world) ──

    public static func workerColors(dark: Bool) -> [Color] {
        dark ? [
            Color(hex: "ee7878"), Color(hex: "68d498"), Color(hex: "eebb50"),
            Color(hex: "70b0ee"), Color(hex: "c08ce6"), Color(hex: "ee9858"),
            Color(hex: "58ccbb"), Color(hex: "ee78bb")
        ] : [
            Color(hex: "d04848"), Color(hex: "259248"), Color(hex: "b88000"),
            Color(hex: "2260d0"), Color(hex: "6a40d0"), Color(hex: "c86020"),
            Color(hex: "0a8888"), Color(hex: "c84080")
        ]
    }
}

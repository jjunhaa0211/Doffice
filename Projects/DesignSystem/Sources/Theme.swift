import SwiftUI

// ═══════════════════════════════════════════════════════
// MARK: - Theme (동적 테마)
// ═══════════════════════════════════════════════════════

public enum Theme {
    private static var _cachedDark: Bool = false
    private static var _cachedIsCustom: Bool = false
    private static var _cachedCustomConfig: CustomThemeConfig?
    private static var _cacheValid: Bool = false

    private static var _lastDarkValue: Bool = false
    private static var _lastThemeMode: String = ""

    private static func ensureCache() {
        guard !_cacheValid else { return }
        let settings = AppSettings.shared
        let newDark = settings.isDarkMode
        let newThemeMode = settings.themeMode
        let themeChanged = newDark != _lastDarkValue || newThemeMode != _lastThemeMode
        _cachedDark = newDark
        _cachedIsCustom = newThemeMode == "custom"
        _cachedCustomConfig = _cachedIsCustom ? settings.customTheme : nil
        _lastDarkValue = newDark
        _lastThemeMode = newThemeMode
        if themeChanged { _fontCache.removeAll() }
        _cacheValid = true
        DispatchQueue.main.async { _cacheValid = false }
    }

    private static var dark: Bool { ensureCache(); return _cachedDark }
    static var isCustomMode: Bool { ensureCache(); return _cachedIsCustom }
    private static var cachedCustomConfig: CustomThemeConfig? { ensureCache(); return _cachedCustomConfig }

    private static var scale: CGFloat { CGFloat(AppSettings.shared.fontSizeScale) }
    /// UI 크롬(툴바, 사이드바, 필터 등)용 완화된 스케일 — 콘텐츠보다 덜 커짐
    private static var chromeScale: CGFloat { 1 + (scale - 1) * 0.5 }

    // ── Font Cache ──
    private static var _fontCache: [String: Font] = [:]

    private static func cachedFont(key: String, create: () -> Font) -> Font {
        if let cached = _fontCache[key] { return cached }
        let font = create()
        _fontCache[key] = font
        return font
    }

    /// Clear font cache (call when font settings change)
    public static func invalidateFontCache() {
        _fontCache.removeAll()
    }

    // ═══════════════════════════════════════════════════════
    // 도피스 디자인 시스템 (Vercel Geist 재해석)
    //
    // 철학: 도피스의 세계관 + Vercel급 컴포넌트 정제도
    // - 순수 블랙/그레이스케일 surface 계층
    // - 얇은 1px border로 구조 표현, 그림자 없음
    // - 색상은 상태 표시에만 절제하여 사용
    // - UI는 산세리프, 코드/터미널만 monospaced
    // - 도트 캐릭터 영역은 그대로 보존
    // ═══════════════════════════════════════════════════════

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 1. COLOR TOKENS
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // ── Background Surfaces (4-layer depth system) ──
    // Layer 0: App background (deepest)
    public static var bg: Color {
        if let config = cachedCustomConfig, let hex = config.bgHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "000000") : Color(hex: "fafafa")
    }
    // Layer 1: Card / elevated panel
    public static var bgCard: Color {
        if let config = cachedCustomConfig, let hex = config.bgCardHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "0a0a0a") : Color(hex: "ffffff")
    }
    // Layer 2: Raised surface / nested element
    public static var bgSurface: Color {
        if let config = cachedCustomConfig, let hex = config.bgSurfaceHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "111111") : Color(hex: "f5f5f5")
    }
    // Layer 3: Tertiary surface (badges, code blocks)
    public static var bgTertiary: Color {
        if let config = cachedCustomConfig, let hex = config.bgTertiaryHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "1a1a1a") : Color(hex: "ebebeb")
    }

    // ── Functional backgrounds ──
    public static var bgTerminal: Color {
        if let config = cachedCustomConfig, let hex = config.bgHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "0a0a0a") : Color(hex: "fafafa")
    }
    public static var bgInput: Color { dark ? Color(hex: "000000") : Color(hex: "ffffff") }
    public static var bgHover: Color { dark ? Color(hex: "1a1a1a") : Color(hex: "f0f0f0") }
    public static var bgSelected: Color { dark ? Color(hex: "1a1a1a") : Color(hex: "eaeaea") }
    public static var bgPressed: Color { dark ? Color(hex: "222222") : Color(hex: "e5e5e5") }
    public static var bgDisabled: Color { dark ? Color(hex: "0a0a0a") : Color(hex: "f5f5f5") }
    public static var bgOverlay: Color { dark ? Color(hex: "000000").opacity(0.7) : Color(hex: "000000").opacity(0.4) }

    // ── Borders (single-weight system: always 1px, vary opacity) ──
    public static var border: Color {
        if let config = cachedCustomConfig, let hex = config.borderHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "282828") : Color(hex: "e5e5e5")
    }
    public static var borderStrong: Color {
        if let config = cachedCustomConfig, let hex = config.borderStrongHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "3e3e3e") : Color(hex: "d0d0d0")
    }
    public static var borderActive: Color { dark ? Color(hex: "555555") : Color(hex: "999999") }
    public static var borderSubtle: Color { dark ? Color(hex: "1e1e1e") : Color(hex: "eeeeee") }
    public static var focusRing: Color { Color(hex: "0070f3").opacity(0.5) }

    // ── Text (5-step hierarchy) ──
    public static var textPrimary: Color {
        if let config = cachedCustomConfig, let hex = config.textPrimaryHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "ededed") : Color(hex: "171717")
    }
    public static var textSecondary: Color {
        if let config = cachedCustomConfig, let hex = config.textSecondaryHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "a1a1a1") : Color(hex: "636363")
    }
    public static var textDim: Color {
        if let config = cachedCustomConfig, let hex = config.textDimHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "707070") : Color(hex: "8f8f8f")
    }
    public static var textMuted: Color {
        if let config = cachedCustomConfig, let hex = config.textMutedHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "484848") : Color(hex: "b0b0b0")
    }
    public static var textTerminal: Color { dark ? Color(hex: "ededed") : Color(hex: "171717") }

    // ── System ──
    public static var textOnAccent: Color {
        if let config = cachedCustomConfig, config.accentHex != nil {
            return accent.contrastingTextColor
        }
        return .white
    }
    public static var overlay: Color { dark ? .white : .black }
    public static var overlayBg: Color { dark ? .black : .white }

    // ── Semantic Accents ──
    public static var accent: Color {
        if let config = cachedCustomConfig, let hex = config.accentHex, !hex.isEmpty {
            return Color(hex: hex)
        }
        return dark ? Color(hex: "3291ff") : Color(hex: "0070f3")
    }
    public static var green: Color {
        if let config = cachedCustomConfig, let hex = config.greenHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "3ecf8e") : Color(hex: "18a058")
    }
    public static var red: Color {
        if let config = cachedCustomConfig, let hex = config.redHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "f14c4c") : Color(hex: "e5484d")
    }
    public static var yellow: Color {
        if let config = cachedCustomConfig, let hex = config.yellowHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "f5a623") : Color(hex: "ca8a04")
    }
    public static var purple: Color {
        if let config = cachedCustomConfig, let hex = config.purpleHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "8e4ec6") : Color(hex: "6e56cf")
    }
    public static var orange: Color {
        if let config = cachedCustomConfig, let hex = config.orangeHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "f97316") : Color(hex: "e5560a")
    }
    public static var cyan: Color {
        if let config = cachedCustomConfig, let hex = config.cyanHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "06b6d4") : Color(hex: "0891b2")
    }
    public static var pink: Color {
        if let config = cachedCustomConfig, let hex = config.pinkHex, !hex.isEmpty { return Color(hex: hex) }
        return dark ? Color(hex: "e54d9e") : Color(hex: "d23197")
    }

    // ── Semantic accent backgrounds (soft fills for badges/indicators) ──
    public static func accentBg(_ color: Color) -> Color { color.opacity(dark ? 0.12 : 0.08) }
    public static func accentBorder(_ color: Color) -> Color { color.opacity(dark ? 0.25 : 0.2) }

    /// 그라데이션 또는 단색 accent 배경 (AnyShapeStyle) — Custom 모드에서만 그라데이션 적용
    public static var accentBackground: AnyShapeStyle {
        if let config = cachedCustomConfig {
            if config.useGradient,
               let startHex = config.gradientStartHex, !startHex.isEmpty,
               let endHex = config.gradientEndHex, !endHex.isEmpty {
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [Color(hex: startHex), Color(hex: endHex)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            }
        }
        return AnyShapeStyle(accent)
    }

    /// 소프트 그라데이션 배경 (낮은 opacity) — 비 prominent accent 버튼 등에 사용
    public static var accentSoftBackground: AnyShapeStyle {
        if let config = cachedCustomConfig {
            if config.useGradient,
               let startHex = config.gradientStartHex, !startHex.isEmpty,
               let endHex = config.gradientEndHex, !endHex.isEmpty {
                let opacity = dark ? 0.14 : 0.10
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [Color(hex: startHex).opacity(opacity), Color(hex: endHex).opacity(opacity)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            }
        }
        return AnyShapeStyle(accentBg(accent))
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 2. TYPOGRAPHY SYSTEM
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //
    // UI text: system sans-serif (.default)
    // Code/terminal/git hash: monospaced (.monospaced)
    // Pixel world labels: monospaced bold (preserved)
    //
    // Scale hierarchy:
    //   display: 18   title: 14   heading: 12   body: 11
    //   small: 10     micro: 9    tiny: 8

    // Pre-scaled convenience fonts
    public static var monoTiny: Font { .system(size: round(8 * scale), design: .monospaced) }
    public static var monoSmall: Font { .system(size: round(10 * scale), design: .monospaced) }
    public static var monoNormal: Font { .system(size: round(12 * scale), design: .monospaced) }
    public static var monoBold: Font { .system(size: round(11 * scale), weight: .semibold, design: .monospaced) }
    public static var pixel: Font { .system(size: round(8 * chromeScale), weight: .bold, design: .monospaced) }

    /// 커스텀 테마에서 fontSize가 설정되어 있으면 해당 스케일 사용
    private static var customScale: CGFloat? {
        guard let config = cachedCustomConfig, let fs = config.fontSize, fs > 0 else { return nil }
        return CGFloat(fs / 11.0)
    }

    /// Primary UI text (Geist Sans equivalent — system san-serif)
    public static func mono(_ baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        let key = "mono-\(baseSize)-\(weight.hashValue)"
        return cachedFont(key: key) {
            let effectiveScale = customScale ?? scale
            if let config = cachedCustomConfig, let fontName = config.fontName, !fontName.isEmpty {
                return Font.custom(fontName, size: round(baseSize * effectiveScale)).weight(weight)
            }
            return .system(size: round(baseSize * effectiveScale), weight: weight, design: .default)
        }
    }

    /// Code, terminal, git hashes, file paths — 커스텀 폰트 미적용 (항상 monospaced)
    public static func code(_ baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        let key = "code-\(baseSize)-\(weight.hashValue)"
        return cachedFont(key: key) {
            .system(size: round(baseSize * scale), weight: weight, design: .monospaced)
        }
    }

    /// General scaled font
    public static func scaled(_ baseSize: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        let key = "scaled-\(baseSize)-\(weight.hashValue)-\(design.hashValue)"
        return cachedFont(key: key) {
            let effectiveScale = customScale ?? scale
            if let config = cachedCustomConfig, let fontName = config.fontName, !fontName.isEmpty, design == .default {
                return Font.custom(fontName, size: round(baseSize * effectiveScale)).weight(weight)
            }
            return .system(size: round(baseSize * effectiveScale), weight: weight, design: design)
        }
    }

    /// Chrome-only font (sidebar, toolbar — less aggressive scaling)
    public static func chrome(_ baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        let key = "chrome-\(baseSize)-\(weight.hashValue)"
        return cachedFont(key: key) {
            let effectiveChromeScale: CGFloat = {
                if let cs = customScale { return 1 + (cs - 1) * 0.5 }
                return chromeScale
            }()
            if let config = cachedCustomConfig, let fontName = config.fontName, !fontName.isEmpty {
                return Font.custom(fontName, size: round(baseSize * effectiveChromeScale)).weight(weight)
            }
            return .system(size: round(baseSize * effectiveChromeScale), weight: weight, design: .default)
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 3. SPACING & SIZING
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //
    // 4px base grid. All spacing in multiples of 4.
    //
    // Naming: sp1=4, sp2=8, sp3=12, sp4=16, sp5=20, sp6=24, sp8=32

    public static let sp1: CGFloat = 4
    public static let sp2: CGFloat = 8
    public static let sp3: CGFloat = 12
    public static let sp4: CGFloat = 16
    public static let sp5: CGFloat = 20
    public static let sp6: CGFloat = 24
    public static let sp8: CGFloat = 32

    // Row heights
    public static let rowCompact: CGFloat = 28     // dense list rows, sidebar items
    public static let rowDefault: CGFloat = 36     // standard list rows, table rows
    public static let rowComfortable: CGFloat = 44 // touch-friendly / spacious rows

    // Panel padding
    public static let panelPadding: CGFloat = 16
    public static let cardPadding: CGFloat = 12
    public static let toolbarHeight: CGFloat = 36
    public static let sidebarItemHeight: CGFloat = 30

    // Icon sizes
    public static func iconSize(_ baseSize: CGFloat) -> CGFloat { round(baseSize * scale) }
    public static func chromeIconSize(_ baseSize: CGFloat) -> CGFloat { round(baseSize * chromeScale) }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 4. RADIUS / BORDER / SURFACE
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //
    // Radius: tight and precise, never bubbly
    // Border: always 1px, full color (no opacity tricks)
    // Shadow: none (depth = border + surface color)

    public static let cornerSmall: CGFloat = 5     // badges, tags, small chips
    public static let cornerMedium: CGFloat = 6    // buttons, inputs, select
    public static let cornerLarge: CGFloat = 8     // cards, panels, dialogs
    public static let cornerXL: CGFloat = 12       // modals, sheets, large containers

    // Border defaults (for modifier compatibility)
    public static let borderDefault: CGFloat = 1.0
    public static let borderActiveOpacity: CGFloat = 1.0
    public static let borderLight: CGFloat = 0.6

    // Interaction state opacities (consistent across all components)
    public static let hoverOpacity: CGFloat = 0.08
    public static let activeOpacity: CGFloat = 0.12
    public static let strokeActiveOpacity: CGFloat = 0.25
    public static let strokeInactiveOpacity: CGFloat = 0.15

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 5. PRESERVED TOKENS (pixel world)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    public static var workerColors: [Color] {
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

    public static var bgGradient: LinearGradient {
        dark ? LinearGradient(colors: [Color(hex: "000000"), Color(hex: "0a0a0a")], startPoint: .top, endPoint: .bottom)
             : LinearGradient(colors: [Color(hex: "ffffff"), Color(hex: "fafafa")], startPoint: .top, endPoint: .bottom)
    }
}

public enum AppChromeTone: Equatable {
    case neutral
    case accent
    case green
    case red
    case yellow
    case purple
    case cyan
    case orange

    public var color: Color {
        switch self {
        case .neutral: return Theme.textSecondary
        case .accent: return Theme.accent
        case .green: return Theme.green
        case .red: return Theme.red
        case .yellow: return Theme.yellow
        case .purple: return Theme.purple
        case .cyan: return Theme.cyan
        case .orange: return Theme.orange
        }
    }
}

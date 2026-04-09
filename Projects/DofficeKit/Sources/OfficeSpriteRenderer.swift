import SwiftUI
import DesignSystem
import OrderedCollections

// ═══════════════════════════════════════════════════════
// MARK: - Office Sprite Renderer (Z-sorted Canvas)
// ═══════════════════════════════════════════════════════

public struct OfficeSpriteRenderer {
    public let map: OfficeMap
    public let characters: [String: OfficeCharacter]
    public let tabs: [TerminalTab]
    public let frame: Int
    public let dark: Bool
    public let theme: BackgroundTheme
    public let selectedTabId: String?
    public let selectedFurnitureId: String?
    public var chromeScreenshots: [String: CGImage] = [:]  // tabId → chrome screenshot
    public let officeCat: OfficeCat?
    /// Pre-built tab lookup table — avoids O(n) tabs.first(where:) per character
    internal let tabLookup: [String: TerminalTab]

    public init(map: OfficeMap, characters: [String: OfficeCharacter], tabs: [TerminalTab],
         frame: Int, dark: Bool, theme: BackgroundTheme,
         selectedTabId: String?, selectedFurnitureId: String?,
         officeCat: OfficeCat? = nil) {
        self.init(map: map, characters: characters, tabs: tabs,
                  frame: frame, dark: dark, theme: theme,
                  selectedTabId: selectedTabId, selectedFurnitureId: selectedFurnitureId,
                  officeCat: officeCat,
                  cachedPalette: OfficeScenePalette(theme: theme, dark: dark))
    }

    /// Init with a pre-built palette to avoid recomputing it every frame.
    public init(map: OfficeMap, characters: [String: OfficeCharacter], tabs: [TerminalTab],
         frame: Int, dark: Bool, theme: BackgroundTheme,
         selectedTabId: String?, selectedFurnitureId: String?,
         officeCat: OfficeCat? = nil,
         cachedPalette: OfficeScenePalette) {
        self.map = map
        self.characters = characters
        self.tabs = tabs
        self.frame = frame
        self.dark = dark
        self.theme = theme
        self.selectedTabId = selectedTabId
        self.selectedFurnitureId = selectedFurnitureId
        self.officeCat = officeCat
        self.palette = cachedPalette
        // Build O(1) tab lookup once instead of O(n) per character
        var lookup: [String: TerminalTab] = [:]
        lookup.reserveCapacity(tabs.count)
        for tab in tabs { lookup[tab.id] = tab }
        self.tabLookup = lookup
    }

    // Sprite cache: OrderedDictionary for LRU eviction (oldest = first entries)
    internal static var spriteCache: OrderedDictionary<String, CharacterSpriteSet> = [:]

    // Reusable Z-sort buffer — avoids per-frame heap allocation
    internal static var zBuffer: [ZDrawable] = []

    // Pre-allocated bubble text arrays to avoid per-frame allocation
    internal static let greetTexts0 = ["(ᵔᴥᵔ)", "ヾ(＾∇＾)", "(◕‿◕)", "\\(^o^)/"]
    internal static let greetTexts1 = ["(＾▽＾)", "(｡◕‿◕｡)", "٩(◕‿◕)۶", "(づ｡◕‿‿◕｡)づ"]
    internal static let chatTexts0 = ["(¬‿¬)", "ᕕ(ᐛ)ᕗ", "(•̀ᴗ•́)و", "( ˘▽˘)っ♨"]
    internal static let chatTexts1 = ["(≧◡≦)", "ʕ•ᴥ•ʔ", "(ノ◕ヮ◕)ノ*:・゚✧", "٩(♡ε♡)۶"]
    internal static let brainTexts0 = ["(°ロ°)☝", "φ(._.)メモメモ", "(⌐■_■)", "ᕦ(ò_óˇ)ᕤ"]
    internal static let brainTexts1 = ["(☞ﾟ∀ﾟ)☞", "( •_•)>⌐■-■", "ψ(._. )>", "(╯°□°)╯︵ ┻━┻"]
    internal static let coffeeTexts0 = ["☕(◕‿◕)", "(っ˘ω˘c)♨", "( ˘⌣˘)❤☕", "✧(˘⌣˘)☕"]
    internal static let coffeeTexts1 = ["(⊃˘▽˘)⊃☕", "☕(⌐■_■)", "(´∀`)♨", "☕✧(◕‿◕✿)"]
    internal static let highFiveTexts0 = ["(つ≧▽≦)つ", "ε=ε=(ノ≧∇≦)ノ", "(ﾉ◕ヮ◕)ﾉ*:・゚✧", "( •̀ω•́ )σ"]
    internal static let highFiveTexts1 = ["⊂(◉‿◉)つ", "(ノ´ヮ`)ノ*: ・゚✧", "\\(★ω★)/", "(*≧▽≦)ノシ"]
    internal static let arguingTexts0 = ["(ノಠ益ಠ)ノ", "(╬ Ò﹏Ó)", "ᕦ(ò_óˇ)ᕤ!", "( •̀ω•́ )☝"]
    internal static let arguingTexts1 = ["(¬_¬\")", "(ー_ー゛)", "ψ(｀∇´)ψ", "(눈_눈)"]
    internal static let nappingTexts0 = ["(-_-) zzZ", "(˘ω˘) zzz", "(-.-)Zzz..", "(¦3[▓▓]"]
    internal static let nappingTexts1 = ["(∪｡∪)｡｡｡", "(´-﹃-`)Zz", "₍ᐢ..ᐢ₎zzz", "(˘εз˘)"]
    internal static let dancingTexts0 = ["♪(┌・。・)┌", "♪ ₍₍(ง˘ω˘)ว⁾⁾♪", "┏(＾0＾)┛♪", "~(˘▽˘~)"]
    internal static let dancingTexts1 = ["(~˘▽˘)~♪", "♪♪♪(∇⌒ヽ)", "ᕕ(⌐■_■)ᕗ♪", "└(^o^ )Ｘ"]
    internal static let snackingTexts0 = ["🍩(◕ᴗ◕✿)", "🍪 ᵐᵐᵐ", "🍕(⌒▽⌒)", "( ˘ᴗ˘ )🧁"]
    internal static let snackingTexts1 = ["(ᵔᴥᵔ)🍫", "🥤(◕‿◕)", "🍿(≧◡≦)", "🍜(˘ω˘)"]
    internal static let photoTimeTexts0 = ["📸✧ᵕ̈", "🤳(◕‿◕✿)", "📸✌('ω'✌ )", "📷(⌐■_■)"]
    internal static let photoTimeTexts1 = ["✌(◕‿-)✌", "(＾▽＾)📸", "✨📸✨", "✌('ω')✌"]
    internal static let flirtingTexts0 = ["(⁄ ⁄•⁄ω⁄•⁄ ⁄)", "♡(◕‿◕✿)", "(˶ᵔ ᵕ ᵔ˶)♡", "(⸝⸝⸝´꒳`⸝⸝⸝)"]
    internal static let flirtingTexts1 = ["(◍•ᴗ•◍)❤", "♡(⁰▿⁰)♡", "(≧◡≦)♡", "(*˘︶˘*).。.:*♡"]
    internal static let pettingCatTexts0 = ["🐱♡", "(=^・ω・^=)", "ᓚᘏᗢ♡", "🐾(◕‿◕✿)"]
    internal static let pettingCatTexts1 = ["🐈✧", "(ΦωΦ)♡", "ᓚᘏᗢ~", "🐱(˘ω˘)"]
    // 고양이 전용 리액션
    internal static let catReactions = ["ᓚᘏᗢ", "=^.^=", "🐾", "(=^‥^=)"]
    internal static let catSleepReactions = ["ᓚᘏᗢzzz", "(=˘ω˘=)zzz", "₍˄·͈˶·͈˄₎zzz"]
    internal static let catPettedReactions = ["ᓚᘏᗢ♡", "ᵖᵘʳʳ~♡", "(=^-ω-^=)♡", "ᓚᘏᗢ~nyaa"]
    // 캐릭터가 고양이를 쓰다듬을 때 리액션
    internal static let pettingReactions = ["🐱♡ᵃʷ~", "(◕‿◕)🐾", "ᓚᘏᗢ so soft", "🐈✧ᶜᵘᵗᵉ"]

    // 가구 상호작용 전용 리액션
    internal static let coffeeInteractionReactions = ["☕ᵃʰʰ~", "☕(˘ω˘)", "☕✧", "( ˘⌣˘)☕♨"]
    internal static let waterInteractionReactions = ["💧ᵍˡᵘᵍ", "💦(◕‿◕)", "🥤ᵖᵘʰᵃ", "💧✧"]
    internal static let bookInteractionReactions = ["📖(ᵔᴥᵔ)", "📚hmm..", "📖ᶠˡⁱᵖ", "📕✧"]
    internal static let sofaInteractionReactions = ["(˘ω˘)~♡", "ᵃʰʰ~ ☁", "(-ω-)~♡", "✧ᶠˡᵘᶠᶠʸ"]
    internal static let printerInteractionReactions = ["🖨ᵇʳʳ", "🖨..⏳", "📄✓!", "🖨✧ᵈᵒⁿᵉ"]
    internal static let whiteboardInteractionReactions = ["📋hmm", "✏️(·_·)", "💡!", "📋✓"]
    internal static let trashInteractionReactions = ["🗑ᵖᵒⁱ", "🗑✓", "( ˘▽˘)🗑", "🗑✧"]
    internal static let plantInteractionReactions = ["🌿💧", "🌱✧", "🪴(◕‿◕)", "🌿ᵍʳᵒʷ"]
    // 축하 반응 전용 리액션
    internal static let celebrationReactReactions = ["👏✧", "🥳!", "\\(◕‿◕)/", "🎊✧"]

    // Pre-allocated activity reaction arrays to avoid per-frame allocation
    internal static let typingReactions = ["⌨️ ᵗᵃᵏ", "✎ ᵗᵃᵏ", "⌨ᵈᵃᵈᵃ", "⚡⌨⚡"]
    internal static let readingReactions = ["📖...", "🔍hmm", "👀...", "📄✓"]
    internal static let searchingReactions = ["🔎...", "🧐?", "🗂️...", "📂✓"]
    internal static let errorReactions = ["(╥_╥)", "╥﹏╥", "(ᗒᗣᗕ)՞", "( ꈨ◞ )"]
    internal static let thinkingReactions = ["(·_·)", "🤔...", "φ(._.)", "(ᵕ≀ᵕ)"]
    internal static let celebratingReactions = ["🎉✧", "\\(ᵔᵕᵔ)/", "٩(◕‿◕)۶", "★彡"]
    internal static let idleReactions = ["(¬_¬)", "(-_-) zzZ", "(˘ω˘)", "( ˙꒳˙ )"]
    internal static let windowColumns: Set<Int> = [3, 4, 5, 9, 10, 11, 15, 16, 17, 21, 22, 23, 31, 32, 33, 37, 38, 39]
    /// Computed once per renderer creation, not per property access
    public let palette: OfficeScenePalette

    // Static background cache: avoids redrawing ~8000 floor/wall draw calls every frame
    private static var cachedBackgroundImage: CGImage?
    private static var cachedBackgroundKey: String = ""
    private static let staticCachedTypes: Set<FurnitureType> = [.rug, .bookshelf, .whiteboard, .pictureFrame, .clock]
    public static func usesStaticBackgroundCache(for type: FurnitureType) -> Bool {
        staticCachedTypes.contains(type)
    }

    // MARK: - Main Render

    public func render(context: GraphicsContext, scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        renderStaticBackground(context: context, scale: scale, offsetX: offsetX, offsetY: offsetY)
        renderDynamicLayers(context: context, scale: scale, offsetX: offsetX, offsetY: offsetY)
    }

    public func renderStaticBackground(context: GraphicsContext, scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        let cacheKey = "\(theme.rawValue)-\(dark)-\(map.cols)-\(map.rows)"

        if cacheKey == Self.cachedBackgroundKey, let cached = Self.cachedBackgroundImage {
            var ctx = context
            ctx.translateBy(x: offsetX, y: offsetY)
            ctx.scaleBy(x: scale, y: scale)
            ctx.draw(
                Image(decorative: cached, scale: 1),
                in: CGRect(x: 0, y: 0,
                           width: CGFloat(map.cols) * 16,
                           height: CGFloat(map.rows) * 16)
            )
            return
        }

        // Cache miss — draw normally into the live context
        var ctx = context
        ctx.translateBy(x: offsetX, y: offsetY)
        ctx.scaleBy(x: scale, y: scale)
        drawBackdrop(ctx)
        drawFloorTiles(ctx)
        drawWindowLight(ctx)
        drawWalls(ctx)
        drawCachedStaticFurniture(ctx)

        // Generate cached CGImage for subsequent frames
        Task { @MainActor in
            Self.generateBackgroundCache(map: map, dark: dark, theme: theme, cacheKey: cacheKey)
        }
    }

    /// Renders the static background into an offscreen CGImage via ImageRenderer.
    @MainActor private static func generateBackgroundCache(map: OfficeMap, dark: Bool, theme: BackgroundTheme, cacheKey: String) {
        let size = CGSize(
            width: CGFloat(map.cols) * 16,
            height: CGFloat(map.rows) * 16
        )
        let snapshotView = Canvas { context, _ in
            let renderer = OfficeSpriteRenderer(
                map: map,
                characters: [:],
                tabs: [],
                frame: 0,
                dark: dark,
                theme: theme,
                selectedTabId: nil,
                selectedFurnitureId: nil
            )
            renderer.drawBackdrop(context)
            renderer.drawFloorTiles(context)
            renderer.drawWindowLight(context)
            renderer.drawWalls(context)
            renderer.drawCachedStaticFurniture(context)
        }
        .frame(width: size.width, height: size.height)

        let imageRenderer = ImageRenderer(content: snapshotView)
        imageRenderer.scale = 1
        if let cgImage = imageRenderer.cgImage {
            cachedBackgroundImage = cgImage
            cachedBackgroundKey = cacheKey
        }
    }

    /// Invalidates the static background cache (call when theme or layout changes).
    public static func invalidateBackgroundCache() {
        cachedBackgroundImage = nil
        cachedBackgroundKey = ""
    }

    public func renderDynamicLayers(context: GraphicsContext, scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        var ctx = context
        ctx.translateBy(x: offsetX, y: offsetY)
        ctx.scaleBy(x: scale, y: scale)
        drawZSortedScene(ctx)
        drawOfficeCat(ctx)
        drawOverlays(ctx, viewScale: scale)
    }

    private func drawOfficeCat(_ ctx: GraphicsContext) {
        guard let cat = officeCat else { return }

        let catEmoji: String
        let catSize: CGFloat
        switch cat.state {
        case .sleeping:
            catEmoji = "🐱💤"
            catSize = 7
        case .stretching:
            let phase = (frame / 8) % 2
            catEmoji = phase == 0 ? "🐱" : "🙀"
            catSize = 7
        case .beingPetted:
            catEmoji = "😻"
            catSize = 7
        case .playing:
            let phase = (frame / 6) % 3
            catEmoji = ["🐱", "🙀", "😺"][phase]
            catSize = 7
        default:
            catEmoji = "🐱"
            catSize = 6.5
        }

        // 그림자
        let shadowRect = CGRect(x: cat.pixelX - 4, y: cat.pixelY - 1, width: 8, height: 3)
        ctx.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(dark ? 0.15 : 0.08)))

        // 고양이 이모지
        ctx.draw(
            Text(catEmoji).font(.system(size: catSize)),
            at: CGPoint(x: cat.pixelX, y: cat.pixelY - 6)
        )

        // 고양이 리액션 버블
        let cycle = frame % Int(OfficeConstants.fps * 5)
        if cycle < Int(OfficeConstants.fps * 1.5) {
            let reactions: [String]
            let color: Color
            switch cat.state {
            case .sleeping:
                reactions = Self.catSleepReactions
                color = Color(hex: "8090B0")
            case .beingPetted:
                reactions = Self.catPettedReactions
                color = Color(hex: "F08090")
            default:
                reactions = Self.catReactions
                color = Color(hex: "E8B870")
            }
            let text = reactions[frame / 18 % reactions.count]
            ctx.draw(
                Text(text).font(.system(size: 4.5, weight: .medium)).foregroundColor(color),
                at: CGPoint(x: cat.pixelX, y: cat.pixelY - 18)
            )
        }
    }
}

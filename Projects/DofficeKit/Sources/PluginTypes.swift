import Foundation
import SwiftUI

// ═══════════════════════════════════════════════════════
// MARK: - Plugin Manager (Homebrew 플러그인 관리)
// ═══════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════
// MARK: - Registry Item (마켓플레이스 항목)
// ═══════════════════════════════════════════════════════

/// 원격 레지스트리에 등록된 플러그인 (GitHub registry.json)
// MARK: - Marketplace Enums

public enum PluginCategory: String, CaseIterable, Identifiable {
    case all, themes, characters, commands, effects

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .all: return NSLocalizedString("plugin.category.all", comment: "")
        case .themes: return NSLocalizedString("plugin.category.themes", comment: "")
        case .characters: return NSLocalizedString("plugin.category.characters", comment: "")
        case .commands: return NSLocalizedString("plugin.category.commands", comment: "")
        case .effects: return NSLocalizedString("plugin.category.effects", comment: "")
        }
    }

    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .themes: return "paintpalette.fill"
        case .characters: return "person.2.fill"
        case .commands: return "terminal"
        case .effects: return "sparkles"
        }
    }

    public func matches(_ tags: [String]) -> Bool {
        guard self != .all else { return true }
        return tags.contains { $0.lowercased() == rawValue || $0.lowercased().contains(rawValue.dropLast()) }
    }
}

public enum PluginSortOption: String, CaseIterable, Identifiable {
    case popular, newest, alphabetical

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .popular: return NSLocalizedString("plugin.sort.popular", comment: "")
        case .newest: return NSLocalizedString("plugin.sort.newest", comment: "")
        case .alphabetical: return NSLocalizedString("plugin.sort.alphabetical", comment: "")
        }
    }
}

public enum PluginTemplate: String, CaseIterable, Identifiable {
    case themePack, commandPack, effectPack, fullPlugin

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .themePack: return NSLocalizedString("plugin.template.theme", comment: "")
        case .commandPack: return NSLocalizedString("plugin.template.command", comment: "")
        case .effectPack: return NSLocalizedString("plugin.template.effect", comment: "")
        case .fullPlugin: return NSLocalizedString("plugin.template.full", comment: "")
        }
    }

    public var icon: String {
        switch self {
        case .themePack: return "paintpalette.fill"
        case .commandPack: return "terminal.fill"
        case .effectPack: return "sparkles"
        case .fullPlugin: return "puzzlepiece.fill"
        }
    }

    public var description: String {
        switch self {
        case .themePack: return NSLocalizedString("plugin.template.theme.desc", comment: "")
        case .commandPack: return NSLocalizedString("plugin.template.command.desc", comment: "")
        case .effectPack: return NSLocalizedString("plugin.template.effect.desc", comment: "")
        case .fullPlugin: return NSLocalizedString("plugin.template.full.desc", comment: "")
        }
    }

    public var tint: String {
        switch self {
        case .themePack: return "purple"
        case .commandPack: return "cyan"
        case .effectPack: return "orange"
        case .fullPlugin: return "green"
        }
    }

    public var scaffoldOptions: PluginManager.ScaffoldOptions {
        switch self {
        case .themePack:
            return .init(includeHooks: false, includeSlashCommands: false, includeCharacters: true, includeSettings: false, includePanel: false, includeThemes: true, includeEffects: false, includeFurniture: true)
        case .commandPack:
            return .init(includeHooks: true, includeSlashCommands: true, includeCharacters: false, includeSettings: true, includePanel: false, includeThemes: false, includeEffects: false, includeFurniture: false)
        case .effectPack:
            return .init(includeHooks: false, includeSlashCommands: false, includeCharacters: false, includeSettings: false, includePanel: false, includeThemes: false, includeEffects: true, includeFurniture: false)
        case .fullPlugin:
            return .init(includeHooks: true, includeSlashCommands: true, includeCharacters: true, includeSettings: true, includePanel: true, includeThemes: true, includeEffects: true, includeFurniture: true)
        }
    }
}

// MARK: - Debug Entry

public struct PluginDebugEntry: Identifiable {
    public let id = UUID()
    public let timestamp = Date()
    public let level: Level
    public let source: String
    public let message: String

    public enum Level: String {
        case info, warning, error, event, effect
    }
}

public struct RegistryPlugin: Codable, Identifiable, Equatable {
    public let id: String              // 고유 식별자
    public var name: String            // 표시 이름
    public var author: String          // 제작자
    public var description: String     // 설명
    public var version: String         // 최신 버전
    public var downloadURL: String     // tar.gz / zip 다운로드 URL
    public var characterCount: Int     // 포함된 캐릭터 수
    public var tags: [String]          // 태그 (예: ["cat", "pixel-art", "korean"])
    public var previewImageURL: String? // 미리보기 이미지 URL (옵션)
    public var stars: Int?             // 인기도 (옵션)
}

/// 플러그인 메타데이터
public struct PluginEntry: Codable, Identifiable, Equatable {
    public let id: String          // UUID
    public var name: String        // 표시 이름
    public var source: String      // brew formula 또는 tap URL (예: "user/tap/formula")
    public var localPath: String   // 설치된 로컬 경로
    public var version: String     // 버전
    public var installedAt: Date
    public var enabled: Bool
    public var sourceType: SourceType

    public enum SourceType: String, Codable {
        case brewFormula    // brew install <formula>
        case brewTap        // brew tap <user/repo> → brew install <formula>
        case rawURL         // curl로 직접 다운로드
        case local          // 로컬 디렉토리 직접 링크
    }
}


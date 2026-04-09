import Foundation
import DesignSystem

extension PluginManager {

    // MARK: - 의존성 검증

    /// 플러그인 의존성 충족 여부 확인
    public func validateDependencies(for pluginPath: String) -> [DependencyIssue] {
        let manifest: PluginManifest
        if let cached = manifestCacheGet(pluginPath) {
            manifest = cached
        } else {
            let baseURL = URL(fileURLWithPath: pluginPath)
            let manifestURL = baseURL.appendingPathComponent("plugin.json")
            guard let data = try? Data(contentsOf: manifestURL),
                  let decoded = try? JSONDecoder().decode(PluginManifest.self, from: data) else {
                return []
            }
            manifest = decoded
            manifestCacheSet(pluginPath, manifest)
        }
        guard let requires = manifest.requires, !requires.isEmpty else {
            return []
        }

        var issues: [DependencyIssue] = []
        for dep in requires {
            let installed = plugins.first { $0.name == dep.pluginId && $0.enabled }
            if installed == nil {
                issues.append(DependencyIssue(
                    pluginId: dep.pluginId,
                    kind: .missing,
                    requiredVersion: dep.minVersion,
                    installedVersion: nil
                ))
            } else if let minVer = dep.minVersion, let inst = installed {
                if Self.isNewerVersion(minVer, than: inst.version) {
                    issues.append(DependencyIssue(
                        pluginId: dep.pluginId,
                        kind: .versionTooLow,
                        requiredVersion: minVer,
                        installedVersion: inst.version
                    ))
                }
            }
        }
        return issues
    }

    public struct DependencyIssue {
        public let pluginId: String
        public let kind: Kind
        public let requiredVersion: String?
        public let installedVersion: String?

        public enum Kind {
            case missing
            case versionTooLow
        }

        public var localizedMessage: String {
            switch kind {
            case .missing:
                return String(format: NSLocalizedString("plugin.dep.missing", comment: ""), pluginId)
            case .versionTooLow:
                return String(format: NSLocalizedString("plugin.dep.version.low", comment: ""),
                              pluginId, requiredVersion ?? "?", installedVersion ?? "?")
            }
        }
    }

    // MARK: - 플러그인 상세 정보

    /// 플러그인이 기여하는 확장 포인트 요약
    public func contributionSummary(for plugin: PluginEntry) -> [ContributionBadge] {
        let baseURL = URL(fileURLWithPath: plugin.localPath)
        let manifest: PluginManifest
        if let cached = manifestCacheGet(plugin.localPath) {
            manifest = cached
        } else {
            let manifestURL = baseURL.appendingPathComponent("plugin.json")
            guard let data = try? Data(contentsOf: manifestURL),
                  let decoded = try? JSONDecoder().decode(PluginManifest.self, from: data) else {
                return []
            }
            manifest = decoded
            manifestCacheSet(plugin.localPath, manifest)
        }
        guard let c = manifest.contributes else {
            return []
        }

        var badges: [ContributionBadge] = []
        if let themes = c.themes, !themes.isEmpty {
            badges.append(ContributionBadge(icon: "paintpalette.fill", label: NSLocalizedString("plugin.badge.theme", comment: ""), count: themes.count))
        }
        if let effects = c.effects, !effects.isEmpty {
            badges.append(ContributionBadge(icon: "sparkles", label: NSLocalizedString("plugin.badge.effect", comment: ""), count: effects.count))
        }
        if let furniture = c.furniture, !furniture.isEmpty {
            badges.append(ContributionBadge(icon: "chair.lounge.fill", label: NSLocalizedString("plugin.badge.furniture", comment: ""), count: furniture.count))
        }
        if c.characters != nil {
            let charURL = baseURL.appendingPathComponent(c.characters!)
            if let charData = try? Data(contentsOf: charURL),
               let arr = try? JSONSerialization.jsonObject(with: charData) as? [[String: Any]] {
                badges.append(ContributionBadge(icon: "person.2.fill", label: NSLocalizedString("plugin.badge.character", comment: ""), count: arr.count))
            }
        }
        if let panels = c.panels, !panels.isEmpty {
            badges.append(ContributionBadge(icon: "rectangle.on.rectangle", label: NSLocalizedString("plugin.badge.panel", comment: ""), count: panels.count))
        }
        if let commands = c.commands, !commands.isEmpty {
            badges.append(ContributionBadge(icon: "terminal", label: NSLocalizedString("plugin.badge.command", comment: ""), count: commands.count))
        }
        if let achievements = c.achievements, !achievements.isEmpty {
            badges.append(ContributionBadge(icon: "trophy.fill", label: NSLocalizedString("plugin.badge.achievement", comment: ""), count: achievements.count))
        }
        if let presets = c.officePresets, !presets.isEmpty {
            badges.append(ContributionBadge(icon: "building.2.fill", label: NSLocalizedString("plugin.badge.office", comment: ""), count: presets.count))
        }
        if let lines = c.bossLines, !lines.isEmpty {
            badges.append(ContributionBadge(icon: "text.bubble.fill", label: NSLocalizedString("plugin.badge.bossline", comment: ""), count: lines.count))
        }
        return badges
    }

    public struct ContributionBadge {
        public let icon: String
        public let label: String
        public let count: Int
    }

    // MARK: - 충돌 감지

    /// 활성 플러그인 간 확장 포인트 ID 충돌 감지
    @discardableResult
    public func detectConflicts() -> [PluginConflict] {
        var conflicts: [PluginConflict] = []

        // pluginName → (extensionType, [IDs]) 맵
        var themeMap: [String: String] = [:]    // themeID → pluginName
        var effectMap: [String: String] = [:]
        var furnitureMap: [String: String] = [:]
        var achievementMap: [String: String] = [:]

        for pluginPath in activePluginPaths {
            let manifest: PluginManifest
            if let cached = manifestCacheGet(pluginPath) {
                manifest = cached
            } else {
                let baseURL = URL(fileURLWithPath: pluginPath)
                let manifestURL = baseURL.appendingPathComponent("plugin.json")
                guard let data = try? Data(contentsOf: manifestURL),
                      let decoded = try? JSONDecoder().decode(PluginManifest.self, from: data) else { continue }
                manifest = decoded
                manifestCacheSet(pluginPath, manifest)
            }

            guard let c = manifest.contributes else { continue }

            let name = manifest.name

            if let themes = c.themes {
                for t in themes {
                    if let existing = themeMap[t.id] {
                        conflicts.append(PluginConflict(pluginA: existing, pluginB: name, extensionType: NSLocalizedString("plugin.badge.theme", comment: ""), conflictingId: t.id))
                    } else { themeMap[t.id] = name }
                }
            }
            if let effects = c.effects {
                for e in effects {
                    if let existing = effectMap[e.id] {
                        conflicts.append(PluginConflict(pluginA: existing, pluginB: name, extensionType: NSLocalizedString("plugin.badge.effect", comment: ""), conflictingId: e.id))
                    } else { effectMap[e.id] = name }
                }
            }
            if let furniture = c.furniture {
                for f in furniture {
                    if let existing = furnitureMap[f.id] {
                        conflicts.append(PluginConflict(pluginA: existing, pluginB: name, extensionType: NSLocalizedString("plugin.badge.furniture", comment: ""), conflictingId: f.id))
                    } else { furnitureMap[f.id] = name }
                }
            }
            if let achievements = c.achievements {
                for a in achievements {
                    if let existing = achievementMap[a.id] {
                        conflicts.append(PluginConflict(pluginA: existing, pluginB: name, extensionType: NSLocalizedString("plugin.badge.achievement", comment: ""), conflictingId: a.id))
                    } else { achievementMap[a.id] = name }
                }
            }
        }
        cachedConflicts = conflicts
        return conflicts
    }

    /// 특정 플러그인에 해당하는 충돌만 반환 (캐시 사용)
    public func conflicts(for pluginName: String) -> [PluginConflict] {
        cachedConflicts.filter { $0.pluginA == pluginName || $0.pluginB == pluginName }
    }

    public struct PluginConflict {
        public let pluginA: String
        public let pluginB: String
        public let extensionType: String
        public let conflictingId: String

        public var localizedMessage: String {
            String(format: NSLocalizedString("plugin.conflict.desc", comment: ""),
                   pluginA, pluginB, extensionType, conflictingId)
        }
    }


}

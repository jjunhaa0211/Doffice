import Foundation

extension PluginManager {

    // MARK: - 마켓플레이스 검색/필터

    /// 검색어 + 태그 + 카테고리 필터가 적용된 레지스트리 목록 (정렬 포함)
    public var filteredRegistryPlugins: [RegistryPlugin] {
        var result = registryPlugins

        // 카테고리 필터
        if marketplaceCategory != .all {
            result = result.filter { marketplaceCategory.matches($0.tags) }
        }

        // 검색어 필터
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(query)
                || $0.description.lowercased().contains(query)
                || $0.author.lowercased().contains(query)
                || $0.tags.contains { $0.lowercased().contains(query) }
            }
        }

        // 태그 필터
        if !selectedTags.isEmpty {
            result = result.filter { item in
                !selectedTags.isDisjoint(with: Set(item.tags.map { $0.lowercased() }))
            }
        }

        // 정렬
        switch marketplaceSortOption {
        case .popular:
            result.sort { ($0.stars ?? 0) > ($1.stars ?? 0) }
        case .newest:
            result.sort { $0.version > $1.version }
        case .alphabetical:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        return result
    }

    /// Featured 플러그인 (별이 가장 많은 상위 3개)
    public var featuredPlugins: [RegistryPlugin] {
        Array(registryPlugins.sorted { ($0.stars ?? 0) > ($1.stars ?? 0) }.prefix(3))
    }

    /// 레지스트리에 있는 모든 태그 (카운트 포함)
    public var allRegistryTags: [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        for item in registryPlugins {
            for tag in item.tags {
                let lower = tag.lowercased()
                tagCounts[lower, default: 0] += 1
            }
        }
        return tagCounts.sorted { $0.value > $1.value }.map { (tag: $0.key, count: $0.value) }
    }

    // MARK: - 업데이트 감지

    /// 레지스트리와 설치된 플러그인 버전 비교
    public func checkForUpdates() {
        isCheckingUpdates = true
        var updates: [String: String] = [:]

        for plugin in plugins {
            guard plugin.enabled else { continue }
            if let registryItem = registryPlugins.first(where: {
                $0.id == plugin.name || $0.name == plugin.name || $0.downloadURL == plugin.source
            }) {
                if Self.isNewerVersion(registryItem.version, than: plugin.version) {
                    updates[plugin.id] = registryItem.version
                }
            }
        }

        updatablePlugins = updates
        isCheckingUpdates = false
    }

    /// 업데이트 가능한 플러그인인지 확인
    public func hasUpdate(_ plugin: PluginEntry) -> Bool {
        updatablePlugins[plugin.id] != nil
    }

    /// 업데이트 가능한 새 버전
    public func availableVersion(for plugin: PluginEntry) -> String? {
        updatablePlugins[plugin.id]
    }

    /// 업데이트 가능한 플러그인을 레지스트리에서 재설치
    public func updatePlugin(_ plugin: PluginEntry) {
        guard let registryItem = registryPlugins.first(where: {
            $0.id == plugin.name || $0.name == plugin.name || $0.downloadURL == plugin.source
        }) else { return }
        installFromRegistry(registryItem)
    }

    /// 모든 업데이트 가능한 플러그인 일괄 업데이트
    public func updateAllPlugins() {
        let updatable = plugins.filter { hasUpdate($0) }
        for plugin in updatable {
            updatePlugin(plugin)
        }
    }

    /// Semver 비교 (major.minor.patch)
    static func isNewerVersion(_ new: String, than old: String) -> Bool {
        let newParts = new.split(separator: ".").compactMap { Int($0) }
        let oldParts = old.split(separator: ".").compactMap { Int($0) }
        let maxLen = max(newParts.count, oldParts.count)
        for i in 0..<maxLen {
            let n = i < newParts.count ? newParts[i] : 0
            let o = i < oldParts.count ? oldParts[i] : 0
            if n > o { return true }
            if n < o { return false }
        }
        return false
    }


}

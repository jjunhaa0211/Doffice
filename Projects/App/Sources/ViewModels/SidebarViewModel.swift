import SwiftUI
import DesignSystem
import DofficeKit

// MARK: - SidebarViewModel

/// SidebarView의 필터링, 정렬, 배치 작업 로직을 담당합니다.
@MainActor
final class SidebarViewModel: ObservableObject {

    // MARK: - Search & Filter State

    @Published var searchQuery = ""
    @Published var isMultiSelectMode = false
    @Published var selectedTabIds: Set<String> = []
    @Published var showHistory = false

    // Sheet presentation
    @Published var showCharacterSheet = false
    @Published var showAchievementSheet = false
    @Published var showAccessorySheet = false
    @Published var showReportSheet = false

    @AppStorage("doffice.sidebarStatusFilter") var statusFilterRaw: String = SessionStatusFilter.all.rawValue
    @AppStorage("doffice.sidebarSortOption") var sortOptionRaw: String = SidebarSortOption.recent.rawValue

    var statusFilter: SessionStatusFilter {
        get { SessionStatusFilter(rawValue: statusFilterRaw) ?? .all }
        set { statusFilterRaw = newValue.rawValue }
    }

    var sortOption: SidebarSortOption {
        get { SidebarSortOption(rawValue: sortOptionRaw) ?? .recent }
        set { sortOptionRaw = newValue.rawValue }
    }

    var sortOptionBinding: Binding<SidebarSortOption> {
        Binding(
            get: { [weak self] in SidebarSortOption(rawValue: self?.sortOptionRaw ?? "recent") ?? .recent },
            set: { [weak self] in self?.sortOptionRaw = $0.rawValue }
        )
    }

    // MARK: - Filtering Logic

    func filteredProjectGroups(manager: SessionManager) -> [SessionManager.ProjectGroup] {
        let loweredQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let groups = manager.projectGroups.compactMap { group -> SessionManager.ProjectGroup? in
            let matchingTabs = group.tabs
                .filter { tab in
                    matchesQuery(tab, loweredQuery: loweredQuery) && matchesFilter(tab)
                }
                .sorted(by: tabSortComparator(lhs:rhs:))

            guard !matchingTabs.isEmpty else { return nil }
            return SessionManager.ProjectGroup(
                id: group.id,
                projectName: group.projectName,
                tabs: matchingTabs,
                hasActiveTab: matchingTabs.contains(where: { $0.id == manager.activeTabId })
            )
        }

        return groups.sorted { lhs, rhs in
            compareGroups(lhs, rhs)
        }
    }

    func matchesQuery(_ tab: TerminalTab, loweredQuery: String) -> Bool {
        guard !loweredQuery.isEmpty else { return true }
        return tab.sidebarSearchTokens.contains(loweredQuery)
    }

    func matchesFilter(_ tab: TerminalTab) -> Bool {
        switch statusFilter {
        case .all:
            return true
        case .active:
            return tab.statusPresentation.category == .active || tab.statusPresentation.category == .processing
        case .processing:
            return tab.statusPresentation.category == .processing
        case .completed:
            return tab.statusPresentation.category == .completed
        case .attention:
            return tab.statusPresentation.category == .attention
        }
    }

    func countForFilter(_ filter: SessionStatusFilter, manager: SessionManager) -> Int {
        manager.userVisibleTabs.filter { tab in
            switch filter {
            case .all:
                return true
            case .active:
                return tab.statusPresentation.category == .active || tab.statusPresentation.category == .processing
            case .processing:
                return tab.statusPresentation.category == .processing
            case .completed:
                return tab.statusPresentation.category == .completed
            case .attention:
                return tab.statusPresentation.category == .attention
            }
        }.count
    }

    // MARK: - Sorting Logic

    func tabSortComparator(lhs: TerminalTab, rhs: TerminalTab) -> Bool {
        switch sortOption {
        case .recent:
            if lhs.lastActivityTime != rhs.lastActivityTime { return lhs.lastActivityTime > rhs.lastActivityTime }
        case .name:
            let nameComparison = lhs.projectName.localizedCaseInsensitiveCompare(rhs.projectName)
            if nameComparison != .orderedSame { return nameComparison == .orderedAscending }
        case .tokens:
            if lhs.tokensUsed != rhs.tokensUsed { return lhs.tokensUsed > rhs.tokensUsed }
        case .status:
            if lhs.statusPresentation.sortPriority != rhs.statusPresentation.sortPriority {
                return lhs.statusPresentation.sortPriority < rhs.statusPresentation.sortPriority
            }
        }

        if lhs.projectName != rhs.projectName {
            return lhs.projectName.localizedCaseInsensitiveCompare(rhs.projectName) == .orderedAscending
        }
        return lhs.workerName.localizedCaseInsensitiveCompare(rhs.workerName) == .orderedAscending
    }

    func compareGroups(_ lhs: SessionManager.ProjectGroup, _ rhs: SessionManager.ProjectGroup) -> Bool {
        switch sortOption {
        case .recent:
            let lhsDate = lhs.tabs.map(\.lastActivityTime).max() ?? .distantPast
            let rhsDate = rhs.tabs.map(\.lastActivityTime).max() ?? .distantPast
            if lhsDate != rhsDate { return lhsDate > rhsDate }
        case .name:
            let comparison = lhs.projectName.localizedCaseInsensitiveCompare(rhs.projectName)
            if comparison != .orderedSame { return comparison == .orderedAscending }
        case .tokens:
            let lhsTokens = lhs.tabs.reduce(0) { $0 + $1.tokensUsed }
            let rhsTokens = rhs.tabs.reduce(0) { $0 + $1.tokensUsed }
            if lhsTokens != rhsTokens { return lhsTokens > rhsTokens }
        case .status:
            let lhsPriority = lhs.tabs.map(\.statusPresentation.sortPriority).min() ?? .max
            let rhsPriority = rhs.tabs.map(\.statusPresentation.sortPriority).min() ?? .max
            if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }
        }

        return lhs.projectName.localizedCaseInsensitiveCompare(rhs.projectName) == .orderedAscending
    }

    // MARK: - Multi-select Toggle

    func toggleSelection(_ tabId: String) {
        if selectedTabIds.contains(tabId) {
            selectedTabIds.remove(tabId)
        } else {
            selectedTabIds.insert(tabId)
        }
    }

    // MARK: - Batch Operations

    func batchRestart(manager: SessionManager) {
        for id in selectedTabIds {
            if let tab = manager.tabs.first(where: { $0.id == id }) {
                tab.stop()
                tab.start()
            }
        }
        finishBatchOperation()
    }

    func batchStop(manager: SessionManager) {
        for id in selectedTabIds {
            if let tab = manager.tabs.first(where: { $0.id == id }) {
                tab.forceStop()
            }
        }
        finishBatchOperation()
    }

    func batchClose(manager: SessionManager) {
        for id in selectedTabIds {
            manager.removeTab(id)
        }
        finishBatchOperation()
    }

    private func finishBatchOperation() {
        selectedTabIds.removeAll()
        isMultiSelectMode = false
    }
}

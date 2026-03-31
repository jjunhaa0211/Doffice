import SwiftUI
import DesignSystem

// MARK: - Grid Panel View
// ═══════════════════════════════════════════════════════

public struct GridPanelView: View {
    @EnvironmentObject var manager: SessionManager
    @StateObject private var settings = AppSettings.shared

    private var hasPinnedTabs: Bool { !manager.pinnedTabIds.isEmpty }

    private var pinnedTabs: [TerminalTab] {
        manager.userVisibleTabs.filter { manager.pinnedTabIds.contains($0.id) }
    }

    private var visibleGroups: [SessionManager.ProjectGroup] {
        if let selectedPath = manager.selectedGroupPath {
            let tabs = manager.visibleTabs
            guard let first = tabs.first else { return [] }
            return [SessionManager.ProjectGroup(id: selectedPath, projectName: first.projectName, tabs: tabs, hasActiveTab: tabs.contains(where: { $0.id == manager.activeTabId }))]
        }
        return manager.projectGroups
    }

    private var isFiltered: Bool { manager.selectedGroupPath != nil }

    public var body: some View {
        if manager.visibleTabs.isEmpty {
            EmptySessionView()
        } else if hasPinnedTabs {
            // ── Pinned multi-select grid (최우선) ──
            pinnedGridView
        } else if manager.focusSingleTab, let tab = manager.activeTab {
            EventStreamView(tab: tab, compact: false)
        } else {
            defaultGridView
        }
    }

    // Pinned tabs grid: show only selected tabs
    private var pinnedGridView: some View {
        let tabs = pinnedTabs
        let cols = tabs.count <= 1 ? 1 : tabs.count <= 4 ? 2 : 3
        return GeometryReader { geo in
            let totalH = geo.size.height
            let rows = max(1, Int(ceil(Double(tabs.count) / Double(cols))))
            let cellH = max(120, (totalH - CGFloat(rows + 1) * 6) / CGFloat(rows))
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: cols), spacing: 6) {
                    ForEach(tabs) { tab in
                        GridSinglePanel(tab: tab, isSelected: manager.activeTabId == tab.id)
                            .frame(height: cellH)
                            .onTapGesture { manager.focusSingleTab = true; manager.selectTab(tab.id) }
                    }
                }.padding(6)
            }.background(Theme.bg)
        }
    }

    // Default grid: show groups
    private var defaultGridView: some View {
        let groups = visibleGroups
        let tabCount = groups.reduce(0) { $0 + $1.tabs.count }
        let cols = tabCount <= 1 ? 1 : tabCount <= 4 ? 2 : 3
        return GeometryReader { geo in
            let totalH = geo.size.height
            let rows = max(1, Int(ceil(Double(tabCount) / Double(cols))))
            let cellH = max(120, (totalH - CGFloat(rows + 1) * 6) / CGFloat(rows))
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: cols), spacing: 6) {
                    ForEach(groups) { group in
                        if isFiltered && group.tabs.count > 1 {
                            ForEach(group.tabs) { tab in
                                GridSinglePanel(tab: tab, isSelected: manager.activeTabId == tab.id)
                                    .frame(height: cellH)
                                    .onTapGesture { manager.focusSingleTab = true; manager.selectTab(tab.id) }
                            }
                        } else {
                            GridGroupPanel(group: group)
                                .frame(height: cellH)
                        }
                    }
                }.padding(6)
            }.background(Theme.bg)
        }
    }
}

// 선택된 그룹 내 개별 탭 패널
public struct GridSinglePanel: View {
    @ObservedObject var tab: TerminalTab
    @StateObject private var settings = AppSettings.shared
    public let isSelected: Bool

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 1).fill(tab.workerColor).frame(width: 3, height: 12)
                Text(tab.workerName).font(Theme.chrome(9, weight: .bold)).foregroundColor(tab.workerColor)
                Text(tab.projectName).font(Theme.chrome(9)).foregroundColor(Theme.textSecondary).lineLimit(1)
                Spacer()
                if tab.isProcessing { ProgressView().scaleEffect(0.35).frame(width: 8, height: 8) }
                Text(tab.selectedModel.icon).font(Theme.chrome(9))
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(isSelected ? Theme.bgSelected : Theme.bgCard)

            EventStreamView(tab: tab, compact: true)
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgCard))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Theme.accent.opacity(0.5) : Theme.border, lineWidth: 1))
    }
}

public struct GridGroupPanel: View {
    public let group: SessionManager.ProjectGroup
    @EnvironmentObject var manager: SessionManager
    @StateObject private var settings = AppSettings.shared
    @State private var selectedWorkerIndex = 0

    private var activeTab: TerminalTab? {
        guard !group.tabs.isEmpty else { return nil }
        let idx = min(max(0, selectedWorkerIndex), group.tabs.count - 1)
        return group.tabs[idx]
    }

    public var body: some View {
        Group {
            if let activeTab = activeTab {
                VStack(spacing: 0) {
                    // Header: project name + worker tabs
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1).fill(activeTab.workerColor).frame(width: 3, height: 12)
                        Text(group.projectName).font(Theme.chrome(10, weight: .semibold)).foregroundColor(Theme.textPrimary).lineLimit(1)
                        Spacer()

                        if group.tabs.count > 1 {
                            HStack(spacing: 2) {
                                ForEach(Array(group.tabs.enumerated()), id: \.element.id) { i, tab in
                                    Button(action: { selectedWorkerIndex = i; manager.selectTab(tab.id) }) {
                                        Text(tab.workerName).font(Theme.chrome(7, weight: selectedWorkerIndex == i ? .bold : .regular))
                                            .foregroundColor(selectedWorkerIndex == i ? tab.workerColor : Theme.textDim)
                                            .padding(.horizontal, 4).padding(.vertical, 2)
                                            .background(selectedWorkerIndex == i ? tab.workerColor.opacity(0.1) : .clear)
                                            .cornerRadius(3)
                                    }.buttonStyle(.plain)
                                }
                            }
                        }

                        if activeTab.isProcessing { ProgressView().scaleEffect(0.35).frame(width: 8, height: 8) }
                        Text(activeTab.selectedModel.icon).font(Theme.chrome(9))
                    }

                    .padding(.horizontal, 6).padding(.vertical, 4)
                    .background(group.hasActiveTab ? Theme.bgSelected : Theme.bgCard)

                    EventStreamView(tab: activeTab, compact: true)
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgCard))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(group.hasActiveTab ? Theme.accent.opacity(0.5) : Theme.border, lineWidth: 1))
                .onTapGesture { manager.selectTab(activeTab.id) }
            } else {
                EmptyView()
            }
        }
    }
}

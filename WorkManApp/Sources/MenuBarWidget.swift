import SwiftUI
import AppKit

// MARK: - Feature 6: 메뉴바 미니 위젯

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "W"
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 440)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView()
                .environmentObject(SessionManager.shared)
        )
        self.popover = popover

        // 주기적으로 메뉴바 타이틀 업데이트
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateTitle()
        }
    }

    private func updateTitle() {
        let mgr = SessionManager.shared
        let active = mgr.tabs.filter { $0.isRunning && !$0.isCompleted }.count
        let doing = mgr.tabs.first(where: { $0.claudeActivity != .idle && $0.claudeActivity != .done })

        if let doing = doing {
            let emoji: String
            switch doing.claudeActivity {
            case .thinking: emoji = "💭"
            case .writing: emoji = "✏️"
            case .reading: emoji = "📖"
            case .searching: emoji = "🔍"
            case .running: emoji = "⚡"
            case .error: emoji = "❌"
            default: emoji = "🔧"
            }
            statusItem?.button?.title = "\(emoji) \(active)"
        } else if active > 0 {
            statusItem?.button?.title = "W \(active)"
        } else {
            statusItem?.button?.title = "W"
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

// MARK: - Popover Content

struct MenuBarPopoverView: View {
    @EnvironmentObject var manager: SessionManager
    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var activeTabs: [TerminalTab] { manager.tabs.filter { $0.isRunning && !$0.isCompleted } }
    private var completedTabs: [TerminalTab] { manager.tabs.filter { $0.isCompleted } }
    private var idleTabs: [TerminalTab] { manager.tabs.filter { !$0.isRunning && !$0.isCompleted } }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Rectangle().fill(Theme.border).frame(height: 1)

            // Summary stats
            summaryBar

            Rectangle().fill(Theme.border).frame(height: 1)

            // Session list
            ScrollView {
                VStack(spacing: 8) {
                    if !activeTabs.isEmpty {
                        sectionHeader("작업 중", icon: "play.circle.fill", color: Theme.green, count: activeTabs.count)
                        ForEach(activeTabs) { tab in MenuBarSessionRow(tab: tab, now: now) }
                    }

                    if !completedTabs.isEmpty {
                        sectionHeader("완료", icon: "checkmark.circle.fill", color: Theme.accent, count: completedTabs.count)
                        ForEach(completedTabs) { tab in MenuBarSessionRow(tab: tab, now: now) }
                    }

                    if !idleTabs.isEmpty {
                        sectionHeader("대기", icon: "pause.circle.fill", color: Theme.textDim, count: idleTabs.count)
                        ForEach(idleTabs) { tab in MenuBarSessionRow(tab: tab, now: now) }
                    }

                    if manager.tabs.isEmpty {
                        VStack(spacing: 8) {
                            Text("W").font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(Theme.accent)
                            Text("활성 세션 없음").font(Theme.mono(10)).foregroundColor(Theme.textDim)
                            Text(AppSettings.shared.appDisplayName).font(Theme.mono(8)).foregroundColor(Theme.textDim.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 30)
                    }
                }
                .padding(10)
            }

            Rectangle().fill(Theme.border).frame(height: 1)

            // Footer
            footerSection
        }
        .background(Theme.bg)
        .onReceive(timer) { now = $0 }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 8) {
            Text("W").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(Theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(AppSettings.shared.appDisplayName).font(Theme.mono(12, weight: .bold)).foregroundColor(Theme.accent)
                Text(AppSettings.shared.companyName.isEmpty ? "Claude Code Manager" : AppSettings.shared.companyName)
                    .font(Theme.mono(7)).foregroundColor(Theme.textDim)
            }
            Spacer()

            // Level badge
            let level = AchievementManager.shared.currentLevel
            Text("Lv.\(level.level)")
                .font(Theme.mono(8, weight: .bold)).foregroundColor(Theme.yellow)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(Theme.yellow.opacity(0.1)).cornerRadius(3)

            Text("\(manager.tabs.count)")
                .font(Theme.mono(10, weight: .bold)).foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Theme.bgSurface).cornerRadius(4)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Theme.bgCard)
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        let tracker = TokenTracker.shared
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                statItem(
                    icon: "play.fill",
                    label: "Active",
                    value: "\(activeTabs.count)",
                    color: activeTabs.isEmpty ? Theme.textDim : Theme.green
                )
                Rectangle().fill(Theme.border).frame(width: 1, height: 22)
                statItem(
                    icon: "checkmark",
                    label: "Done",
                    value: "\(completedTabs.count)",
                    color: completedTabs.isEmpty ? Theme.textDim : Theme.accent
                )
                Rectangle().fill(Theme.border).frame(width: 1, height: 22)
                statItem(
                    icon: "bolt.fill",
                    label: "오늘",
                    value: fmtTokens(tracker.todayTokens),
                    color: tracker.todayTokens > 0 ? Theme.yellow : Theme.textDim
                )
                Rectangle().fill(Theme.border).frame(width: 1, height: 22)
                statItem(
                    icon: "dollarsign",
                    label: "Cost",
                    value: String(format: "$%.3f", tracker.todayCost),
                    color: tracker.todayCost > 0 ? Theme.orange : Theme.textDim
                )
            }

            // Daily usage bar
            if tracker.todayTokens > 0 {
                VStack(spacing: 2) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 1.5).fill(Theme.bg).frame(height: 3)
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(tracker.dailyUsagePercent > 0.8 ? Theme.red : Theme.green)
                                .frame(width: max(0, geo.size.width * min(1, tracker.dailyUsagePercent)), height: 3)
                        }
                    }.frame(height: 3).padding(.horizontal, 12)
                    HStack {
                        Text("남은 양: \(fmtTokens(tracker.dailyRemaining))")
                            .font(Theme.mono(7)).foregroundColor(Theme.textDim)
                        Spacer()
                        Text("주간: \(fmtTokens(tracker.weekTokens))/\(fmtTokens(tracker.weeklyTokenLimit))")
                            .font(Theme.mono(7)).foregroundColor(Theme.textDim)
                    }.padding(.horizontal, 12)
                }.padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
        .background(Theme.bgSurface.opacity(0.5))
    }

    private func statItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 7, weight: .bold)).foregroundColor(color)
                Text(value).font(Theme.mono(9, weight: .bold)).foregroundColor(color)
            }
            Text(label).font(Theme.mono(6)).foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String, color: Color, count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8)).foregroundColor(color)
            Text(title).font(Theme.mono(8, weight: .bold)).foregroundColor(color)
            Spacer()
            Text("\(count)").font(Theme.mono(7, weight: .bold)).foregroundColor(color.opacity(0.7))
                .padding(.horizontal, 4).padding(.vertical, 1)
                .background(color.opacity(0.1)).cornerRadius(3)
        }
        .padding(.horizontal, 4).padding(.top, 4)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 8) {
            Button(action: {
                NSApp.activate(ignoringOtherApps: true)
                if NSApp.windows.filter({ $0.isVisible }).isEmpty {
                    for w in NSApp.windows { w.makeKeyAndOrderFront(nil) }
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "macwindow").font(.system(size: 9))
                    Text("\(AppSettings.shared.appDisplayName) 열기").font(Theme.mono(9, weight: .medium))
                }
                .foregroundColor(Theme.accent)
                .frame(maxWidth: .infinity).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 5).fill(Theme.accent.opacity(0.08)))
            }.buttonStyle(.plain)

            Button(action: { SessionManager.shared.refresh() }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 9))
                    Text("새로고침").font(Theme.mono(9, weight: .medium))
                }
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 5).fill(Theme.bgSurface))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.bgCard)
    }

    private func fmtTokens(_ c: Int) -> String {
        if c >= 1_000_000 { return String(format: "%.1fM", Double(c) / 1_000_000) }
        if c >= 1000 { return String(format: "%.1fk", Double(c) / 1000) }
        return "\(c)"
    }
}

// MARK: - Session Row

struct MenuBarSessionRow: View {
    @ObservedObject var tab: TerminalTab
    var now: Date

    private var statusColor: Color {
        if tab.isCompleted { return Theme.green }
        switch tab.claudeActivity {
        case .thinking: return Theme.purple
        case .writing: return Theme.green
        case .reading: return Theme.accent
        case .searching: return Theme.cyan
        case .running: return Theme.yellow
        case .error: return Theme.red
        case .done: return Theme.green
        case .idle: return Theme.textDim
        }
    }

    private var activityLabel: String {
        if tab.isCompleted { return "완료" }
        switch tab.claudeActivity {
        case .idle: return "대기"
        case .thinking: return "생각 중"
        case .reading: return "읽는 중"
        case .writing: return "작성 중"
        case .searching: return "검색 중"
        case .running: return "실행 중"
        case .done: return "완료"
        case .error: return "에러"
        }
    }

    private var elapsed: String {
        let secs = Int(now.timeIntervalSince(tab.startTime))
        if secs < 60 { return "\(secs)s" }
        if secs < 3600 { return "\(secs / 60)m \(secs % 60)s" }
        return "\(secs / 3600)h \((secs % 3600) / 60)m"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 8) {
                // Status indicator
                ZStack {
                    Circle().fill(statusColor.opacity(0.15)).frame(width: 22, height: 22)
                    Circle().fill(statusColor).frame(width: 6, height: 6)
                    if tab.isProcessing {
                        Circle().stroke(statusColor.opacity(0.4), lineWidth: 1).frame(width: 18, height: 18)
                    }
                }

                // Project info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(tab.projectName)
                            .font(Theme.mono(10, weight: .semibold))
                            .foregroundColor(Theme.textPrimary).lineLimit(1)
                        if tab.selectedModel != .sonnet {
                            Text(tab.selectedModel.rawValue.prefix(1).uppercased())
                                .font(Theme.mono(6, weight: .bold)).foregroundColor(Theme.purple)
                                .padding(.horizontal, 3).padding(.vertical, 1)
                                .background(Theme.purple.opacity(0.1)).cornerRadius(2)
                        }
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1).fill(tab.workerColor).frame(width: 2, height: 8)
                        Text(tab.workerName).font(Theme.mono(8)).foregroundColor(tab.workerColor)
                        Text("·").foregroundColor(Theme.textDim).font(Theme.mono(7))
                        Text(activityLabel).font(Theme.mono(7, weight: .medium)).foregroundColor(statusColor)
                    }
                }

                Spacer()

                // Right side info
                VStack(alignment: .trailing, spacing: 2) {
                    Text(elapsed).font(Theme.mono(8)).foregroundColor(Theme.textDim)
                    if tab.tokensUsed > 0 {
                        Text(fmtTokens(tab.tokensUsed)).font(Theme.mono(7)).foregroundColor(Theme.textDim)
                    }
                }
            }

            // Detail bar (compact stats)
            HStack(spacing: 6) {
                if tab.gitInfo.isGitRepo && !tab.gitInfo.branch.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.triangle.branch").font(.system(size: 7)).foregroundColor(Theme.cyan.opacity(0.7))
                        Text(tab.gitInfo.branch).font(Theme.mono(7)).foregroundColor(Theme.cyan.opacity(0.7)).lineLimit(1)
                    }
                }

                Spacer()

                if !tab.fileChanges.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.fill").font(.system(size: 6)).foregroundColor(Theme.green.opacity(0.7))
                        Text("\(Set(tab.fileChanges.map(\.fileName)).count)").font(Theme.mono(7)).foregroundColor(Theme.green.opacity(0.7))
                    }
                }

                if tab.commandCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "terminal").font(.system(size: 6)).foregroundColor(Theme.textDim)
                        Text("\(tab.commandCount)").font(Theme.mono(7)).foregroundColor(Theme.textDim)
                    }
                }

                if tab.errorCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 6)).foregroundColor(Theme.red.opacity(0.7))
                        Text("\(tab.errorCount)").font(Theme.mono(7)).foregroundColor(Theme.red.opacity(0.7))
                    }
                }

                if tab.totalCost > 0 {
                    Text(String(format: "$%.3f", tab.totalCost))
                        .font(Theme.mono(7)).foregroundColor(Theme.yellow.opacity(0.7))
                }
            }
            .padding(.top, 3)

            // Token progress bar
            if tab.tokensUsed > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1).fill(Theme.bg).frame(height: 2)
                        RoundedRectangle(cornerRadius: 1).fill(statusColor.opacity(0.5))
                            .frame(width: max(2, geo.size.width * CGFloat(tab.tokensUsed) / CGFloat(max(1, tab.tokenLimit))), height: 2)
                    }
                }.frame(height: 2).padding(.top, 4)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(tab.isProcessing ? statusColor.opacity(0.04) : Theme.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(tab.isProcessing ? statusColor.opacity(0.15) : Theme.border.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    private func fmtTokens(_ c: Int) -> String {
        if c >= 1000 { return String(format: "%.1fk", Double(c) / 1000) }
        return "\(c)"
    }
}

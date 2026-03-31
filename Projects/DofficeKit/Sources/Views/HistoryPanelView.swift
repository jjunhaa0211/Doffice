import SwiftUI
import DesignSystem

// MARK: - History Panel View (프롬프트 히스토리)
// ═══════════════════════════════════════════════════════

public struct HistoryPanelView: View {
    @EnvironmentObject var manager: SessionManager

    private var activeTab: TerminalTab? { manager.activeTab }

    public init() {}

    public var body: some View {
        if let tab = activeTab {
            HistoryListView(tab: tab)
        } else {
            EmptySessionView()
        }
    }
}

struct HistoryListView: View {
    @ObservedObject var tab: TerminalTab
    @State private var expandedEntryId: UUID?
    @State private var loadedDiffs: [UUID: String] = [:]
    @State private var revertTargetId: UUID?
    @State private var showRevertAlert = false
    @State private var historyCount: Int = 0
    private let refreshTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: Theme.iconSize(12), weight: .bold))
                    .foregroundColor(Theme.accent)
                Text(NSLocalizedString("terminal.mode.history", comment: ""))
                    .font(Theme.mono(12, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text("\(tab.promptHistory.count)")
                    .font(Theme.mono(10, weight: .bold))
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Theme.accent.opacity(0.12))
                    .cornerRadius(3)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Theme.bgCard)
            .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .bottom)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if tab.promptHistory.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.textDim.opacity(0.4))
                            Text(NSLocalizedString("history.empty", comment: ""))
                                .font(Theme.mono(11))
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        let reversed = Array(tab.promptHistory.reversed())
                        ForEach(Array(reversed.enumerated()), id: \.element.id) { displayIndex, entry in
                            historyEntryRow(entry: entry, isLast: displayIndex == reversed.count - 1)
                        }
                    }
                }
                .padding(12)
            }
            .background(Theme.bg)
        }
        .alert(NSLocalizedString("history.revert.confirm.title", comment: ""), isPresented: $showRevertAlert) {
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("history.revert.action", comment: ""), role: .destructive) {
                if let targetId = revertTargetId,
                   let entry = tab.promptHistory.first(where: { $0.id == targetId }) {
                    tab.revertToBeforePrompt(entry)
                }
            }
        } message: {
            Text(NSLocalizedString("history.revert.confirm.message", comment: ""))
        }
        .onReceive(refreshTimer) { _ in
            // promptHistory는 @Published가 아니므로 수동으로 갱신 감지
            if tab.promptHistory.count != historyCount {
                historyCount = tab.promptHistory.count
            }
        }
        .onAppear { historyCount = tab.promptHistory.count }
    }

    private func historyEntryRow(entry: PromptHistoryEntry, isLast: Bool) -> some View {
        let isExpanded = expandedEntryId == entry.id
        let fileCount = entry.fileChanges.filter { $0.action == "Write" || $0.action == "Edit" }.count

        return VStack(alignment: .leading, spacing: 0) {
            // 메인 행
            HStack(spacing: 8) {
                // 타임라인 인디케이터
                VStack(spacing: 0) {
                    Circle()
                        .fill(entry.isCompleted ? Theme.green : Theme.yellow)
                        .frame(width: 8, height: 8)
                    if !isLast {
                        Rectangle()
                            .fill(Theme.border)
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 12)

                VStack(alignment: .leading, spacing: 4) {
                    // 시간 + 파일 수
                    HStack(spacing: 6) {
                        Text(relativeTime(entry.timestamp))
                            .font(Theme.chrome(8))
                            .foregroundColor(Theme.textDim)
                        if fileCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 7))
                                Text(String(format: NSLocalizedString("history.files.changed", comment: ""), fileCount))
                                    .font(Theme.chrome(8, weight: .medium))
                            }
                            .foregroundColor(Theme.cyan)
                        }
                        if let hash = entry.gitCommitHashBefore {
                            Text(String(hash.prefix(7)))
                                .font(Theme.mono(8))
                                .foregroundColor(Theme.textDim)
                        }
                        Spacer()
                    }

                    // 프롬프트 텍스트
                    Text(entry.promptText)
                        .font(Theme.mono(10))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(isExpanded ? nil : 2)
                }

                Spacer()

                // 액션 버튼
                HStack(spacing: 4) {
                    if fileCount > 0 {
                        Button(action: { toggleExpand(entry) }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Theme.textDim)
                                .frame(width: 24, height: 24)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.bgSurface))
                        }
                        .buttonStyle(.plain)
                        .help(isExpanded ? NSLocalizedString("history.collapse", comment: "") : NSLocalizedString("history.expand", comment: ""))
                    }

                    if entry.gitCommitHashBefore != nil && fileCount > 0 {
                        Button(action: {
                            revertTargetId = entry.id
                            showRevertAlert = true
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Theme.orange)
                                .frame(width: 24, height: 24)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.orange.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                        .help(NSLocalizedString("history.revert.confirm.title", comment: ""))
                    }
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)

            // 확장된 diff 뷰
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.fileChanges.filter { $0.action == "Write" || $0.action == "Edit" }, id: \.id) { file in
                        HStack(spacing: 4) {
                            Image(systemName: file.action == "Write" ? "plus.circle.fill" : "pencil.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(file.action == "Write" ? Theme.green : Theme.yellow)
                            Text(file.fileName)
                                .font(Theme.mono(9))
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                            Text(file.action)
                                .font(Theme.chrome(7, weight: .medium))
                                .foregroundColor(Theme.textDim)
                        }
                    }

                    if let diff = loadedDiffs[entry.id] {
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(diff)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 300)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgTerminal))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                    } else {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.5)
                            Text(NSLocalizedString("history.expand", comment: ""))
                                .font(Theme.chrome(9))
                                .foregroundColor(Theme.textDim)
                        }
                    }
                }
                .padding(.horizontal, 30).padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgCard))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
    }

    private func toggleExpand(_ entry: PromptHistoryEntry) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedEntryId == entry.id {
                expandedEntryId = nil
            } else {
                expandedEntryId = entry.id
                if loadedDiffs[entry.id] == nil {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let diff = tab.loadDiffForHistoryEntry(entry)
                        DispatchQueue.main.async {
                            loadedDiffs[entry.id] = diff
                        }
                    }
                }
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let interval = Int(Date().timeIntervalSince(date))
        if interval < 60 { return NSLocalizedString("history.just.now", comment: "") }
        if interval < 3600 { return "\(interval / 60)m ago" }
        if interval < 86400 { return "\(interval / 3600)h ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

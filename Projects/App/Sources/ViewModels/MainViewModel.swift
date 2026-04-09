import SwiftUI
import Combine
import AppKit
import DesignSystem
import DofficeKit

// MARK: - MainViewModel

/// MainView의 비즈니스 로직과 프레젠테이션 상태를 담당합니다.
/// View는 UI 렌더링만 담당하고, 상태 변경/비즈니스 로직은 이 ViewModel을 통해 처리합니다.
@MainActor
final class MainViewModel: ObservableObject {

    // MARK: - Sheet / Alert Presentation State

    @Published var showSettings = false
    @Published var showBugReport = false
    @Published var showUpdateSheet = false
    @Published var showActionCenter = false
    @Published var showCommandPalette = false

    @Published var showClaudeNotInstalledAlert = false
    @Published var showRoleNoticeAlert = false
    @Published var roleNoticeTitle = ""
    @Published var roleNoticeMessage = ""

    @Published var showDailyReward = false
    @Published var dailyRewardData: AchievementManager.DailyRewardResult?

    @Published var showBillingAlert = false
    @Published var billingAlertMessage = ""

    @Published var activePluginPanelId: String?

    // MARK: - Persisted View State (AppStorage)

    @AppStorage("officeExpanded") var officeExpanded = true
    @AppStorage("splitViewTopHeight") var splitViewTopHeight: Double = Double(AppConstants.Layout.officeExpandedHeight)
    @AppStorage("viewMode") var viewModeRaw: Int = 1
    @AppStorage("sidebarCollapsed") var sidebarCollapsed = false

    // MARK: - Computed Properties

    enum ViewMode: Int { case split = 0, office = 1, terminal = 2, strip = 3 }
    var viewMode: ViewMode { ViewMode(rawValue: viewModeRaw) ?? .split }

    // MARK: - Dependencies (read-only references)

    let settings = AppSettings.shared
    let achievementManager = AchievementManager.shared
    let updater = UpdateChecker.shared
    let pluginHost = PluginHost.shared
    let effectEngine = PluginEffectEngine.shared
    let sessionNotifications = SessionNotificationManager.shared

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// 앱 시작 시 호출 — 세션 복원, CLI 체크, 플러그인 로드, 업데이트 체크 등을 순차 실행
    func initialize(manager: SessionManager) {
        seedPersistedLayoutStateIfNeeded()
        settings.ensureCoffeeSupportPreset()

        if manager.userVisibleTabs.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Timing.sessionRestoreDelay) {
                manager.restoreSessions()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Timing.autoDetectDelay) {
                manager.autoDetectAndConnect()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Timing.installCheckDelay) { [weak self] in
            ClaudeInstallChecker.shared.check()
            CodexInstallChecker.shared.check()
            GeminiInstallChecker.shared.check()
            let noneInstalled = !ClaudeInstallChecker.shared.isInstalled
                && !CodexInstallChecker.shared.isInstalled
                && !GeminiInstallChecker.shared.isInstalled
            if noneInstalled {
                self?.showClaudeNotInstalledAlert = true
            }
        }

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + AppConstants.Timing.pluginReloadDelay) {
            PluginHost.shared.reload()
        }

        if let reward = achievementManager.claimDailyReward() {
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Timing.dailyRewardDelay) { [weak self] in
                self?.dailyRewardData = reward
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    self?.showDailyReward = true
                }
            }
        }

        // 업데이트 준비 완료 시 자동으로 시트 표시
        updater.onReadyToInstall = { [weak self] in
            guard let self else { return }
            // 다른 시트가 열려있지 않을 때만 자동 표시
            let anySheetOpen = self.showSettings || self.showBugReport || self.showUpdateSheet
                || self.showActionCenter || self.showCommandPalette
            if !anySheetOpen {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.showUpdateSheet = true
                }
            }
        }

        // 앱 종료 시 readyToInstall이면 자동 설치
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updater.installOnQuitIfReady()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Timing.updateCheckDelay) { [weak self] in
            self?.updater.checkForUpdates()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Timing.billingCheckDelay) { [weak self] in
            self?.checkBillingDay()
        }
    }

    // MARK: - Sheet Mutual Exclusion

    /// 시트를 열 때 다른 시트와 충돌하지 않도록 관리합니다.
    func ensureNoSheetConflict(with newTabSheet: Bool) {
        guard newTabSheet else { return }
        showSettings = false
        showBugReport = false
        showUpdateSheet = false
        showActionCenter = false
    }

    // MARK: - Business Logic

    func checkBillingDay() {
        let day = settings.billingDay
        guard day > 0 else { return }

        let cal = Calendar.current
        let now = Date()
        let todayDay = cal.component(.day, from: now)
        let monthKey = "\(cal.component(.year, from: now))-\(cal.component(.month, from: now))"

        guard settings.billingLastNotifiedMonth != monthKey else { return }
        guard todayDay >= day else { return }

        settings.billingLastNotifiedMonth = monthKey

        let tracker = TokenTracker.shared
        let costStr = String(format: "$%.2f", tracker.todayCost)
        let tokens = tracker.todayTokens

        billingAlertMessage = String(
            format: NSLocalizedString("main.billing.alert", comment: ""),
            tokens > 1000 ? String(format: "%.1fK", Double(tokens) / 1000) : "\(tokens)",
            costStr
        )

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showBillingAlert = true
        }
    }

    func copyActiveConversation(manager: SessionManager) {
        guard let tab = manager.activeTab else { return }
        tab.copyConversation()
    }

    func exportActiveLog(manager: SessionManager) {
        guard let tab = manager.activeTab, let url = tab.exportLog() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = url.lastPathComponent
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let dest = panel.url {
            do {
                try FileManager.default.copyItem(at: url, to: dest)
            } catch {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("main.log.export.fail", comment: "")
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }

    // MARK: - Layout Helpers

    func seedPersistedLayoutStateIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "splitViewTopHeight") == nil {
            splitViewTopHeight = Double(
                officeExpanded ? AppConstants.Layout.officeExpandedHeight : AppConstants.Layout.officeCollapsedHeight
            )
        }
    }

    func protectedSidebarWidth(totalWidth: CGFloat, sidebarWidth: CGFloat) -> CGFloat {
        let requestedWidth = max(sidebarWidth, AppConstants.Layout.minimumSidebarWidth)
        let safeMaximum = max(
            AppConstants.Layout.minimumSidebarWidth,
            min(
                AppConstants.Layout.maximumSidebarWidth,
                totalWidth - AppConstants.Layout.minimumPrimaryContentWidth
            )
        )
        return min(requestedWidth, safeMaximum)
    }

    func shouldForceCompactSidebar(totalWidth: CGFloat, sidebarWidth: CGFloat) -> Bool {
        totalWidth < AppConstants.Layout.compactBreakpointWidth || sidebarWidth <= AppConstants.Layout.compactSidebarThreshold
    }

    func protectedSplitTopHeight(totalHeight: CGFloat, proposedHeight: CGFloat) -> CGFloat {
        let safeMaximum = max(
            AppConstants.Layout.minimumSplitTopHeight,
            totalHeight - AppConstants.Layout.minimumTerminalHeight
        )
        let requestedHeight = max(proposedHeight, AppConstants.Layout.minimumSplitTopHeight)
        return min(requestedHeight, safeMaximum)
    }

    func currentSplitTopHeight(totalHeight: CGFloat) -> CGFloat {
        protectedSplitTopHeight(totalHeight: totalHeight, proposedHeight: CGFloat(splitViewTopHeight))
    }

    func updateSplitTopHeight(_ proposedHeight: CGFloat, totalHeight: CGFloat) {
        let clampedHeight = protectedSplitTopHeight(totalHeight: totalHeight, proposedHeight: proposedHeight)
        splitViewTopHeight = Double(clampedHeight)
        officeExpanded = clampedHeight > (AppConstants.Layout.officeCollapsedHeight + AppConstants.Layout.officeExpandedHeight) / 2
    }

    func toggleSplitTopHeight(totalHeight: CGFloat) {
        let midpoint = (AppConstants.Layout.officeCollapsedHeight + AppConstants.Layout.officeExpandedHeight) / 2
        let currentHeight = currentSplitTopHeight(totalHeight: totalHeight)
        let targetHeight = currentHeight <= midpoint
            ? AppConstants.Layout.officeExpandedHeight
            : AppConstants.Layout.officeCollapsedHeight
        updateSplitTopHeight(targetHeight, totalHeight: totalHeight)
    }
}

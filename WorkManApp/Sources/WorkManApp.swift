import SwiftUI
import UserNotifications

@main
struct WorkManApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager = SessionManager.shared
    @ObservedObject private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(manager)
                .environmentObject(settings)
                .frame(minWidth: 1000, minHeight: 650)
                .preferredColorScheme(settings.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Refresh Sessions") {
                    NotificationCenter.default.post(name: .workmanRefresh, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("New Session") {
                    NotificationCenter.default.post(name: .workmanNewTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Close Session") {
                    NotificationCenter.default.post(name: .workmanCloseTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)

                Divider()

                Button("Toggle Split View") {
                    NotificationCenter.default.post(name: .workmanToggleSplit, object: nil)
                }
                .keyboardShortcut("\\", modifiers: .command)

                Button("Export Session Log") {
                    NotificationCenter.default.post(name: .workmanExportLog, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()

                ForEach(1...9, id: \.self) { index in
                    Button("Session \(index)") {
                        NotificationCenter.default.post(name: .workmanSelectTab, object: index)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: .command)
                }
            }
        }
    }
}

extension Notification.Name {
    static let workmanRefresh = Notification.Name("workmanRefresh")
    static let workmanNewTab = Notification.Name("workmanNewTab")
    static let workmanCloseTab = Notification.Name("workmanCloseTab")
    static let workmanSelectTab = Notification.Name("workmanSelectTab")
    static let workmanToggleSplit = Notification.Name("workmanToggleSplit")
    static let workmanExportLog = Notification.Name("workmanExportLog")
    static let workmanClaudeNotInstalled = Notification.Name("workmanClaudeNotInstalled")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager = MenuBarManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        menuBarManager.setup()

        // Claude 설치 확인
        ClaudeInstallChecker.shared.check()
        if ClaudeInstallChecker.shared.isInstalled {
            print("[WorkMan] Claude Code \(ClaudeInstallChecker.shared.version) found at \(ClaudeInstallChecker.shared.path)")
        } else {
            print("[WorkMan] ⚠️ Claude Code not installed")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        SessionManager.shared.saveSessions()
    }

    // Feature 3: 메뉴바에서 창 다시 열기
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // 창이 없으면 새로 열기
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

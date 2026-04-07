import SwiftUI
import DesignSystem

struct NotificationsCatalog: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            catalogTitle("Notification Events")

            catalogSection("Tab Management") {
                VStack(alignment: .leading, spacing: 6) {
                    notificationRow("dofficeNewTab", desc: "Create a new session tab", shortcut: "Cmd+T")
                    notificationRow("dofficeCloseTab", desc: "Close current tab", shortcut: "Cmd+W")
                    notificationRow("dofficeSelectTab", desc: "Switch to a specific tab by ID")
                    notificationRow("dofficeNextTab", desc: "Move to next tab", shortcut: "Ctrl+Tab")
                    notificationRow("dofficePreviousTab", desc: "Move to previous tab", shortcut: "Ctrl+Shift+Tab")
                    notificationRow("dofficeTabCycleCompleted", desc: "All tabs have finished processing")
                }
            }

            catalogSection("View Toggles") {
                VStack(alignment: .leading, spacing: 6) {
                    notificationRow("dofficeToggleSplit", desc: "Toggle split pane view")
                    notificationRow("dofficeToggleOffice", desc: "Toggle pixel office overlay")
                    notificationRow("dofficeToggleTerminal", desc: "Toggle terminal visibility")
                    notificationRow("dofficeToggleBrowser", desc: "Toggle built-in browser")
                    notificationRow("dofficeOpenBrowser", desc: "Open URL in built-in browser")
                }
            }

            catalogSection("Session Actions") {
                VStack(alignment: .leading, spacing: 6) {
                    notificationRow("dofficeRefresh", desc: "Refresh current session state")
                    notificationRow("dofficeRestartSession", desc: "Restart the current session")
                    notificationRow("dofficeCancelProcessing", desc: "Cancel active AI processing", shortcut: "Esc")
                    notificationRow("dofficeClearTerminal", desc: "Clear terminal output")
                    notificationRow("dofficeCopyConversation", desc: "Copy conversation to clipboard")
                    notificationRow("dofficeExportLog", desc: "Export session log to file")
                }
            }

            catalogSection("UI & System") {
                VStack(alignment: .leading, spacing: 6) {
                    notificationRow("dofficeCommandPalette", desc: "Open command palette", shortcut: "Cmd+K")
                    notificationRow("dofficeActionCenter", desc: "Open action center panel")
                    notificationRow("dofficeScrollToBlock", desc: "Scroll to a specific stream block")
                    notificationRow("dofficeRoleNotice", desc: "Display character role notification")
                    notificationRow("dofficeSessionStoreDidChange", desc: "Session persistence updated")
                    notificationRow("dofficeClaudeNotInstalled", desc: "Claude CLI not found alert")
                    notificationRow("dofficeDiagnosticReport", desc: "Generate diagnostic report")
                }
            }

            catalogSection("Usage in Code") {
                VStack(alignment: .leading, spacing: 8) {
                    DSCodeBlock(
                        """
                        // Post a notification
                        NotificationCenter.default.post(
                            name: .dofficeNewTab,
                            object: nil,
                            userInfo: ["path": "/project"]
                        )

                        // Observe a notification
                        .onReceive(NotificationCenter.default
                            .publisher(for: .dofficeSelectTab)) { note in
                            if let id = note.userInfo?["id"] as? String {
                                selectedTab = id
                            }
                        }
                        """,
                        language: "swift"
                    )
                }
            }
        }
    }

    private func notificationRow(_ name: String, desc: String, shortcut: String? = nil) -> some View {
        HStack(spacing: 10) {
            Text(".\(name)")
                .font(Theme.code(9.5, weight: .medium))
                .foregroundColor(Theme.accent)
                .frame(minWidth: 200, alignment: .leading)

            Text(desc)
                .font(Theme.chrome(9))
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let shortcut {
                DSKeyboardShortcut(shortcut)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.bgSurface)
        )
    }
}

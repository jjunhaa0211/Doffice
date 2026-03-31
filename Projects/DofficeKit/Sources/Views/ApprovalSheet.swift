import SwiftUI
import DesignSystem

// MARK: - [Feature 5] Approval Sheet
// ═══════════════════════════════════════════════════════

public struct ApprovalSheet: View {
    public let approval: TerminalTab.PendingApproval
    @Environment(\.dismiss) var dismiss

    public var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.shield.fill").font(.system(size: Theme.iconSize(20))).foregroundColor(Theme.yellow)
                Text(NSLocalizedString("terminal.approval.needed", comment: "")).font(Theme.mono(14, weight: .bold)).foregroundColor(Theme.textPrimary)
            }
            Text(approval.reason).font(Theme.monoSmall).foregroundColor(Theme.textSecondary)
            Text(approval.command).font(Theme.mono(11)).foregroundColor(Theme.red)
                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.red.opacity(0.05)))
                .textSelection(.enabled)
            HStack {
                Button(action: { approval.onDeny?(); dismiss() }) {
                    Text(NSLocalizedString("terminal.deny", comment: "")).font(Theme.mono(11, weight: .medium)).foregroundColor(Theme.red)
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(Theme.red.opacity(0.1)).cornerRadius(6)
                }.buttonStyle(.plain).keyboardShortcut(.escape)
                Spacer()
                Button(action: { approval.onApprove?(); dismiss() }) {
                    Text(NSLocalizedString("terminal.approve", comment: "")).font(Theme.mono(11, weight: .medium)).foregroundColor(Theme.textOnAccent)
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(Theme.accent).cornerRadius(6)
                }.buttonStyle(.plain).keyboardShortcut(.return)
            }
        }.padding(24).frame(width: 420).background(Theme.bgCard)
    }
}

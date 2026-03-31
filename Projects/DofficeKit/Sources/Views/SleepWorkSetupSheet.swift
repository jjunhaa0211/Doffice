import SwiftUI
import DesignSystem

// MARK: - CLITerminalView (SwiftTerm — 별도 파일 SwiftTermBridge.swift)
// ═══════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════
// MARK: - Sleep Work Setup Sheet
// ═══════════════════════════════════════════════════════

public struct SleepWorkSetupSheet: View {
    @ObservedObject var tab: TerminalTab
    @Environment(\.dismiss) var envDismiss
    public var onDismiss: (() -> Void)?
    @State private var task = ""
    @State private var budgetText = ""

    private func close() {
        if let onDismiss { onDismiss() } else { envDismiss() }
    }

    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "moon.zzz.fill").font(.system(size: 20)).foregroundColor(Theme.purple)
                Text(NSLocalizedString("terminal.sleepwork.title", comment: "")).font(Theme.mono(14, weight: .bold)).foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { close() }) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundColor(Theme.textDim)
                }.buttonStyle(.plain)
            }

            Text(NSLocalizedString("terminal.sleepwork.desc", comment: ""))
                .font(Theme.mono(10))
                .foregroundColor(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("terminal.sleepwork.task", comment: "")).font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.textDim)
                TextEditor(text: $task)
                    .font(Theme.monoNormal)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("terminal.sleepwork.token.budget", comment: "")).font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.textDim)
                TextField("10k", text: $budgetText)
                    .font(Theme.monoNormal)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                Text(NSLocalizedString("terminal.sleepwork.token.hint", comment: ""))
                    .font(Theme.mono(8)).foregroundColor(Theme.textDim)
            }

            HStack {
                Spacer()
                Button(action: {
                    let budget = parseBudget(budgetText)
                    tab.startSleepWork(task: task, tokenBudget: budget)
                    close()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.zzz.fill").font(.system(size: 12))
                        Text(NSLocalizedString("terminal.sleepwork.start", comment: "")).font(Theme.mono(11, weight: .bold))
                    }
                    .foregroundColor(Theme.textOnAccent)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.purple))
                }
                .buttonStyle(.plain)
                .disabled(task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(Theme.bgCard)
    }

    private func parseBudget(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasSuffix("m") {
            if let n = Double(trimmed.dropLast()) { return Int(n * 1_000_000) }
        }
        if trimmed.hasSuffix("k") {
            if let n = Double(trimmed.dropLast()) { return Int(n * 1000) }
        }
        return Int(trimmed)
    }
}

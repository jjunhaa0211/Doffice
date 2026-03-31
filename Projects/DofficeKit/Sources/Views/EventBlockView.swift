import SwiftUI
import DesignSystem

// ═══════════════════════════════════════════════════════
// MARK: - Event Block View
// ═══════════════════════════════════════════════════════

public struct EventBlockView: View {
    var block: StreamBlock
    @StateObject private var settings = AppSettings.shared
    public let compact: Bool

    public var body: some View {
        switch block.blockType {
        case .sessionStart:
            sessionStartBlock
        case .userPrompt:
            userPromptBlock
        case .thought:
            thoughtBlock
        case .toolUse(let name, _):
            toolUseBlock(name: name)
        case .toolOutput:
            toolOutputBlock
        case .toolError:
            toolErrorBlock
        case .toolEnd(let success):
            toolEndBlock(success: success)
        case .fileChange(_, let action):
            fileChangeBlock(action: action)
        case .status(let msg):
            statusBlock(msg)
        case .completion(let cost, let duration):
            completionBlock(cost: cost, duration: duration)
        case .error(let msg):
            errorBlock(msg)
        case .text:
            textBlock
        }
    }

    // MARK: - Block Styles

    private var sessionStartBlock: some View {
        HStack(spacing: 6) {
            Image(systemName: "play.circle.fill").font(.system(size: Theme.iconSize(10))).foregroundColor(Theme.green)
            Text(block.content).font(Theme.monoSmall).foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, 4)
    }

    private var userPromptBlock: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(">").font(Theme.mono(13, weight: .bold)).foregroundStyle(Theme.accentBackground)
            Text(block.content).font(Theme.mono(compact ? 11 : 13)).foregroundStyle(Theme.accentBackground)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.accent.opacity(0.06)))
    }

    private var thoughtBlock: some View {
        HStack(alignment: .top, spacing: 6) {
            Circle().fill(Theme.textDim).frame(width: 4, height: 4).padding(.top, 6)
            MarkdownTextView(text: block.content, compact: compact)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }.padding(.vertical, 2)
    }

    private func toolUseBlock(name: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(toolColor(name)).frame(width: 6, height: 6)
            Text("\(name)").font(Theme.mono(compact ? 10 : 11, weight: .bold)).foregroundColor(toolColor(name))
            Text("(\(block.content))").font(Theme.mono(compact ? 10 : 11)).foregroundColor(Theme.textSecondary).lineLimit(1)
            if !block.isComplete { ProgressView().scaleEffect(0.4).frame(width: 10, height: 10) }
        }
        .padding(.vertical, 4).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(toolColor(name).opacity(0.06)))
    }

    private var toolOutputBlock: some View {
        ToolOutputBlockView(block: block, compact: compact)
    }

    private var toolErrorBlock: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("  x ").font(Theme.mono(11)).foregroundColor(Theme.red)
            Text(block.content)
                .font(Theme.mono(compact ? 10 : 11))
                .foregroundColor(Theme.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 8)
        .background(Theme.red.opacity(0.04))
    }

    private func toolEndBlock(success: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: success ? "checkmark" : "xmark")
                .font(Theme.mono(8, weight: .bold))
                .foregroundColor(success ? Theme.green : Theme.red)
        }
        .padding(.leading, 16).padding(.vertical, 1)
    }

    private func fileChangeBlock(action: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: action == "Write" ? "doc.badge.plus" : "pencil.line")
                .font(.system(size: Theme.iconSize(9))).foregroundColor(Theme.green)
            Text(action).font(Theme.mono(10, weight: .semibold)).foregroundColor(Theme.green)
            Text(block.content).font(Theme.mono(compact ? 10 : 11)).foregroundColor(Theme.textPrimary)
        }
        .padding(.vertical, 3).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.green.opacity(0.06)))
    }

    private func statusBlock(_ msg: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle").font(.system(size: Theme.iconSize(7))).foregroundColor(Theme.textDim)
            Text(msg).font(Theme.monoTiny).foregroundColor(Theme.textDim).italic()
        }.padding(.vertical, 1)
    }

    private func completionBlock(cost: Double?, duration: Int?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: Theme.iconSize(10))).foregroundColor(Theme.green)
                Text(NSLocalizedString("terminal.complete", comment: "")).font(Theme.mono(10, weight: .bold)).foregroundColor(Theme.green)
                if let d = duration {
                    Text("\(d/1000).\(d%1000/100)s").font(Theme.mono(8)).foregroundColor(Theme.textDim)
                }
                if let c = cost, c > 0 {
                    Text(String(format: "$%.4f", c)).font(Theme.mono(8, weight: .semibold)).foregroundColor(Theme.yellow)
                }
            }

            if !block.content.isEmpty && block.content != NSLocalizedString("slash.status.completed", comment: "") {
                MarkdownTextView(text: block.content, compact: compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
    }

    private func errorBlock(_ msg: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: Theme.iconSize(10))).foregroundColor(Theme.red)
            Text(msg).font(Theme.mono(11)).foregroundColor(Theme.red)
            if !block.content.isEmpty { Text(block.content).font(Theme.monoSmall).foregroundColor(Theme.red.opacity(0.7)) }
        }
        .padding(.vertical, 4).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.red.opacity(0.05)))
    }

    private var textBlock: some View {
        Text(block.content).font(Theme.mono(compact ? 11 : 12)).foregroundColor(Theme.textTerminal)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toolColor(_ name: String) -> Color {
        switch name {
        case "Bash": return Theme.yellow
        case "Read": return Theme.accent
        case "Write", "Edit": return Theme.green
        case "Grep", "Glob": return Theme.cyan
        case "Agent": return Theme.purple
        default: return Theme.textSecondary
        }
    }
}

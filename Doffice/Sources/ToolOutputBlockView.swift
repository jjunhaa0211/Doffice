import SwiftUI
import DesignSystem

// MARK: - Tool Output Block View
// ═══════════════════════════════════════════════════════

public struct ToolOutputBlockView: View {
    var block: StreamBlock
    public let compact: Bool
    private let maxCollapsedLines = 12

    @State private var isExpanded = false
    @State private var copied = false

    private var lines: [String] {
        block.content.components(separatedBy: "\n")
    }

    private var isTruncatable: Bool {
        lines.count > maxCollapsedLines
    }

    private var displayText: String {
        if isExpanded || !isTruncatable {
            return block.content
        }
        if lines.count > 100 {
            let head = lines.prefix(3)
            let tail = lines.suffix(3)
            let hidden = lines.count - 6
            return (head + [String(format: NSLocalizedString("terminal.lines.omitted", comment: ""), hidden)] + tail).joined(separator: "\n")
        }
        let head = lines.prefix(6)
        let tail = lines.suffix(4)
        let hidden = lines.count - 10
        return (head + [String(format: NSLocalizedString("terminal.lines.omitted", comment: ""), hidden)] + tail).joined(separator: "\n")
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.textMuted.opacity(0.25))
                    .frame(width: 2)
                    .padding(.leading, 7)

                Text(displayText)
                    .font(Theme.mono(compact ? 10 : 11))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.leading, 10).padding(.vertical, 2)
            }

            HStack(spacing: 8) {
                if isTruncatable {
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                        HStack(spacing: 5) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: Theme.iconSize(7), weight: .semibold))
                            Text(isExpanded ? NSLocalizedString("terminal.collapse", comment: "") : String(format: NSLocalizedString("terminal.expand.all", comment: ""), lines.count))
                                .font(Theme.mono(compact ? 8 : 9, weight: .medium))
                        }
                        .foregroundColor(Theme.accent.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if !block.content.isEmpty {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(block.content, forType: .string)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: Theme.iconSize(7)))
                            .foregroundColor(copied ? Theme.green : Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 20).padding(.trailing, 8).padding(.vertical, 2)
        }
    }
}

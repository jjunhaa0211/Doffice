import SwiftUI
import DesignSystem

// MARK: - Tool Output Block View (truncated)
// ═══════════════════════════════════════════════════════

public struct ToolOutputBlockView: View {
    var block: StreamBlock
    public let compact: Bool
    private let maxCollapsedLines = 12

    @State private var isExpanded = false

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
                Text("  | ").font(Theme.mono(11)).foregroundColor(Theme.textDim)
                Text(displayText)
                    .font(Theme.mono(compact ? 10 : 11))
                    .foregroundColor(Theme.textTerminal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }.padding(.leading, 8)

            if isTruncatable {
                Button(action: { isExpanded.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: Theme.iconSize(7)))
                        Text(isExpanded ? NSLocalizedString("terminal.collapse", comment: "") : String(format: NSLocalizedString("terminal.expand.all", comment: ""), lines.count))
                            .font(Theme.mono(9))
                    }
                    .foregroundColor(Theme.textDim)
                    .padding(.leading, 28)
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

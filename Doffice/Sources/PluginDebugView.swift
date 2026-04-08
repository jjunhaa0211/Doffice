import SwiftUI


/// 플러그인 개발자를 위한 디버그 콘솔 뷰
public struct PluginDebugView: View {
    @ObservedObject private var pluginManager = PluginManager.shared
    @ObservedObject private var pluginHost = PluginHost.shared
    @State private var filterLevel: PluginDebugEntry.Level?
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "ant.fill")
                    .font(.system(size: Theme.iconSize(14), weight: .bold))
                    .foregroundColor(Theme.cyan)
                Text(NSLocalizedString("plugin.debug.title", comment: "Plugin Debug Console"))
                    .font(Theme.mono(13, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()

                // Event test fire buttons
                Menu {
                    ForEach(["onPromptSubmit", "onSessionComplete", "onSessionError", "onAchievementUnlock", "onLevelUp"], id: \.self) { event in
                        Button(event) {
                            pluginManager.logDebug(.event, source: "Manual", message: "Fired \(event)")
                            if let eventType = PluginEventType(rawValue: event) {
                                pluginHost.fireEvent(eventType)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: Theme.iconSize(10), weight: .bold))
                        Text(NSLocalizedString("plugin.debug.fire", comment: "Fire Event"))
                            .font(Theme.mono(9, weight: .bold))
                    }
                    .foregroundColor(Theme.orange)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.orange.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.orange.opacity(0.2), lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 140)

                Button(action: { pluginManager.clearDebugLog() }) {
                    Image(systemName: "trash")
                        .font(.system(size: Theme.iconSize(10), weight: .medium))
                        .foregroundColor(Theme.textDim)
                }.buttonStyle(.plain)

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textDim)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Theme.bgSurface)

            // Filter chips
            HStack(spacing: 4) {
                filterChip(nil, label: NSLocalizedString("plugin.debug.all", comment: "All"))
                filterChip(.event, label: NSLocalizedString("plugin.debug.events", comment: "Events"))
                filterChip(.effect, label: NSLocalizedString("plugin.debug.effects", comment: "Effects"))
                filterChip(.info, label: "Info")
                filterChip(.warning, label: NSLocalizedString("plugin.debug.warnings", comment: "Warnings"))
                filterChip(.error, label: NSLocalizedString("plugin.debug.errors", comment: "Errors"))
                Spacer()
                Text("\(filteredEntries.count)")
                    .font(Theme.mono(8, weight: .medium))
                    .foregroundColor(Theme.textDim)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Theme.bgSurface.opacity(0.5))

            Rectangle().fill(Theme.border).frame(height: 1)

            // Log entries
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    if filteredEntries.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(Theme.textDim)
                            Text(NSLocalizedString("plugin.debug.empty", comment: "No debug entries yet"))
                                .font(Theme.mono(10))
                                .foregroundColor(Theme.textDim)
                            Text(NSLocalizedString("plugin.debug.hint", comment: ""))
                                .font(Theme.mono(8))
                                .foregroundColor(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(filteredEntries) { entry in
                            debugEntryRow(entry)
                        }
                    }
                }
                .padding(8)
            }
            .background(Theme.bg)

            // Stats bar
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "puzzlepiece.fill").font(.system(size: 8)).foregroundColor(Theme.accent)
                    Text("\(pluginManager.plugins.filter(\.enabled).count) active")
                        .font(Theme.mono(8)).foregroundColor(Theme.textDim)
                }
                HStack(spacing: 4) {
                    Image(systemName: "sparkles").font(.system(size: 8)).foregroundColor(Theme.purple)
                    Text("\(pluginHost.effects.count) effects")
                        .font(Theme.mono(8)).foregroundColor(Theme.textDim)
                }
                HStack(spacing: 4) {
                    Image(systemName: "paintpalette.fill").font(.system(size: 8)).foregroundColor(Theme.cyan)
                    Text("\(pluginHost.themes.count) themes")
                        .font(Theme.mono(8)).foregroundColor(Theme.textDim)
                }
                HStack(spacing: 4) {
                    Image(systemName: "terminal").font(.system(size: 8)).foregroundColor(Theme.green)
                    Text("\(pluginHost.commands.count) commands")
                        .font(Theme.mono(8)).foregroundColor(Theme.textDim)
                }
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Theme.bgCard)
            .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .top)
        }
        .frame(minWidth: 560, minHeight: 400)
    }

    private var filteredEntries: [PluginDebugEntry] {
        guard let level = filterLevel else { return pluginManager.debugLog }
        return pluginManager.debugLog.filter { $0.level == level }
    }

    private func filterChip(_ level: PluginDebugEntry.Level?, label: String) -> some View {
        let isActive = filterLevel == level
        return Button(action: { filterLevel = level }) {
            Text(label)
                .font(Theme.mono(8, weight: isActive ? .bold : .regular))
                .foregroundColor(isActive ? Theme.accent : Theme.textDim)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(isActive ? Theme.accent.opacity(0.12) : .clear))
        }.buttonStyle(.plain)
    }

    private func debugEntryRow(_ entry: PluginDebugEntry) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: levelIcon(entry.level))
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(levelColor(entry.level))
                .frame(width: 12)

            Text(entry.timestamp, style: .time)
                .font(Theme.mono(7))
                .foregroundColor(Theme.textMuted)
                .frame(width: 55, alignment: .leading)

            Text(entry.source)
                .font(Theme.mono(7, weight: .bold))
                .foregroundColor(Theme.textDim)
                .frame(width: 70, alignment: .leading)
                .lineLimit(1)

            Text(entry.message)
                .font(Theme.mono(8))
                .foregroundColor(levelColor(entry.level))
                .lineLimit(3)

            Spacer()
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(entry.level == .error ? Theme.red.opacity(0.04) : .clear)
    }

    private func levelIcon(_ level: PluginDebugEntry.Level) -> String {
        switch level {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .event: return "bolt.fill"
        case .effect: return "sparkles"
        }
    }

    private func levelColor(_ level: PluginDebugEntry.Level) -> Color {
        switch level {
        case .info: return Theme.textSecondary
        case .warning: return Theme.orange
        case .error: return Theme.red
        case .event: return Theme.cyan
        case .effect: return Theme.purple
        }
    }
}

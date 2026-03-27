import SwiftUI
import DesignSystem

struct SavePresetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var store = CustomPresetStore.shared
    @State private var presetName = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedTint = "accent"
    let draft: NewSessionDraftSnapshot

    private let icons = ["star.fill", "hammer.fill", "shield.fill", "bolt.fill", "leaf.fill", "flame.fill", "wand.and.stars", "cpu"]
    private let tints: [(String, Color)] = [
        ("accent", Theme.accent), ("purple", Theme.purple), ("orange", Theme.orange),
        ("cyan", Theme.cyan), ("green", Theme.green), ("red", Theme.red)
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(NSLocalizedString("overlay.save.preset", comment: ""))
                    .font(Theme.mono(14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textDim)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("overlay.label.name", comment: "")).font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.textSecondary)
                TextField(NSLocalizedString("overlay.preset.placeholder", comment: ""), text: $presetName)
                    .textFieldStyle(.plain)
                    .font(Theme.mono(11))
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.3), lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("overlay.label.icon", comment: "")).font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.textSecondary)
                HStack(spacing: 8) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.system(size: Theme.iconSize(14)))
                                .foregroundColor(selectedIcon == icon ? Theme.accent : Theme.textDim)
                                .frame(width: 32, height: 32)
                                .background(RoundedRectangle(cornerRadius: 6).fill(selectedIcon == icon ? Theme.accent.opacity(0.12) : Theme.bgSurface))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(selectedIcon == icon ? Theme.accent.opacity(0.4) : Theme.border.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("overlay.label.color", comment: "")).font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.textSecondary)
                HStack(spacing: 8) {
                    ForEach(tints, id: \.0) { name, color in
                        Button(action: { selectedTint = name }) {
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(.white.opacity(selectedTint == name ? 0.8 : 0), lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 설정 요약
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("overlay.included.settings", comment: "")).font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.textSecondary)
                HStack(spacing: 8) {
                    presetTag(String(format: NSLocalizedString("overlay.model.prefix", comment: ""), "\(draft.selectedModel)"))
                    presetTag(String(format: NSLocalizedString("overlay.effort.prefix", comment: ""), "\(draft.effortLevel)"))
                    presetTag(String(format: NSLocalizedString("overlay.terminal.prefix", comment: ""), "\(draft.terminalCount)"))
                    if !draft.systemPrompt.isEmpty { presetTag(NSLocalizedString("overlay.system.prompt", comment: "")) }
                }
            }

            HStack {
                Button(NSLocalizedString("overlay.cancel", comment: "")) { dismiss() }
                    .buttonStyle(.plain)
                    .font(Theme.mono(10, weight: .bold))
                    .foregroundColor(Theme.textDim)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface))
                    .keyboardShortcut(.escape)
                Spacer()
                Button(NSLocalizedString("overlay.save", comment: "")) {
                    let preset = CustomSessionPreset(
                        name: presetName.trimmingCharacters(in: .whitespacesAndNewlines),
                        icon: selectedIcon,
                        tint: selectedTint,
                        draft: draft
                    )
                    store.save(preset)
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(Theme.mono(10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.accentBackground))
                .keyboardShortcut(.return)
                .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
        .background(Theme.bg)
    }

    private func presetTag(_ text: String) -> some View {
        Text(text)
            .font(Theme.mono(8))
            .foregroundColor(Theme.textDim)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Theme.bgSurface)
            .cornerRadius(4)
    }
}

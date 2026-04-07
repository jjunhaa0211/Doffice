import SwiftUI
import DesignSystem

struct ModifiersCatalog: View {
    @State private var isSelected = false
    @State private var isHovered = false
    @State private var isEmphasized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            catalogTitle("View Modifiers")

            catalogSection("appPanelStyle — Cards & Panels") {
                VStack(spacing: 16) {
                    Text("Default Panel")
                        .font(Theme.mono(10))
                        .foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appPanelStyle()

                    Text("Shadow Panel")
                        .font(Theme.mono(10))
                        .foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appPanelStyle(shadow: true)

                    Text("Custom Radius & Fill")
                        .font(Theme.mono(10))
                        .foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appPanelStyle(padding: 20, radius: 16, fill: Theme.bgSurface)
                }
                .frame(maxWidth: 400)
            }

            catalogSection("appFieldStyle — Input Fields") {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Text("Normal")
                            .font(Theme.mono(10))
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appFieldStyle()

                        Text("Emphasized")
                            .font(Theme.mono(10))
                            .foregroundColor(Theme.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appFieldStyle(emphasized: true)
                    }

                    DSButton(isEmphasized ? "Normal" : "Emphasized", tone: .accent, compact: true) {
                        isEmphasized.toggle()
                    }
                }
                .frame(maxWidth: 400)
            }

            catalogSection("appButtonSurface — Button Backgrounds") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        ForEach([AppChromeTone.neutral, .accent, .green, .red, .yellow, .purple], id: \.self) { tone in
                            Text(String(describing: tone))
                                .font(Theme.mono(9, weight: .bold))
                                .appButtonSurface(tone: tone)
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach([AppChromeTone.accent, .green, .red, .purple], id: \.self) { tone in
                            Text(String(describing: tone))
                                .font(Theme.mono(9, weight: .bold))
                                .appButtonSurface(tone: tone, prominent: true)
                        }
                    }
                }
            }

            catalogSection("sidebarRowStyle — Sidebar Items") {
                VStack(spacing: 4) {
                    sidebarRow("Regular item", icon: "doc", selected: false, hovered: false)
                    sidebarRow("Hovered item", icon: "doc.fill", selected: false, hovered: true)
                    sidebarRow("Selected item", icon: "star.fill", selected: true, hovered: false)
                }
                .frame(maxWidth: 280)
            }

            catalogSection("interactiveSurface — Selection States") {
                HStack(spacing: 12) {
                    VStack(spacing: 6) {
                        Text("Default")
                            .font(Theme.mono(10))
                            .foregroundColor(Theme.textSecondary)
                            .padding(12)
                            .interactiveSurface(isSelected: false)
                        Text("Off").font(Theme.code(8)).foregroundColor(Theme.textDim)
                    }
                    VStack(spacing: 6) {
                        Text("Selected")
                            .font(Theme.mono(10))
                            .foregroundColor(Theme.textPrimary)
                            .padding(12)
                            .interactiveSurface(isSelected: true)
                        Text("On").font(Theme.code(8)).foregroundColor(Theme.textDim)
                    }
                }
            }

            catalogSection("appDivider — Subtle Separator") {
                VStack(spacing: 0) {
                    Text("Content above")
                        .font(Theme.mono(10))
                        .foregroundColor(Theme.textSecondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appDivider()

                    Text("Content below")
                        .font(Theme.mono(10))
                        .foregroundColor(Theme.textSecondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: 400)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgCard))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
            }
        }
    }

    private func sidebarRow(_ label: String, icon: String, selected: Bool, hovered: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(selected ? Theme.accent : Theme.textDim)
            Text(label)
                .font(Theme.mono(10))
                .foregroundColor(selected ? Theme.textPrimary : Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sidebarRowStyle(isSelected: selected, isHovered: hovered)
    }
}

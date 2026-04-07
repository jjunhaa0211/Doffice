import SwiftUI
import DesignSystem

struct ExtensionsCatalog: View {
    @State private var hexInput = "6366F1"
    @State private var parsedColor: Color = Color(hex: "6366F1")

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            catalogTitle("Extensions & Utilities")

            catalogSection("Color(hex:) — Hex Initialization") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Hex", text: $hexInput)
                            .font(Theme.code(11))
                            .frame(width: 100)
                            .appFieldStyle()
                            .onChange(of: hexInput) { _, val in
                                if Color.isValidHex(val) { parsedColor = Color(hex: val) }
                            }

                        RoundedRectangle(cornerRadius: 6)
                            .fill(parsedColor)
                            .frame(width: 40, height: 28)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))

                        Text(Color.isValidHex(hexInput) ? "Valid" : "Invalid")
                            .font(Theme.code(9, weight: .bold))
                            .foregroundColor(Color.isValidHex(hexInput) ? Theme.green : Theme.red)
                    }

                    HStack(spacing: 8) {
                        colorChip("6366F1")
                        colorChip("10B981")
                        colorChip("F59E0B")
                        colorChip("EF4444")
                        colorChip("8B5CF6")
                        colorChip("06B6D4")
                        colorChip("fff")
                    }
                }
            }

            catalogSection("hexString — Color to Hex") {
                HStack(spacing: 16) {
                    hexDisplay("Accent", Theme.accent)
                    hexDisplay("Green", Theme.green)
                    hexDisplay("Red", Theme.red)
                    hexDisplay("Purple", Theme.purple)
                    hexDisplay("Cyan", Theme.cyan)
                }
            }

            catalogSection("luminance & contrastingTextColor — WCAG") {
                HStack(spacing: 12) {
                    contrastDemo("Light BG", Color(hex: "F8FAFC"))
                    contrastDemo("Medium", Color(hex: "64748B"))
                    contrastDemo("Dark BG", Color(hex: "1E293B"))
                    contrastDemo("Accent", Color(hex: "6366F1"))
                    contrastDemo("Green", Color(hex: "10B981"))
                }
            }

            catalogSection("Int.tokenFormatted — Compact Numbers") {
                VStack(alignment: .leading, spacing: 8) {
                    tokenRow(0)
                    tokenRow(500)
                    tokenRow(1_500)
                    tokenRow(10_000)
                    tokenRow(123_456)
                    tokenRow(1_500_000)
                    tokenRow(2_345_678)
                }
            }
        }
    }

    private func colorChip(_ hex: String) -> some View {
        Button {
            hexInput = hex
            parsedColor = Color(hex: hex)
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: hex))
                .frame(width: 28, height: 28)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func hexDisplay(_ label: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 40, height: 28)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
            Text("#\(color.hexString)")
                .font(Theme.code(8))
                .foregroundColor(Theme.textDim)
            Text(label)
                .font(Theme.code(8))
                .foregroundColor(Theme.textMuted)
        }
    }

    private func contrastDemo(_ label: String, _ bg: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(bg)
                    .frame(width: 70, height: 36)
                Text("Text")
                    .font(Theme.mono(10, weight: .bold))
                    .foregroundColor(bg.contrastingTextColor)
            }
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))

            Text(String(format: "L: %.2f", bg.luminance))
                .font(Theme.code(8))
                .foregroundColor(Theme.textDim)
            Text(label)
                .font(Theme.code(8))
                .foregroundColor(Theme.textMuted)
        }
    }

    private func tokenRow(_ value: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(value)")
                .font(Theme.code(10))
                .foregroundColor(Theme.textDim)
                .frame(width: 80, alignment: .trailing)
            Text("→")
                .font(Theme.code(10))
                .foregroundColor(Theme.textMuted)
            Text(value.tokenFormatted)
                .font(Theme.code(10, weight: .bold))
                .foregroundColor(Theme.accent)
        }
    }
}

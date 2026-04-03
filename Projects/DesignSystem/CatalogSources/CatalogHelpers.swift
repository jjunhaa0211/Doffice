import SwiftUI
import DesignSystem

func catalogTitle(_ title: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(Theme.mono(18, weight: .bold))
            .foregroundColor(Theme.textPrimary)
        Rectangle()
            .fill(Theme.border)
            .frame(height: 1)
    }
}

@ViewBuilder
func catalogSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.mono(13, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text("Preview the component in a production-like surface.")
                .font(Theme.chrome(8.5))
                .foregroundColor(Theme.textDim)
        }

        content()
    }
    .padding(16)
    .background(
        RoundedRectangle(cornerRadius: Theme.cornerXL)
            .fill(Theme.bgCard)
    )
    .overlay(
        RoundedRectangle(cornerRadius: Theme.cornerXL)
            .stroke(Theme.border, lineWidth: 1)
    )
}

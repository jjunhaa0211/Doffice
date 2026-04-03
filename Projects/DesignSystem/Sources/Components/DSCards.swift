import SwiftUI

// MARK: - Stat Card (통합 stat/metric 카드)

public struct DSStatCard: View {
    public let title: String
    public let value: String
    public var subtitle: String = ""
    public var icon: String = ""
    public var tint: Color = Theme.textPrimary

    public init(title: String, value: String, subtitle: String = "", icon: String = "", tint: Color = Theme.textPrimary) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.sp3) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.sp2) {
                    HStack(spacing: Theme.sp1 + 1) {
                        if !icon.isEmpty {
                            ZStack {
                                Circle()
                                    .fill(Theme.accentBg(tint))
                                    .frame(width: 26, height: 26)
                                Image(systemName: icon)
                                    .font(.system(size: Theme.iconSize(10), weight: .semibold))
                                    .foregroundColor(tint)
                            }
                        }
                        Text(title.uppercased())
                            .font(Theme.chrome(8, weight: .bold))
                            .tracking(1.1)
                            .foregroundColor(Theme.textDim)
                    }

                    Text(value)
                        .font(Theme.mono(22, weight: .black))
                        .foregroundColor(tint)
                        .lineLimit(1)
                }

                Spacer(minLength: Theme.sp3)

                RoundedRectangle(cornerRadius: Theme.cornerLarge)
                    .fill(tint.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerLarge)
                            .stroke(tint.opacity(0.22), lineWidth: 1)
                    )
            }

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(Theme.mono(9.5))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.sp4)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerXL)
                .fill(Theme.panelBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerXL)
                .stroke(Theme.border, lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Theme.cornerXL)
                .stroke(Theme.topHighlight.opacity(0.4), lineWidth: 1)
                .blur(radius: 0.2)
                .mask(
                    LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .top, endPoint: .bottom)
                )
        }
        .shadow(color: Theme.panelShadow.opacity(0.24), radius: 14, x: 0, y: 8)
    }
}

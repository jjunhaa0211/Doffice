import SwiftUI

// MARK: - Status Badge (Vercel-style: tight, border-accented)

public struct AppStatusBadge: View {
    public let title: String
    public let symbol: String
    public let tint: Color
    public var compact: Bool = true

    public init(title: String, symbol: String, tint: Color, compact: Bool = true) {
        self.title = title
        self.symbol = symbol
        self.tint = tint
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: compact ? Theme.chromeIconSize(8) : Theme.iconSize(9), weight: .medium))
            Text(title)
                .font(compact ? Theme.chrome(8, weight: .medium) : Theme.mono(9, weight: .medium))
                .lineLimit(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, compact ? Theme.sp1 + 2 : Theme.sp2)
        .padding(.vertical, compact ? 2 : 3)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerSmall)
                .fill(Theme.accentBg(tint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerSmall)
                .stroke(Theme.accentBorder(tint), lineWidth: 1)
        )
    }
}

// MARK: - Status Dot (Vercel deployments style: tiny colored circle)

public struct AppStatusDot: View {
    public let color: Color
    public var size: CGFloat = 6

    public init(color: Color, size: CGFloat = 6) {
        self.color = color
        self.size = size
    }

    public var body: some View {
        Circle().fill(color).frame(width: size, height: size)
    }
}

// MARK: - Section Header (Vercel panel headers)

public struct AppSectionHeader: View {
    public let title: String
    public var count: Int? = nil
    public var action: (() -> Void)? = nil
    public var actionLabel: String = ""

    public init(title: String, count: Int? = nil, action: (() -> Void)? = nil, actionLabel: String = "") {
        self.title = title
        self.count = count
        self.action = action
        self.actionLabel = actionLabel
    }

    public var body: some View {
        HStack(spacing: Theme.sp2) {
            Text(title.uppercased())
                .font(Theme.chrome(9, weight: .semibold))
                .foregroundColor(Theme.textDim)
                .tracking(0.5)
            if let count {
                Text("\(count)")
                    .font(Theme.chrome(8, weight: .bold))
                    .foregroundColor(Theme.textMuted)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Theme.bgTertiary))
            }
            Spacer()
            if let action, !actionLabel.isEmpty {
                Button(action: action) {
                    Text(actionLabel)
                        .font(Theme.chrome(9, weight: .medium))
                        .foregroundColor(Theme.textDim)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.sp3)
        .padding(.vertical, Theme.sp2)
    }
}

// MARK: - Empty State (Vercel: minimal, informative)

public struct AppEmptyStateView: View {
    public let title: String
    public let message: String
    public let symbol: String
    public var tint: Color = Theme.textDim

    public init(title: String, message: String, symbol: String, tint: Color = Theme.textDim) {
        self.title = title
        self.message = message
        self.symbol = symbol
        self.tint = tint
    }

    public var body: some View {
        VStack(spacing: Theme.sp3) {
            Image(systemName: symbol)
                .font(.system(size: Theme.iconSize(20), weight: .light))
                .foregroundColor(tint.opacity(0.5))
            VStack(spacing: Theme.sp1) {
                Text(title)
                    .font(Theme.mono(11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                Text(message)
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.textDim)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.sp8)
        .padding(.horizontal, Theme.sp4)
    }
}

// MARK: - Key-Value Row (for stats, metadata display)

public struct AppKeyValueRow: View {
    public let key: String
    public let value: String
    public var valueColor: Color = Theme.textPrimary
    public var mono: Bool = false

    public init(key: String, value: String, valueColor: Color = Theme.textPrimary, mono: Bool = false) {
        self.key = key
        self.value = value
        self.valueColor = valueColor
        self.mono = mono
    }

    public var body: some View {
        HStack {
            Text(key)
                .font(Theme.mono(10))
                .foregroundColor(Theme.textDim)
            Spacer()
            Text(value)
                .font(mono ? Theme.code(10, weight: .medium) : Theme.mono(10, weight: .medium))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Inline Code Block

public struct AppInlineCode: View {
    public let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(Theme.code(10))
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, Theme.sp1 + 1)
            .padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 3).fill(Theme.bgTertiary))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.borderSubtle, lineWidth: 1))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 통합 모달 시스템 (DSModal)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// 모든 시트/모달이 동일한 구조를 따름:
// DSModalShell > DSModalHeader > Content > DSModalFooter
// 헤더: 아이콘 + 타이틀 + 서브타이틀 + 닫기 버튼
// 바디: ScrollView + 섹션들
// 푸터: 좌측 보조 액션 + 우측 주요 액션

/// 모달 전체 컨테이너
public struct DSModalShell<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Theme.bg)
    }
}

/// 통합 모달 헤더
public struct DSModalHeader: View {
    public let icon: String
    public let iconColor: Color
    public let title: String
    public var subtitle: String = ""
    public var trailing: AnyView? = nil
    public var onClose: (() -> Void)? = nil

    public init(icon: String, iconColor: Color, title: String, subtitle: String = "", trailing: AnyView? = nil, onClose: (() -> Void)? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.onClose = onClose
    }

    public var body: some View {
        HStack(spacing: Theme.sp3) {
            // 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cornerMedium)
                    .fill(Theme.accentBg(iconColor))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: Theme.iconSize(14), weight: .medium))
                    .foregroundColor(iconColor)
            }

            // 타이틀 영역
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.mono(13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Theme.mono(10))
                        .foregroundColor(Theme.textDim)
                }
            }

            Spacer()

            // 트레일링 (카운터, 배지 등)
            if let trailing { trailing }

            // 닫기 버튼
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.textDim)
                        .frame(width: 24, height: 24)
                        .background(RoundedRectangle(cornerRadius: Theme.cornerSmall).fill(Theme.bgSurface))
                        .overlay(RoundedRectangle(cornerRadius: Theme.cornerSmall).stroke(Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.sp5)
        .padding(.vertical, Theme.sp4)
        .background(Theme.bgCard)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.border).frame(height: 1) }
    }
}

/// 모달 푸터 (액션 바)
public struct DSModalFooter<Leading: View, Trailing: View>: View {
    public let leading: Leading
    public let trailing: Trailing

    public init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: Theme.sp2) {
            leading
            Spacer()
            trailing
        }
        .padding(.horizontal, Theme.sp5)
        .padding(.vertical, Theme.sp3)
        .background(Theme.bgCard)
        .overlay(alignment: .top) { Rectangle().fill(Theme.border).frame(height: 1) }
    }
}

/// 모달 내부 섹션 (통합 settingsSection 대체)
public struct DSSection<Content: View>: View {
    public let title: String
    public var subtitle: String = ""
    public let content: Content

    public init(title: String, subtitle: String = "", @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.sp3) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.mono(11, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Theme.mono(9))
                        .foregroundColor(Theme.textDim)
                }
            }
            content
        }
        .padding(Theme.sp4)
        .background(RoundedRectangle(cornerRadius: Theme.cornerLarge).fill(Theme.bgCard))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerLarge).stroke(Theme.border, lineWidth: 1))
    }
}

/// 탭 바 (설정, 필터 등에서 사용)
public struct DSTabBar: View {
    public let tabs: [(String, String)]  // (icon, label)
    @Binding public var selectedIndex: Int

    public init(tabs: [(String, String)], selectedIndex: Binding<Int>) {
        self.tabs = tabs
        self._selectedIndex = selectedIndex
    }

    public var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: { selectedIndex = index }) {
                    HStack(spacing: 4) {
                        Image(systemName: tab.0)
                            .font(.system(size: Theme.chromeIconSize(9), weight: .medium))
                        Text(tab.1)
                            .font(Theme.chrome(9, weight: index == selectedIndex ? .semibold : .regular))
                    }
                    .foregroundColor(index == selectedIndex ? Theme.textPrimary : Theme.textDim)
                    .padding(.horizontal, Theme.sp3)
                    .padding(.vertical, Theme.sp2)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerMedium)
                            .fill(index == selectedIndex ? Theme.bgSurface : .clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerMedium)
                            .stroke(index == selectedIndex ? Theme.border : .clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: Theme.cornerLarge).fill(Theme.bgCard))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerLarge).stroke(Theme.border, lineWidth: 1))
    }
}

/// 통합 필터 칩
public struct DSFilterChip: View {
    public let label: String
    public let isSelected: Bool
    public var count: Int? = nil
    public let action: () -> Void

    public init(label: String, isSelected: Bool, count: Int? = nil, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.count = count
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                    .font(Theme.chrome(9, weight: isSelected ? .semibold : .regular))
                if let count {
                    Text("\(count)")
                        .font(Theme.chrome(8, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                }
            }
            .foregroundColor(isSelected ? Theme.textPrimary : Theme.textDim)
            .padding(.horizontal, Theme.sp3)
            .padding(.vertical, Theme.sp1 + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerMedium)
                    .fill(isSelected ? Theme.bgSurface : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerMedium)
                    .stroke(isSelected ? Theme.border : Theme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// 통합 리스트 행 컴포넌트
public struct DSListRow<Leading: View, Trailing: View>: View {
    public let leading: Leading
    public let title: String
    public var subtitle: String = ""
    public let trailing: Trailing
    public var isSelected: Bool = false

    public init(title: String, subtitle: String = "", isSelected: Bool = false, @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: Theme.sp3) {
            leading
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Theme.mono(10, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Theme.mono(9))
                        .foregroundColor(Theme.textDim)
                        .lineLimit(1)
                }
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, Theme.sp3)
        .padding(.vertical, Theme.sp2)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerMedium)
                .fill(isSelected ? Theme.bgSelected : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerMedium)
                .stroke(isSelected ? Theme.border : .clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

/// 통합 stat/metric 카드
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
        VStack(alignment: .leading, spacing: Theme.sp2) {
            HStack(spacing: Theme.sp1) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: Theme.iconSize(9)))
                        .foregroundColor(Theme.textDim)
                }
                Text(title)
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.textDim)
            }
            Text(value)
                .font(Theme.mono(16, weight: .semibold))
                .foregroundColor(tint)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.textDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.sp3)
        .background(RoundedRectangle(cornerRadius: Theme.cornerLarge).fill(Theme.bgCard))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerLarge).stroke(Theme.border, lineWidth: 1))
    }
}

/// 통합 프로그레스 바
public struct DSProgressBar: View {
    public let value: Double  // 0.0 ~ 1.0
    public var tint: Color = Theme.accent
    public var height: CGFloat = 4

    public init(value: Double, tint: Color = Theme.accent, height: CGFloat = 4) {
        self.value = value
        self.tint = tint
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Theme.bgSurface)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(tint)
                    .frame(width: geo.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: height)
    }
}

import SwiftUI
import AppKit
import DesignSystem

enum CoffeeSupportProvider: String, CaseIterable, Identifiable {
    case kakaoBank
    case toss

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kakaoBank: return NSLocalizedString("coffee.bank.kakao", comment: "")
        case .toss: return NSLocalizedString("coffee.bank.toss", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .kakaoBank: return "building.columns.fill"
        case .toss: return "paperplane.fill"
        }
    }

    var tint: Color {
        switch self {
        case .kakaoBank: return Theme.yellow
        case .toss: return Theme.cyan
        }
    }

    var appURL: URL? {
        switch self {
        case .kakaoBank:
            return URL(string: "kakaobank://")
        case .toss:
            return URL(string: "supertoss://toss/pay")
        }
    }

    var fallbackURL: URL? {
        switch self {
        case .kakaoBank:
            return URL(string: "https://www.kakaobank.com/view/main")
        case .toss:
            return URL(string: "https://toss.im")
        }
    }

    var subtitle: String {
        switch self {
        case .kakaoBank: return NSLocalizedString("coffee.bank.kakao.subtitle", comment: "")
        case .toss: return NSLocalizedString("coffee.bank.toss.subtitle", comment: "")
        }
    }
}

struct CoffeeSupportPopoverView: View {
    @ObservedObject private var settings = AppSettings.shared
    var onRequestSettings: (() -> Void)? = nil
    var embedded: Bool = false

    @State private var feedback: Feedback?
    @State private var copied = false

    struct Feedback {
        let icon: String
        let text: String
        let tint: Color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack(spacing: 12) {
                Text(settings.coffeeSupportDisplayTitle)
                    .font(Theme.mono(14, weight: .black))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            // 안내 메시지
            Text(settings.coffeeSupportMessage)
                .font(Theme.mono(9))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if settings.hasCoffeeSupportDestination {
                // 계좌 카드
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(settings.trimmedCoffeeSupportBankName.isEmpty ? NSLocalizedString("coffee.bank.kakao", comment: "") : settings.trimmedCoffeeSupportBankName)
                                .font(Theme.mono(9, weight: .semibold))
                                .foregroundColor(Theme.textDim)
                            Text(settings.trimmedCoffeeSupportAccountNumber.isEmpty ? "7777015832634" : settings.trimmedCoffeeSupportAccountNumber)
                                .font(Theme.mono(15, weight: .black))
                                .foregroundColor(Theme.textPrimary)
                        }
                        Spacer()
                        Button(action: {
                            copySupportAccount(showFeedback: true)
                            withAnimation(.easeInOut(duration: 0.2)) { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { copied = false }
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc.fill")
                                    .font(.system(size: Theme.iconSize(10), weight: .bold))
                                Text(copied ? NSLocalizedString("coffee.copied", comment: "") : NSLocalizedString("coffee.copy", comment: ""))
                                    .font(Theme.mono(9, weight: .bold))
                            }
                            .foregroundColor(copied ? Theme.green : Theme.orange)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Capsule().fill((copied ? Theme.green : Theme.orange).opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.bgSurface.opacity(0.7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.border.opacity(0.25), lineWidth: 1)
                    )
                }

                // 송금 버튼들
                VStack(spacing: 6) {
                    ForEach(CoffeeSupportProvider.allCases) { provider in
                        providerButton(provider)
                    }
                }

                // 안내
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: Theme.iconSize(9)))
                        .foregroundColor(Theme.textDim)
                    Text(NSLocalizedString("coffee.fallback.info", comment: ""))
                        .font(Theme.mono(8))
                        .foregroundColor(Theme.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                // 계좌 미설정 상태
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: Theme.iconSize(11), weight: .bold))
                            .foregroundColor(Theme.orange)
                        Text(NSLocalizedString("coffee.setup.hint", comment: ""))
                            .font(Theme.mono(9))
                            .foregroundColor(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let onRequestSettings {
                        Button(action: onRequestSettings) {
                            Text(NSLocalizedString("coffee.open.settings", comment: ""))
                                .font(Theme.mono(9, weight: .bold))
                                .foregroundColor(Theme.orange)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.orange.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.bgSurface.opacity(0.5)))
            }

            if let feedback {
                HStack(spacing: 6) {
                    Image(systemName: feedback.icon)
                        .font(.system(size: Theme.iconSize(10), weight: .bold))
                    Text(feedback.text)
                        .font(Theme.mono(8, weight: .medium))
                }
                .foregroundColor(feedback.tint)
                .transition(.opacity)
            }
        }
        .padding(embedded ? 0 : 16)
        .frame(maxWidth: embedded ? .infinity : 320, alignment: .leading)
        .background(embedded ? AnyShapeStyle(.clear) : AnyShapeStyle(Theme.bgCard))
        .clipShape(RoundedRectangle(cornerRadius: embedded ? 0 : 16))
        .overlay(
            RoundedRectangle(cornerRadius: embedded ? 0 : 16)
                .stroke(embedded ? .clear : Theme.border.opacity(0.35), lineWidth: embedded ? 0 : 1)
        )
        .onAppear {
            settings.ensureCoffeeSupportPreset()
        }
    }

    func providerButton(_ provider: CoffeeSupportProvider) -> some View {
        Button(action: { openProvider(provider) }) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(provider.tint.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: provider.icon)
                        .font(.system(size: Theme.iconSize(14), weight: .bold))
                        .foregroundColor(provider.tint)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(provider.title)
                        .font(Theme.mono(10, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(provider.subtitle)
                        .font(Theme.mono(8))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer(minLength: 0)

                Text(NSLocalizedString("coffee.open", comment: ""))
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundColor(provider.tint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(provider.tint.opacity(0.1))
                    )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.bgSurface.opacity(0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(provider.tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    func openProvider(_ provider: CoffeeSupportProvider) {
        guard copySupportAccount(showFeedback: false) else {
            feedback = Feedback(icon: "exclamationmark.triangle.fill", text: NSLocalizedString("coffee.account.empty", comment: ""), tint: Theme.orange)
            return
        }

        if let appURL = provider.appURL, NSWorkspace.shared.open(appURL) {
            feedback = Feedback(icon: "arrow.up.right.square.fill", text: String(format: NSLocalizedString("coffee.opened", comment: ""), provider.title), tint: provider.tint)
            return
        }

        if let fallbackURL = provider.fallbackURL, NSWorkspace.shared.open(fallbackURL) {
            feedback = Feedback(icon: "safari.fill", text: String(format: NSLocalizedString("coffee.fallback.opened", comment: ""), provider.title), tint: provider.tint)
            return
        }

        feedback = Feedback(icon: "doc.on.doc.fill", text: String(format: NSLocalizedString("coffee.copy.only", comment: ""), provider.title), tint: provider.tint)
    }

    @discardableResult
    func copySupportAccount(showFeedback: Bool) -> Bool {
        let accountText = settings.coffeeSupportAccountDisplayText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accountText.isEmpty else { return false }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(accountText, forType: .string)

        if showFeedback {
            feedback = Feedback(icon: "doc.on.doc.fill", text: NSLocalizedString("coffee.account.copied", comment: ""), tint: Theme.orange)
        }
        return true
    }
}

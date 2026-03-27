import SwiftUI
import DesignSystem

// ═══════════════════════════════════════════════════════
// MARK: - Onboarding View (첫 실행 튜토리얼)
// ═══════════════════════════════════════════════════════

struct OnboardingView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var animateIn = false
    @State private var hoveredFeature: String?

    private let totalSteps = 5

    var body: some View {
        ZStack {
            // 배경 그라디언트
            backgroundGradient

            VStack(spacing: 0) {
                // 상단 바
                topBar
                    .padding(.top, 16).padding(.horizontal, 24)

                // 컨텐츠
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    sessionStep.tag(1)
                    officeStep.tag(2)
                    shortcutsStep.tag(3)
                    readyStep.tag(4)
                }
                .tabViewStyle(.automatic)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 하단 네비게이션
                bottomBar
                    .padding(.bottom, 20).padding(.horizontal, 28)
            }
        }
        .frame(width: 600, height: 540)
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        .onAppear { withAnimation(.easeOut(duration: 0.5)) { animateIn = true } }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Theme.bg
            LinearGradient(
                colors: [stepAccent.opacity(0.06), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.4), value: currentStep)
        }
    }

    private var stepAccent: Color {
        switch currentStep {
        case 0: return Theme.accent
        case 1: return Theme.green
        case 2: return Theme.purple
        case 3: return Theme.cyan
        case 4: return Theme.yellow
        default: return Theme.accent
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // 스텝 인디케이터
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i == currentStep ? stepAccent : Theme.textDim.opacity(0.2))
                        .frame(width: i == currentStep ? 24 : 8, height: 4)
                        .animation(.spring(response: 0.3), value: currentStep)
                }
            }

            Spacer()

            Text("\(currentStep + 1)/\(totalSteps)")
                .font(Theme.mono(9, weight: .medium))
                .foregroundColor(Theme.textDim)

            Button(action: completeOnboarding) {
                Text(NSLocalizedString("onboard.skip", comment: ""))
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundColor(Theme.textDim)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Theme.bgSurface))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button(action: { withAnimation(.spring(response: 0.35)) { currentStep -= 1 } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 10, weight: .bold))
                        Text(NSLocalizedString("onboard.previous", comment: "")).font(Theme.mono(11, weight: .bold))
                    }
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgSurface))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if currentStep < totalSteps - 1 {
                Button(action: { withAnimation(.spring(response: 0.35)) { currentStep += 1 } }) {
                    HStack(spacing: 4) {
                        Text(NSLocalizedString("onboard.next", comment: "")).font(Theme.mono(11, weight: .bold))
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 22).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(stepAccent))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
            } else {
                Button(action: completeOnboarding) {
                    HStack(spacing: 6) {
                        Text(NSLocalizedString("onboard.start", comment: "")).font(Theme.mono(12, weight: .black))
                        Image(systemName: "arrow.right").font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 28).padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Theme.accent, Theme.purple], startPoint: .leading, endPoint: .trailing))
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()

            // 로고 애니메이션
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateIn ? 1 : 0.5)
                Circle()
                    .fill(Theme.accent.opacity(0.05))
                    .frame(width: 130, height: 130)
                    .scaleEffect(animateIn ? 1 : 0.3)
                Text("⛏")
                    .font(.system(size: 44))
                    .scaleEffect(animateIn ? 1 : 0)
            }

            VStack(spacing: 8) {
                Text(NSLocalizedString("app.name", comment: ""))
                    .font(Theme.mono(28, weight: .black))
                    .foregroundColor(Theme.textPrimary)
                Text(NSLocalizedString("onboard.subtitle", comment: ""))
                    .font(Theme.mono(13))
                    .foregroundColor(Theme.textSecondary)
            }

            // 핵심 가치 3개
            HStack(spacing: 12) {
                valueChip(icon: "eye.fill", label: NSLocalizedString("onboard.visualization", comment: ""), color: Theme.accent)
                valueChip(icon: "bolt.fill", label: NSLocalizedString("onboard.automation", comment: ""), color: Theme.green)
                valueChip(icon: "person.3.fill", label: NSLocalizedString("onboard.collaboration", comment: ""), color: Theme.purple)
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step 1: Sessions

    private var sessionStep: some View {
        VStack(spacing: 16) {
            Spacer()

            stepHeader(
                icon: "terminal.fill",
                color: Theme.green,
                title: NSLocalizedString("onboard.session.title", comment: ""),
                subtitle: NSLocalizedString("onboard.session.subtitle", comment: "")
            )

            VStack(spacing: 8) {
                tipCard(
                    icon: "plus.circle.fill",
                    title: "Cmd+T",
                    desc: NSLocalizedString("onboard.session.new.desc", comment: ""),
                    accent: Theme.green
                )
                tipCard(
                    icon: "number",
                    title: "Cmd+1~9",
                    desc: NSLocalizedString("onboard.session.switch.desc", comment: ""),
                    accent: Theme.accent
                )
                tipCard(
                    icon: "magnifyingglass",
                    title: "Cmd+P",
                    desc: NSLocalizedString("onboard.session.palette.desc", comment: ""),
                    accent: Theme.cyan
                )
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 2: Office

    private var officeStep: some View {
        VStack(spacing: 16) {
            Spacer()

            stepHeader(
                icon: "building.2.fill",
                color: Theme.purple,
                title: NSLocalizedString("onboard.office.title", comment: ""),
                subtitle: NSLocalizedString("onboard.office.subtitle", comment: "")
            )

            // 오피스 미리보기 카드
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    miniCharacterCard(name: NSLocalizedString("onboard.office.planner", comment: ""), icon: "list.bullet.clipboard", color: Theme.purple, status: NSLocalizedString("onboard.office.planning", comment: ""))
                    miniCharacterCard(name: NSLocalizedString("onboard.office.developer", comment: ""), icon: "hammer.fill", color: Theme.accent, status: NSLocalizedString("onboard.office.coding", comment: ""))
                    miniCharacterCard(name: NSLocalizedString("onboard.office.qa", comment: ""), icon: "checkmark.shield", color: Theme.green, status: NSLocalizedString("onboard.office.testing", comment: ""))
                    miniCharacterCard(name: NSLocalizedString("onboard.office.reporter", comment: ""), icon: "doc.text.fill", color: Theme.orange, status: NSLocalizedString("onboard.office.writing", comment: ""))
                }

                Text(NSLocalizedString("onboard.office.desc", comment: ""))
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.textDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 12)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.bgCard.opacity(0.8)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.purple.opacity(0.15), lineWidth: 1))

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 3: Shortcuts

    private var shortcutsStep: some View {
        VStack(spacing: 16) {
            Spacer()

            stepHeader(
                icon: "keyboard.fill",
                color: Theme.cyan,
                title: NSLocalizedString("onboard.shortcuts.title", comment: ""),
                subtitle: NSLocalizedString("onboard.shortcuts.subtitle", comment: "")
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                shortcutCard(key: "⌘T", label: NSLocalizedString("onboard.shortcut.new", comment: ""))
                shortcutCard(key: "⌘W", label: NSLocalizedString("onboard.shortcut.close", comment: ""))
                shortcutCard(key: "⌘P", label: NSLocalizedString("onboard.shortcut.palette", comment: ""))
                shortcutCard(key: "⌘J", label: NSLocalizedString("onboard.shortcut.center", comment: ""))
                shortcutCard(key: "⌘R", label: NSLocalizedString("onboard.shortcut.refresh", comment: ""))
                shortcutCard(key: "⌘K", label: NSLocalizedString("onboard.shortcut.clear", comment: ""))
                shortcutCard(key: "⌘.", label: NSLocalizedString("onboard.shortcut.cancel", comment: ""))
                shortcutCard(key: "⌘1~9", label: NSLocalizedString("onboard.shortcut.switch", comment: ""))
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 4: Ready

    private var readyStep: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.yellow.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.yellow, Theme.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(spacing: 8) {
                Text(NSLocalizedString("onboard.ready.title", comment: ""))
                    .font(Theme.mono(24, weight: .black))
                    .foregroundColor(Theme.textPrimary)
                Text(NSLocalizedString("onboard.ready.subtitle", comment: ""))
                    .font(Theme.mono(12))
                    .foregroundColor(Theme.textSecondary)
            }

            // 빠른 시작 팁
            VStack(spacing: 6) {
                quickTip(icon: "gearshape.fill", text: NSLocalizedString("onboard.tip.tutorial", comment: ""))
                quickTip(icon: "paintbrush.fill", text: NSLocalizedString("onboard.tip.theme", comment: ""))
                quickTip(icon: "star.fill", text: NSLocalizedString("onboard.tip.level", comment: ""))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.bgCard.opacity(0.6)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.2), lineWidth: 1))

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Component Views

    private func valueChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: Theme.iconSize(11)))
                .foregroundColor(color)
            Text(label)
                .font(Theme.mono(10, weight: .bold))
                .foregroundColor(Theme.textPrimary)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.15), lineWidth: 1))
    }

    private func stepHeader(icon: String, color: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.1)).frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(color)
            }
            Text(title)
                .font(Theme.mono(20, weight: .black))
                .foregroundColor(Theme.textPrimary)
            Text(subtitle)
                .font(Theme.mono(11))
                .foregroundColor(Theme.textSecondary)
        }
    }

    private func tipCard(icon: String, title: String, desc: String, accent: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(accent.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: Theme.iconSize(14)))
                    .foregroundColor(accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.mono(11, weight: .black))
                    .foregroundColor(Theme.textPrimary)
                Text(desc)
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.textDim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgCard))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.12), lineWidth: 1))
    }

    private func miniCharacterCard(name: String, icon: String, color: Color, status: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: Theme.iconSize(14)))
                    .foregroundColor(color)
            }
            Text(name)
                .font(Theme.mono(9, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text(status)
                .font(Theme.mono(7))
                .foregroundColor(Theme.textDim)
                .lineLimit(1)
        }
    }

    private func shortcutCard(key: String, label: String) -> some View {
        HStack(spacing: 8) {
            Text(key)
                .font(Theme.mono(11, weight: .black))
                .foregroundColor(Theme.cyan)
                .frame(width: 56, alignment: .trailing)
            Text(label)
                .font(Theme.mono(10))
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgCard))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.15), lineWidth: 1))
    }

    private func quickTip(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: Theme.iconSize(10)))
                .foregroundColor(Theme.yellow)
                .frame(width: 16)
            Text(text)
                .font(Theme.mono(9))
                .foregroundColor(Theme.textDim)
            Spacer()
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        dismiss()
    }
}

import SwiftUI
import DesignSystem

extension NewTabSheet {
    // MARK: - 폴더 신뢰 확인 화면

    var trustPromptView: some View {
        VStack(spacing: 0) {
            // 터미널 스타일 헤더
            VStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: Theme.iconSize(28))).foregroundColor(Theme.yellow)

                Text(NSLocalizedString("terminal.trust.title", comment: ""))
                    .font(Theme.mono(14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }.padding(.top, 20).padding(.bottom, 12)

            // 경로 표시
            HStack(spacing: 6) {
                Image(systemName: "folder.fill").font(.system(size: Theme.iconSize(10))).foregroundStyle(Theme.accentBackground)
                Text(projectPath)
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.accentBackground).lineLimit(1).truncationMode(.middle)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.accent.opacity(0.06)))
            .padding(.horizontal, 24)

            // 안내 텍스트
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("terminal.trust.question", comment: ""))
                    .font(Theme.mono(11, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                Text(NSLocalizedString("terminal.trust.hint", comment: ""))
                    .font(Theme.mono(9))
                    .foregroundColor(Theme.textDim)

                Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, 4)

                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: Theme.iconSize(9))).foregroundColor(Theme.yellow)
                    Text(trustWarningText)
                        .font(Theme.mono(9)).foregroundColor(Theme.yellow)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16).padding(.horizontal, 8)

            Spacer(minLength: 8)

            // 선택 버튼
            VStack(spacing: 6) {
                Button(action: {
                    approveFolderTrustAndLaunch()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: Theme.iconSize(10), weight: .bold))
                            .foregroundColor(Theme.green)
                        Text(NSLocalizedString("terminal.trust.yes", comment: ""))
                            .font(Theme.mono(11, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: Theme.iconSize(12)))
                            .foregroundColor(Theme.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.green.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.green.opacity(0.3), lineWidth: 1)))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .keyboardShortcut(.return)
                .disabled(isCreatingSessions)
                .accessibilityLabel(NSLocalizedString("terminal.trust.yes.a11y", comment: ""))
                .accessibilityHint(NSLocalizedString("terminal.trust.yes.a11y.hint", comment: ""))

                Button(action: {
                    withAnimation(sheetAnimation) {
                        showTrustPrompt = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Color.clear.frame(width: 12, height: 12)
                        Text(NSLocalizedString("terminal.trust.no", comment: ""))
                            .font(Theme.mono(11))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "xmark.circle")
                            .font(.system(size: Theme.iconSize(12)))
                            .foregroundColor(Theme.textDim)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border.opacity(0.3), lineWidth: 1)))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .keyboardShortcut(.escape)
                .disabled(isCreatingSessions)
                .accessibilityLabel(NSLocalizedString("terminal.trust.no.a11y", comment: ""))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: min(520, preferredSheetWidth - 72))
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Theme.border.opacity(0.45), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
    }

}

import SwiftUI
import DesignSystem
import DofficeKit

extension SettingsView {
    // MARK: - 토큰 탭

    var tokenTab: some View {
        let protectionReason = tokenTracker.startBlockReason(isAutomation: false)
        return VStack(spacing: 14) {
            settingsSection(title: NSLocalizedString("settings.usage", comment: ""), subtitle: NSLocalizedString("settings.usage.subtitle", comment: "")) {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        usageMetricCard(
                            title: NSLocalizedString("settings.usage.today", comment: ""),
                            value: tokenTracker.formatTokens(tokenTracker.todayTokens),
                            secondary: "$" + String(format: "%.2f", tokenTracker.todayCost),
                            tint: Theme.accent,
                            progress: tokenTracker.dailyUsagePercent
                        )
                        usageMetricCard(
                            title: NSLocalizedString("settings.usage.week", comment: ""),
                            value: tokenTracker.formatTokens(tokenTracker.weekTokens),
                            secondary: "$" + String(format: "%.2f", tokenTracker.weekCost),
                            tint: Theme.cyan,
                            progress: tokenTracker.weeklyUsagePercent
                        )
                    }

                    HStack(spacing: 12) {
                        tokenLimitField(title: NSLocalizedString("settings.token.daily.limit", comment: ""), value: $tokenTracker.dailyTokenLimit)
                        tokenLimitField(title: NSLocalizedString("settings.token.weekly.limit", comment: ""), value: $tokenTracker.weeklyTokenLimit)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        if let protectionReason {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: Theme.iconSize(11), weight: .bold))
                                    .foregroundColor(Theme.orange)
                                Text(protectionReason)
                                    .font(Theme.mono(8))
                                    .foregroundColor(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: Theme.iconSize(11), weight: .bold))
                                    .foregroundColor(Theme.green)
                                Text(NSLocalizedString("settings.token.ok.desc", comment: ""))
                                    .font(Theme.mono(8))
                                    .foregroundColor(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        HStack(spacing: 10) {
                            Button(action: {
                                tokenTracker.applyRecommendedMinimumLimits()
                            }) {
                                Text(NSLocalizedString("settings.token.apply.min", comment: ""))
                                    .font(Theme.mono(9, weight: .bold))
                                    .foregroundColor(Theme.cyan)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.cyan.opacity(0.1)))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.cyan.opacity(0.25), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                showTokenResetConfirm = true
                            }) {
                                Text(NSLocalizedString("settings.token.reset", comment: ""))
                                    .font(Theme.mono(9, weight: .bold))
                                    .foregroundColor(Theme.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.orange.opacity(0.1)))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.orange.opacity(0.25), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.bgSurface.opacity(0.85))
                    )
                }
            }

            settingsSection(title: NSLocalizedString("settings.automation", comment: ""), subtitle: NSLocalizedString("settings.automation.subtitle", comment: "")) {
                VStack(spacing: 10) {
                    settingsToggleRow(
                        title: NSLocalizedString("settings.automation.parallel", comment: ""),
                        subtitle: settings.allowParallelSubagents ? NSLocalizedString("settings.automation.allowed", comment: "") : NSLocalizedString("settings.automation.blocked", comment: ""),
                        isOn: Binding(
                            get: { settings.allowParallelSubagents },
                            set: { settings.allowParallelSubagents = $0 }
                        ),
                        tint: Theme.purple
                    )

                    settingsToggleRow(
                        title: NSLocalizedString("settings.automation.terminal.light", comment: ""),
                        subtitle: settings.terminalSidebarLightweight ? NSLocalizedString("settings.enabled", comment: "") : NSLocalizedString("settings.disabled", comment: ""),
                        isOn: Binding(
                            get: { settings.terminalSidebarLightweight },
                            set: { settings.terminalSidebarLightweight = $0 }
                        ),
                        tint: Theme.cyan
                    )

                    HStack(spacing: 10) {
                        limitStepperCard(
                            title: NSLocalizedString("settings.automation.review.max", comment: ""),
                            subtitle: NSLocalizedString("settings.automation.review.sub", comment: ""),
                            value: Binding(
                                get: { settings.reviewerMaxPasses },
                                set: { settings.reviewerMaxPasses = min(3, max(0, $0)) }
                            ),
                            range: 0...3,
                            tint: Theme.yellow
                        )
                        limitStepperCard(
                            title: "QA 최대",
                            subtitle: NSLocalizedString("settings.automation.qa.sub", comment: ""),
                            value: Binding(
                                get: { settings.qaMaxPasses },
                                set: { settings.qaMaxPasses = min(3, max(0, $0)) }
                            ),
                            range: 0...3,
                            tint: Theme.green
                        )
                    }

                    limitStepperCard(
                        title: NSLocalizedString("settings.automation.revision.max", comment: ""),
                        subtitle: NSLocalizedString("settings.automation.revision.sub", comment: ""),
                        value: Binding(
                            get: { settings.automationRevisionLimit },
                            set: { settings.automationRevisionLimit = min(5, max(1, $0)) }
                        ),
                        range: 1...5,
                        tint: Theme.accent
                    )

                    HStack(spacing: 8) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: Theme.iconSize(11), weight: .bold))
                            .foregroundColor(Theme.orange)
                        Text(NSLocalizedString("settings.automation.worker.limit", comment: ""))
                            .font(Theme.mono(8))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.orange.opacity(0.08))
                    )
                }
            }
        }
    }

}

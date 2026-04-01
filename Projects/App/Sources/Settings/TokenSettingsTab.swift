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

                    if settings.tokenProtectionEnabled {
                        HStack(spacing: 12) {
                            tokenLimitField(title: NSLocalizedString("settings.token.daily.limit", comment: ""), value: $tokenTracker.dailyTokenLimit)
                            tokenLimitField(title: NSLocalizedString("settings.token.weekly.limit", comment: ""), value: $tokenTracker.weeklyTokenLimit)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        if !settings.tokenProtectionEnabled {
                            HStack(spacing: 8) {
                                Image(systemName: "shield.slash")
                                    .font(.system(size: Theme.iconSize(11), weight: .bold))
                                    .foregroundColor(Theme.textDim)
                                Text("토큰 보호 비활성 — 일간/주간 한도 없이 무제한 사용")
                                    .font(Theme.mono(8))
                                    .foregroundColor(Theme.textDim)
                            }
                        } else if let protectionReason {
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
                            if settings.tokenProtectionEnabled {
                                Button(action: {
                                    tokenTracker.applyRecommendedMinimumLimits()
                                }) {
                                    Text(NSLocalizedString("settings.token.apply.min", comment: ""))
                                        .font(Theme.mono(9, weight: .bold))
                                        .foregroundColor(Theme.cyan)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.cyan.opacity(0.1)))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cyan.opacity(0.25), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }

                            Button(action: { showTokenResetConfirm = true }) {
                                Text(NSLocalizedString("settings.token.reset", comment: ""))
                                    .font(Theme.mono(9, weight: .bold))
                                    .foregroundColor(Theme.orange)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.orange.opacity(0.1)))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.orange.opacity(0.25), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgSurface.opacity(0.85)))
                }
            }

            settingsSection(title: "토큰 보호", subtitle: "전역 보호 · Provider별 세션 한도 · 토큰 계산기") {
                VStack(spacing: 10) {
                    settingsToggleRow(
                        title: "토큰 보호 활성화",
                        subtitle: settings.tokenProtectionEnabled ? "일간/주간 한도 초과 시 자동 차단" : "보호 꺼짐 — 일간/주간 한도 무시",
                        isOn: Binding(
                            get: { settings.tokenProtectionEnabled },
                            set: { settings.tokenProtectionEnabled = $0 }
                        ),
                        tint: settings.tokenProtectionEnabled ? Theme.green : Theme.textDim
                    )

                    if settings.tokenProtectionEnabled {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Provider별 세션 토큰 한도 (0 = 무제한)")
                                .font(Theme.mono(8))
                                .foregroundColor(Theme.textDim)

                            HStack(spacing: 8) {
                                providerTokenLimitField("🔵 Claude", value: Binding(
                                    get: { settings.claudeSessionTokenLimit },
                                    set: { settings.claudeSessionTokenLimit = $0 }
                                ))
                                providerTokenLimitField("◉ Codex", value: Binding(
                                    get: { settings.codexSessionTokenLimit },
                                    set: { settings.codexSessionTokenLimit = $0 }
                                ))
                                providerTokenLimitField("💎 Gemini", value: Binding(
                                    get: { settings.geminiSessionTokenLimit },
                                    set: { settings.geminiSessionTokenLimit = $0 }
                                ))
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgSurface.opacity(0.85)))

                        // ── 토큰 계산기 ──
                        tokenCalculatorSection
                    }
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

    // MARK: - Token Calculator (Provider별)

    private var tokenCalculatorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "function")
                    .font(.system(size: Theme.iconSize(10), weight: .bold))
                    .foregroundColor(Theme.purple)
                Text("토큰 계산기")
                    .font(Theme.mono(10, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("에이전트별 플랜을 선택하세요")
                    .font(Theme.mono(7))
                    .foregroundColor(Theme.textDim)
            }

            // 전체 주간 합산 요약
            let totalWeekly = settings.claudeWeeklyLimit + settings.codexWeeklyLimit + settings.geminiWeeklyLimit
            let totalDaily = totalWeekly / 7
            if totalWeekly > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "sum").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.accent)
                    Text("합산: 주 \(tokenTracker.formatTokens(totalWeekly)) · 일 \(tokenTracker.formatTokens(totalDaily))")
                        .font(Theme.mono(9, weight: .bold)).foregroundColor(Theme.accent)
                    Spacer()
                    Button("합산 한도 적용") {
                        tokenTracker.weeklyTokenLimit = totalWeekly
                        tokenTracker.dailyTokenLimit = totalDaily
                    }
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.accent))
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.accent.opacity(0.08)))
            }

            // Claude
            providerPlanSection(
                icon: "🔵", provider: "Claude", color: Theme.accent,
                plans: [
                    ("Pro", 25_000_000),
                    ("Max 5x", 125_000_000),
                    ("Max 20x", 500_000_000),
                    ("Team", 50_000_000),
                    ("Enterprise", 100_000_000),
                ],
                selectedPlan: settings.claudePlanName,
                weeklyLimit: settings.claudeWeeklyLimit,
                onSelect: { name, weekly in
                    settings.claudePlanName = name
                    settings.claudeWeeklyLimit = weekly
                    settings.claudeSessionTokenLimit = weekly / 7
                },
                onClear: {
                    settings.claudePlanName = ""
                    settings.claudeWeeklyLimit = 0
                    settings.claudeSessionTokenLimit = 0
                }
            )

            // Codex
            providerPlanSection(
                icon: "◉", provider: "Codex", color: Theme.green,
                plans: [
                    ("Pro", 30_000_000),
                    ("Team", 60_000_000),
                ],
                selectedPlan: settings.codexPlanName,
                weeklyLimit: settings.codexWeeklyLimit,
                onSelect: { name, weekly in
                    settings.codexPlanName = name
                    settings.codexWeeklyLimit = weekly
                    settings.codexSessionTokenLimit = weekly / 7
                },
                onClear: {
                    settings.codexPlanName = ""
                    settings.codexWeeklyLimit = 0
                    settings.codexSessionTokenLimit = 0
                }
            )

            // Gemini
            providerPlanSection(
                icon: "💎", provider: "Gemini", color: Theme.cyan,
                plans: [
                    ("Advanced", 40_000_000),
                    ("Business", 80_000_000),
                ],
                selectedPlan: settings.geminiPlanName,
                weeklyLimit: settings.geminiWeeklyLimit,
                onSelect: { name, weekly in
                    settings.geminiPlanName = name
                    settings.geminiWeeklyLimit = weekly
                    settings.geminiSessionTokenLimit = weekly / 7
                },
                onClear: {
                    settings.geminiPlanName = ""
                    settings.geminiWeeklyLimit = 0
                    settings.geminiSessionTokenLimit = 0
                }
            )
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.bgSurface.opacity(0.85)))
    }

    private func providerPlanSection(
        icon: String, provider: String, color: Color,
        plans: [(name: String, weekly: Int)],
        selectedPlan: String, weeklyLimit: Int,
        onSelect: @escaping (String, Int) -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(icon).font(.system(size: 10))
                Text(provider).font(Theme.mono(9, weight: .bold)).foregroundColor(color)
                if !selectedPlan.isEmpty {
                    Text(selectedPlan).font(Theme.mono(8)).foregroundColor(Theme.textDim)
                    Text("· 주 \(tokenTracker.formatTokens(weeklyLimit))")
                        .font(Theme.mono(7, weight: .semibold)).foregroundColor(color)
                    Spacer()
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.textDim)
                    }.buttonStyle(.plain)
                } else {
                    Text("미설정").font(Theme.mono(8)).foregroundColor(Theme.textMuted)
                    Spacer()
                }
            }

            HStack(spacing: 4) {
                ForEach(plans, id: \.name) { plan in
                    let isActive = selectedPlan == plan.name
                    Button(action: { onSelect(plan.name, plan.weekly) }) {
                        VStack(spacing: 2) {
                            Text(plan.name)
                                .font(Theme.mono(7, weight: .bold))
                                .foregroundColor(isActive ? .white : Theme.textPrimary)
                            Text("주 \(tokenTracker.formatTokens(plan.weekly))")
                                .font(Theme.mono(6))
                                .foregroundColor(isActive ? .white.opacity(0.8) : Theme.textDim)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(isActive ? color : Theme.bgSurface))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(isActive ? color : Theme.border.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

}

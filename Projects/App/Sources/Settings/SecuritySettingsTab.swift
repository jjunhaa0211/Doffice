import SwiftUI
import DesignSystem
import DofficeKit

extension SettingsView {
    // MARK: - 보안 탭

    var securityTab: some View {
        VStack(spacing: 14) {
            // 세션 잠금 + 결제일
            settingsSection(title: NSLocalizedString("settings.security.session", comment: ""), subtitle: settings.lockPIN.isEmpty ? NSLocalizedString("settings.security.lock.off", comment: "") : NSLocalizedString("settings.security.lock.on", comment: "")) {
                VStack(spacing: 10) {
                    securityRow(label: NSLocalizedString("settings.security.pin", comment: "")) {
                        SecureField(NSLocalizedString("settings.security.pin.placeholder", comment: ""), text: $settings.lockPIN)
                            .font(Theme.monoSmall).textFieldStyle(.plain)
                            .frame(width: 100).padding(6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 0.5))
                    }
                    securityRow(label: NSLocalizedString("settings.security.autolock", comment: "")) {
                        Picker("", selection: $settings.autoLockMinutes) {
                            Text(NSLocalizedString("settings.none", comment: "")).tag(0)
                            Text(NSLocalizedString("settings.1min", comment: "")).tag(1); Text(NSLocalizedString("settings.3min", comment: "")).tag(3)
                            Text(NSLocalizedString("settings.5min", comment: "")).tag(5); Text(NSLocalizedString("settings.10min", comment: "")).tag(10)
                        }.frame(width: 120)
                    }
                    securityRow(label: NSLocalizedString("settings.security.billing", comment: "")) {
                        Picker("", selection: $settings.billingDay) {
                            Text(NSLocalizedString("settings.notset", comment: "")).tag(0)
                            ForEach(1...31, id: \.self) { day in Text(String(format: NSLocalizedString("settings.day.format", comment: ""), day)).tag(day) }
                        }.frame(width: 100)
                    }
                }
            }

            // 비용 제한
            settingsSection(title: NSLocalizedString("settings.security.cost", comment: ""), subtitle: settings.dailyCostLimit > 0 ? "$\(String(format: "%.0f", settings.dailyCostLimit))/" + NSLocalizedString("settings.day", comment: "") : NSLocalizedString("settings.unlimited", comment: "")) {
                VStack(spacing: 10) {
                    securityRow(label: NSLocalizedString("settings.security.cost.daily", comment: "")) {
                        TextField("0", value: $settings.dailyCostLimit, format: .number)
                            .font(Theme.monoSmall).textFieldStyle(.plain)
                            .frame(width: 80).padding(6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 0.5))
                    }
                    securityRow(label: NSLocalizedString("settings.security.cost.session", comment: "")) {
                        TextField("0", value: $settings.perSessionCostLimit, format: .number)
                            .font(Theme.monoSmall).textFieldStyle(.plain)
                            .frame(width: 80).padding(6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.bgSurface))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 0.5))
                    }
                    Toggle(NSLocalizedString("settings.security.cost.warn80", comment: ""), isOn: $settings.costWarningAt80)
                        .font(Theme.mono(10, weight: .medium))
                        .tint(Theme.accent)
                }
            }

            // 보호 기능 통합
            settingsSection(title: NSLocalizedString("settings.security.protection", comment: ""), subtitle: NSLocalizedString("settings.security.protection.subtitle", comment: "")) {
                VStack(spacing: 10) {
                    Toggle(NSLocalizedString("settings.security.danger.detect", comment: ""), isOn: Binding(
                        get: { DangerousCommandDetector.shared.enabled },
                        set: { DangerousCommandDetector.shared.enabled = $0 }
                    )).font(Theme.mono(10, weight: .medium)).tint(Theme.accent)

                    Toggle(NSLocalizedString("settings.security.sensitive.file", comment: ""), isOn: Binding(
                        get: { SensitiveFileShield.shared.enabled },
                        set: { SensitiveFileShield.shared.enabled = $0 }
                    )).font(Theme.mono(10, weight: .medium)).tint(Theme.accent)

                    Toggle(NSLocalizedString("settings.security.audit.log", comment: ""), isOn: Binding(
                        get: { AuditLog.shared.enabled },
                        set: { AuditLog.shared.enabled = $0 }
                    )).font(Theme.mono(10, weight: .medium)).tint(Theme.accent)

                    HStack(spacing: 8) {
                        Button(action: {
                            if let data = AuditLog.shared.exportJSON() {
                                let panel = NSSavePanel()
                                panel.nameFieldStringValue = "doffice_audit_log.json"
                                panel.allowedContentTypes = [.json]
                                if panel.runModal() == .OK, let url = panel.url {
                                    try? data.write(to: url)
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.doc").font(.system(size: 10))
                                Text(NSLocalizedString("settings.security.log.export", comment: "")).font(Theme.mono(9, weight: .medium))
                            }
                            .foregroundStyle(Theme.accentBackground)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.accent.opacity(0.08)))
                        }.buttonStyle(.plain)

                        Button(action: { AuditLog.shared.clear() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash").font(.system(size: 10))
                                Text(NSLocalizedString("settings.security.log.delete", comment: "")).font(Theme.mono(9, weight: .medium))
                            }
                            .foregroundColor(Theme.red)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.red.opacity(0.08)))
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

}

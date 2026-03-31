import SwiftUI
import DesignSystem
import DofficeKit

extension SettingsView {
    // MARK: - 데이터 탭

    var dataTab: some View {
        VStack(spacing: 14) {
            settingsSection(title: NSLocalizedString("settings.data.storage", comment: ""), subtitle: cacheSize) {
                VStack(alignment: .leading, spacing: 12) {
                    dataRow(icon: "doc.text.fill", title: NSLocalizedString("settings.data.sessions", comment: ""), detail: String(format: NSLocalizedString("settings.data.count", comment: ""), SessionStore.shared.sessionCount), tint: Theme.accent)
                    dataRow(icon: "bolt.fill", title: NSLocalizedString("settings.data.tokens", comment: ""), detail: tokenTracker.formatTokens(tokenTracker.weekTokens), tint: Theme.yellow)
                    dataRow(icon: "building.2.fill", title: NSLocalizedString("settings.data.office.layout", comment: ""), detail: "UserDefaults", tint: Theme.cyan)
                    dataRow(icon: "trophy.fill", title: NSLocalizedString("settings.data.achievements", comment: ""), detail: "UserDefaults", tint: Theme.purple)
                    dataRow(icon: "person.2.fill", title: NSLocalizedString("settings.data.characters", comment: ""), detail: "UserDefaults", tint: Theme.green)
                }
            }

            settingsSection(title: NSLocalizedString("settings.data.cache", comment: ""), subtitle: NSLocalizedString("settings.data.cache.subtitle", comment: "")) {
                VStack(spacing: 10) {
                    Button(action: {
                        clearAllMode = false
                        showClearConfirm = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "wind").font(.system(size: Theme.iconSize(11), weight: .bold))
                            Text(NSLocalizedString("settings.data.cache.old", comment: "")).font(Theme.mono(11, weight: .semibold))
                            Spacer()
                            Text(NSLocalizedString("settings.data.cache.old.desc", comment: ""))
                                .font(Theme.mono(8)).foregroundColor(Theme.textDim)
                        }
                        .foregroundColor(Theme.orange)
                        .appButtonSurface(tone: .orange)
                    }.buttonStyle(.plain)

                    Button(action: {
                        clearAllMode = true
                        showClearConfirm = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill").font(.system(size: Theme.iconSize(11), weight: .bold))
                            Text(NSLocalizedString("settings.data.delete.all", comment: "")).font(Theme.mono(11, weight: .semibold))
                            Spacer()
                            Text(NSLocalizedString("settings.data.delete.all.desc", comment: ""))
                                .font(Theme.mono(8)).foregroundColor(Theme.textDim)
                        }
                        .foregroundColor(Theme.red)
                        .appButtonSurface(tone: .red)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Data Helpers

    func dataRow(icon: String, title: String, detail: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: Theme.iconSize(10), weight: .bold)).foregroundColor(tint)
                .frame(width: 20)
            Text(title).font(Theme.mono(10, weight: .medium)).foregroundColor(Theme.textPrimary)
            Spacer()
            Text(detail).font(Theme.mono(9)).foregroundColor(Theme.textSecondary)
        }
    }

    func calculateCacheSize() {
        var totalBytes: Int64 = 0
        // Application Support 디렉토리
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dofficeDir = appSupport.appendingPathComponent("Doffice")
            if let enumerator = FileManager.default.enumerator(at: dofficeDir, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let url as URL in enumerator {
                    if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalBytes += Int64(size)
                    }
                }
            }
        }
        // UserDefaults 추정 (대략적)
        let udKeys = ["DofficeTokenHistory", "DofficeCharacters", "DofficeCharacterManualUnlocks", "DofficeAchievements"]
        for key in udKeys {
            if let data = UserDefaults.standard.data(forKey: key) {
                totalBytes += Int64(data.count)
            } else if let dict = UserDefaults.standard.dictionary(forKey: key),
                      let data = try? JSONSerialization.data(withJSONObject: dict) {
                totalBytes += Int64(data.count)
            }
        }
        if totalBytes < 1024 {
            cacheSize = "\(totalBytes) B"
        } else if totalBytes < 1024 * 1024 {
            cacheSize = String(format: "%.1f KB", Double(totalBytes) / 1024.0)
        } else {
            cacheSize = String(format: "%.1f MB", Double(totalBytes) / (1024.0 * 1024.0))
        }
    }

    func clearOldCache() {
        // 완료된 세션 기록만 삭제 (빈 리스트로 저장)
        SessionStore.shared.save(tabs: [])
        // 토큰 이력 중 오래된 것은 TokenTracker가 자동 관리하므로 수동 리셋
        TokenTracker.shared.clearOldEntries()
        calculateCacheSize()
    }

    func clearAllData() {
        // 세션 기록 삭제
        SessionStore.shared.save(tabs: [])
        // 토큰 데이터 삭제
        TokenTracker.shared.clearAllEntries()
        // 업적 데이터 삭제
        UserDefaults.standard.removeObject(forKey: "DofficeAchievements")
        // 캐릭터 데이터 삭제
        UserDefaults.standard.removeObject(forKey: "DofficeCharacters")
        CharacterRegistry.shared.clearManualUnlocks()
        UserDefaults.standard.removeObject(forKey: "DofficeCharacterManualUnlocks")
        // 오피스 레이아웃 삭제
        for preset in OfficePreset.allCases {
            UserDefaults.standard.removeObject(forKey: "doffice.office.layout.\(preset.rawValue).v1")
        }
        // 가구 위치 초기화
        settings.resetFurniturePositions()
        calculateCacheSize()
    }
}

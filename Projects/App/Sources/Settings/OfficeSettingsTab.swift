import SwiftUI
import DesignSystem
import DofficeKit

extension SettingsView {
    // MARK: - 오피스 탭

    var officeTab: some View {
        VStack(spacing: 14) {
            settingsSection(title: NSLocalizedString("settings.layout", comment: ""), subtitle: currentOfficePreset.displayName) {
                VStack(spacing: 8) {
                    ForEach(OfficePreset.allCases) { preset in
                        officePresetButton(preset)
                    }
                }
            }

            settingsSection(title: NSLocalizedString("settings.camera", comment: ""), subtitle: settings.officeViewMode == "side" ? NSLocalizedString("settings.camera.focus", comment: "") : NSLocalizedString("settings.camera.full", comment: "")) {
                HStack(spacing: 8) {
                    officeCameraButton(title: NSLocalizedString("settings.camera.full", comment: ""), icon: "rectangle.expand.vertical", mode: "grid")
                    officeCameraButton(title: NSLocalizedString("settings.camera.focus", comment: ""), icon: "scope", mode: "side")
                }
            }

            settingsSection(title: NSLocalizedString("settings.character.speed", comment: ""), subtitle: characterSpeedLabel) {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "tortoise.fill")
                            .font(.system(size: Theme.iconSize(10)))
                            .foregroundColor(Theme.textDim)
                        Slider(value: $settings.characterSpeedMultiplier, in: 0.3...3.0, step: 0.1)
                            .tint(Theme.accent)
                        Image(systemName: "hare.fill")
                            .font(.system(size: Theme.iconSize(10)))
                            .foregroundColor(Theme.textDim)
                    }
                    Text(characterSpeedLabel)
                        .font(Theme.mono(9))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private var characterSpeedLabel: String {
        let v = settings.characterSpeedMultiplier
        if v <= 0.5 { return NSLocalizedString("settings.character.speed.very.slow", comment: "") }
        if v <= 0.8 { return NSLocalizedString("settings.character.speed.slow", comment: "") }
        if v <= 1.2 { return NSLocalizedString("settings.character.speed.normal", comment: "") }
        if v <= 2.0 { return NSLocalizedString("settings.character.speed.fast", comment: "") }
        return NSLocalizedString("settings.character.speed.very.fast", comment: "")
    }

}

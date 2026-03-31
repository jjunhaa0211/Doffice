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
        }
    }

}

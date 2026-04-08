import SwiftUI
import AppKit
import DesignSystem
import DofficeKit

extension SidebarView {
    func batchRestart() { vm.batchRestart(manager: manager) }
    func batchStop() { vm.batchStop(manager: manager) }
    func batchClose() { vm.batchClose(manager: manager) }

    var managementButtons: some View {
        VStack(spacing: 6) {
            utilityButton(title: NSLocalizedString("sidebar.characters", comment: ""), icon: "person.2.fill", countText: "\(CharacterRegistry.shared.hiredCharacters.count)/\(CharacterRegistry.shared.allCharacters.count)", tone: .accent) { showCharacterSheet = true }
            utilityButton(title: NSLocalizedString("sidebar.accessories", comment: ""), icon: "sofa.fill", countText: "\(breakRoomFurnitureOnCount)/20", tone: .purple) { showAccessorySheet = true }
            utilityButton(title: NSLocalizedString("sidebar.reports", comment: ""), icon: "doc.text.fill", countText: "\(manager.availableReportCount)", tone: .cyan) { showReportSheet = true }
            utilityButton(title: NSLocalizedString("sidebar.achievements", comment: ""), icon: "trophy.fill", countText: "\(AchievementManager.shared.unlockedCount)/\(AchievementManager.shared.achievements.count)", tone: .yellow) { showAchievementSheet = true }
        }
        .padding(.horizontal, 10).padding(.bottom, 6)
        .sheet(isPresented: $vm.showCharacterSheet) {
            CharacterCollectionView()
                .frame(minWidth: AppConstants.Sheet.characterMinSize.width, idealWidth: AppConstants.Sheet.characterIdealSize.width, minHeight: AppConstants.Sheet.characterMinSize.height, idealHeight: AppConstants.Sheet.characterIdealSize.height)
                .dofficeSheetPresentation()
        }
        .sheet(isPresented: $vm.showAccessorySheet) { AccessoryView().frame(minWidth: AppConstants.Sheet.accessoryMinSize.width, minHeight: AppConstants.Sheet.accessoryMinSize.height).dofficeSheetPresentation() }
        .sheet(isPresented: $vm.showReportSheet) { ReportCenterView().frame(minWidth: AppConstants.Sheet.reportMinSize.width, minHeight: AppConstants.Sheet.reportMinSize.height).dofficeSheetPresentation() }
        .sheet(isPresented: $vm.showAchievementSheet) { AchievementCollectionView().frame(minWidth: AppConstants.Sheet.achievementMinSize.width, idealWidth: AppConstants.Sheet.achievementIdealSize.width, minHeight: AppConstants.Sheet.achievementMinSize.height, idealHeight: AppConstants.Sheet.achievementIdealSize.height).dofficeSheetPresentation() }
    }

    var lightweightManagementButtons: some View {
        VStack(spacing: 6) {
            lightweightButton(title: NSLocalizedString("sidebar.characters", comment: ""), icon: "person.2.fill") { showCharacterSheet = true }
            lightweightButton(title: NSLocalizedString("sidebar.accessories", comment: ""), icon: "sofa.fill") { showAccessorySheet = true }
            lightweightButton(title: NSLocalizedString("sidebar.reports", comment: ""), icon: "doc.text.fill") { showReportSheet = true }
            lightweightButton(title: NSLocalizedString("sidebar.achievements", comment: ""), icon: "trophy.fill") { showAchievementSheet = true }
        }
        .padding(.horizontal, 10).padding(.bottom, 6)
        .sheet(isPresented: $vm.showCharacterSheet) {
            CharacterCollectionView()
                .frame(minWidth: AppConstants.Sheet.characterMinSize.width, idealWidth: AppConstants.Sheet.characterIdealSize.width, minHeight: AppConstants.Sheet.characterMinSize.height, idealHeight: AppConstants.Sheet.characterIdealSize.height)
                .dofficeSheetPresentation()
        }
        .sheet(isPresented: $vm.showAccessorySheet) { AccessoryView().frame(minWidth: AppConstants.Sheet.accessoryMinSize.width, minHeight: AppConstants.Sheet.accessoryMinSize.height).dofficeSheetPresentation() }
        .sheet(isPresented: $vm.showReportSheet) { ReportCenterView().frame(minWidth: AppConstants.Sheet.reportMinSize.width, minHeight: AppConstants.Sheet.reportMinSize.height).dofficeSheetPresentation() }
        .sheet(isPresented: $vm.showAchievementSheet) { AchievementCollectionView().frame(minWidth: AppConstants.Sheet.achievementMinSize.width, idealWidth: AppConstants.Sheet.achievementIdealSize.width, minHeight: AppConstants.Sheet.achievementMinSize.height, idealHeight: AppConstants.Sheet.achievementIdealSize.height).dofficeSheetPresentation() }
    }

    func lightweightButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: Theme.chromeIconSize(12), weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                Text(title).font(Theme.chrome(11, weight: .medium))
                Spacer()
                Text(NSLocalizedString("action.open", comment: ""))
                    .font(Theme.chrome(8, weight: .bold))
                    .foregroundColor(Theme.textDim)
            }
            .foregroundColor(Theme.textSecondary)
            .padding(.vertical, 9).padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgSurface.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }
}

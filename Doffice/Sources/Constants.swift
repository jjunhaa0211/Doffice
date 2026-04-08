import SwiftUI

// MARK: - App-wide Constants

/// 앱 전체에서 사용되는 하드코딩 값을 중앙 관리합니다.
/// 매직넘버 대신 이 상수를 참조하세요.
enum AppConstants {

    // MARK: - Layout

    enum Layout {
        static let minimumSidebarWidth: CGFloat = 196
        static let preferredSidebarWidth: CGFloat = 216
        static let minimumPrimaryContentWidth: CGFloat = 880
        static let compactBreakpointWidth: CGFloat = 1240
        static let compactSidebarThreshold: CGFloat = 204
        static let officeExpandedHeight: CGFloat = 380
        static let officeCollapsedHeight: CGFloat = 240
        static let stripHeight: CGFloat = 140
    }

    // MARK: - Timing

    enum Timing {
        static let sessionRestoreDelay: TimeInterval = 0.15
        static let autoDetectDelay: TimeInterval = 0.45
        static let pluginReloadDelay: TimeInterval = 0.6
        static let installCheckDelay: TimeInterval = 1.0
        static let dailyRewardDelay: TimeInterval = 1.5
        static let updateCheckDelay: TimeInterval = 2.0
        static let billingCheckDelay: TimeInterval = 3.0
        static let autoSaveInterval: TimeInterval = 15
    }

    // MARK: - Sheet Sizes

    enum Sheet {
        static let characterMinSize = CGSize(width: 940, height: 760)
        static let characterIdealSize = CGSize(width: 1040, height: 840)
        static let accessoryMinSize = CGSize(width: 480, height: 560)
        static let reportMinSize = CGSize(width: 760, height: 620)
        static let achievementMinSize = CGSize(width: 880, height: 680)
        static let achievementIdealSize = CGSize(width: 960, height: 740)
    }

    // MARK: - Token Thresholds

    enum TokenThreshold {
        static let critical: Double = 0.9
        static let warning: Double = 0.7
        static let high: Double = 0.8
    }
}

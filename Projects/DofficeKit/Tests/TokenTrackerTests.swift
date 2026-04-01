import XCTest
@testable import DofficeKit
import DesignSystem

final class TokenTrackerTests: XCTestCase {

    func testInitialState() {
        // TokenTracker.shared loads from UserDefaults; verify basic API
        let tracker = TokenTracker.shared
        XCTAssertGreaterThanOrEqual(tracker.todayTokens, 0)
        XCTAssertGreaterThanOrEqual(tracker.weekTokens, 0)
    }

    func testFormatTokensSmall() {
        let tracker = TokenTracker.shared
        XCTAssertEqual(tracker.formatTokens(500), "500")
        XCTAssertEqual(tracker.formatTokens(0), "0")
    }

    func testFormatTokensThousands() {
        let tracker = TokenTracker.shared
        XCTAssertEqual(tracker.formatTokens(1500), "1.5k")
        XCTAssertEqual(tracker.formatTokens(10000), "10.0k")
    }

    func testFormatTokensMillions() {
        let tracker = TokenTracker.shared
        XCTAssertEqual(tracker.formatTokens(1_500_000), "1.5M")
        XCTAssertEqual(tracker.formatTokens(2_000_000), "2.0M")
    }

    func testDailyLimitDefaults() {
        XCTAssertEqual(TokenTracker.recommendedDailyLimit, 500_000)
        XCTAssertEqual(TokenTracker.recommendedWeeklyLimit, 2_500_000)
    }

    func testUsagePercentComputation() {
        let tracker = TokenTracker.shared
        // Usage percent should be between 0 and some reasonable value
        XCTAssertGreaterThanOrEqual(tracker.dailyUsagePercent, 0)
        XCTAssertGreaterThanOrEqual(tracker.weeklyUsagePercent, 0)
    }

    func testLast7DaysRecordsCount() {
        let tracker = TokenTracker.shared
        let records = tracker.last7DaysRecords
        XCTAssertEqual(records.count, 7, "Should always return exactly 7 records")
    }

    func testBillingPeriodDaysNonNegative() {
        let tracker = TokenTracker.shared
        XCTAssertGreaterThanOrEqual(tracker.billingPeriodDays, 0)
    }

    func testBillingPeriodLabelNotEmpty() {
        let tracker = TokenTracker.shared
        XCTAssertFalse(tracker.billingPeriodLabel.isEmpty)
    }

    // MARK: - Token Protection Tests

    func testStartBlockReturnsNilWhenProtectionDisabled() {
        let settings = AppSettings.shared
        let originalValue = settings.tokenProtectionEnabled
        defer { settings.tokenProtectionEnabled = originalValue }

        settings.tokenProtectionEnabled = false
        let tracker = TokenTracker.shared
        // 보호 비활성 시 항상 nil 반환
        XCTAssertNil(tracker.startBlockReason(isAutomation: false))
        XCTAssertNil(tracker.startBlockReason(isAutomation: true))
    }

    func testRunningStopReturnsNilWhenProtectionDisabled() {
        let settings = AppSettings.shared
        let originalValue = settings.tokenProtectionEnabled
        defer { settings.tokenProtectionEnabled = originalValue }

        settings.tokenProtectionEnabled = false
        let tracker = TokenTracker.shared
        // 보호 비활성이어도 세션 한도(tokenLimit > 0)는 적용됨
        XCTAssertNil(tracker.runningStopReason(isAutomation: false, currentTabTokens: 999999, tokenLimit: 0))
        // 세션 한도 설정 시에는 적용
        XCTAssertNotNil(tracker.runningStopReason(isAutomation: false, currentTabTokens: 50000, tokenLimit: 40000))
    }

    func testRunningStopReturnsNilWhenTokenLimitZero() {
        let settings = AppSettings.shared
        let originalValue = settings.tokenProtectionEnabled
        defer { settings.tokenProtectionEnabled = originalValue }

        settings.tokenProtectionEnabled = true
        let tracker = TokenTracker.shared
        // tokenLimit = 0 (무제한)이면 세션 한도 체크 안 함
        let reason = tracker.runningStopReason(isAutomation: false, currentTabTokens: 999999, tokenLimit: 0)
        // 글로벌 한도에 안 걸렸다면 nil
        // (실제 일간/주간 사용량에 따라 다를 수 있으므로 글로벌 체크 통과 여부만 확인)
        if tracker.dailyUsagePercent < 0.98 && tracker.weeklyUsagePercent < 0.98 {
            XCTAssertNil(reason, "tokenLimit=0 should not trigger session limit block")
        }
    }

    func testRunningStopTriggersWhenTokenLimitExceeded() {
        let settings = AppSettings.shared
        let originalValue = settings.tokenProtectionEnabled
        defer { settings.tokenProtectionEnabled = originalValue }

        settings.tokenProtectionEnabled = true
        let tracker = TokenTracker.shared
        // 세션 한도 50000, 사용량 60000 → 차단
        let reason = tracker.runningStopReason(isAutomation: false, currentTabTokens: 60000, tokenLimit: 50000)
        XCTAssertNotNil(reason, "Should block when currentTabTokens exceeds tokenLimit")
    }

    func testStartBlockReturnsNilWithHighLimits() {
        let settings = AppSettings.shared
        let originalProtection = settings.tokenProtectionEnabled
        let tracker = TokenTracker.shared
        let originalDaily = tracker.dailyTokenLimit
        let originalWeekly = tracker.weeklyTokenLimit
        defer {
            settings.tokenProtectionEnabled = originalProtection
            tracker.dailyTokenLimit = originalDaily
            tracker.weeklyTokenLimit = originalWeekly
        }

        settings.tokenProtectionEnabled = true
        // 매우 높은 한도 설정 → 차단 안 됨
        tracker.dailyTokenLimit = 100_000_000
        tracker.weeklyTokenLimit = 500_000_000
        XCTAssertNil(tracker.startBlockReason(isAutomation: false), "Should not block with very high limits")
    }
}

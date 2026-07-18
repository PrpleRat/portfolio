import UserNotifications
import XCTest
@testable import RAS

final class NotificationSchedulerTests: XCTestCase {

    func testNotificationPrefixesAreDistinct() {
        XCTAssertFalse(AppConstants.checkInNotifPrefix == AppConstants.warningNotifPrefix)
        XCTAssertFalse(AppConstants.warningNotifPrefix == AppConstants.alertNotifPrefix)
    }

    func testMaxScheduledNotificationsRespectsIOSLimit() {
        XCTAssertLessThanOrEqual(AppConstants.maxScheduledNotifications, 64)
        XCTAssertGreaterThan(AppConstants.maxScheduledNotifications, 0)
    }

    func testGraceAndWarningArePositive() {
        XCTAssertGreaterThan(AppConstants.warningWindowMinutes, 0)
        XCTAssertGreaterThan(AppConstants.gracePeriodMinutes, 0)
    }

    func testRegisterCategoriesDoesNotCrash() {
        NotificationScheduler.shared.registerNotificationCategories()
        let expectation = expectation(description: "categories registered")
        UNUserNotificationCenter.current().getNotificationCategories { categories in
            XCTAssertTrue(categories.contains { $0.identifier == "CHECKIN_ACTION" })
            XCTAssertTrue(categories.contains { $0.identifier == "ALERT_ACTION" })
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }
}

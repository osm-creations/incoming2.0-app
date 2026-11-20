import CoreFoundation
import XCTest

final class PerformanceUITests: XCTestCase {
    private let app = XCUIApplication()
    private var note: XCUIElement { app.textViews.firstMatch }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launch(_ profile: String) {
        app.launchEnvironment["FIXTURE_PROFILE"] = profile
        app.launch()
        XCTAssertTrue(note.waitForExistence(timeout: 22), app.debugDescription)
        XCTAssertEqual(note.value as? String, "Rose")
    }

    private func arm() {
        note.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        XCTAssertTrue(note.waitForNonExistence(timeout: 6), app.debugDescription)
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertFalse(app.alerts["Volume trigger unavailable"].exists, app.debugDescription)
    }

    private func volume(_ level: String) {
        let name = CFNotificationName(rawValue: "com.osmcreations.qa.volume18.\(level)" as CFString)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), name, nil, nil, true)
    }

    func testPlainZeroNeedsActualChangeAndRearms() {
        launch("plain-0")
        volume("high")
        Thread.sleep(forTimeInterval: 0.4)
        XCTAssertTrue(note.exists)
        arm()
        let caller = app.buttons["Jamie Rose"]
        app.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        volume("high")
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertFalse(caller.exists, "A repeated level or a second triple-tap should leave the screen black")
        volume("low")
        XCTAssertTrue(caller.waitForExistence(timeout: 3), app.debugDescription)
        caller.tap()
        XCTAssertTrue(note.waitForExistence(timeout: 8))
        arm()
        XCTAssertFalse(caller.exists)
        volume("high")
        XCTAssertTrue(caller.waitForExistence(timeout: 3))
        print("VOLUME-QA plain zero, duplicate suppression, old gesture removed and second cycle passed")
    }

    func testLegacyDefaultCancelsOnBackgroundAndRearms() {
        launch("standard-default")
        arm()
        let caller = app.staticTexts["Jamie Rose"]
        volume("high")
        Thread.sleep(forTimeInterval: 0.5)
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 6)
        app.activate()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertFalse(caller.exists, "A backgrounded countdown must be cancelled")
        volume("low")
        let start = Date()
        Thread.sleep(forTimeInterval: 3)
        XCTAssertFalse(caller.exists, "A missing delay should default to five seconds")
        XCTAssertTrue(caller.waitForExistence(timeout: 6), app.debugDescription)
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 4.5)
        print("VOLUME-QA missing setting defaults to five seconds; background cancels and foreground rearms")
    }

    func testStandardSixtySecondsAndRepeatedCueDoesNotReset() {
        launch("standard-60")
        arm()
        let caller = app.staticTexts["Jamie Rose"]
        volume("high")
        let start = Date()
        Thread.sleep(forTimeInterval: 54)
        XCTAssertFalse(caller.exists, "60 second reveal appeared early")
        volume("low")
        XCTAssertTrue(caller.waitForExistence(timeout: 13), app.debugDescription)
        let duration = Date().timeIntervalSince(start)
        XCTAssertGreaterThanOrEqual(duration, 59.0, "Configured one-minute delay was not applied")
        XCTAssertLessThan(duration, 69.0, "A repeat cue restarted the timer")
        print("VOLUME-QA standard 60-second delay elapsed in", duration, "seconds")
    }
}

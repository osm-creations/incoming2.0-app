import XCTest

final class PerformanceUITests: XCTestCase {
    private let app = XCUIApplication()
    private var note: XCUIElement { app.textViews.firstMatch }
    private var share: XCUIElement { app.buttons["Share"] }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(profile: String = "enabled") {
        app.launchEnvironment["FIXTURE_PROFILE"] = profile
        app.launch()
        XCTAssertTrue(note.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertEqual(note.value as? String, "Rose")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func preview(_ choice: String) {
        XCTAssertTrue(share.waitForExistence(timeout: 8))
        share.press(forDuration: 0.90)
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(alert.staticTexts["Morgan"].exists)
        capture("Selection - " + choice)
        alert.buttons[choice].tap()
    }

    private func performCall(expected: String) {
        note.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        XCTAssertTrue(note.waitForNonExistence(timeout: 5), app.debugDescription)
        // Wait for the crossfade to finish before revealing from the black screen.
        Thread.sleep(forTimeInterval: 0.4)
        app.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        XCTAssertTrue(app.staticTexts[expected].waitForExistence(timeout: 6), app.debugDescription)
        let slider = app.buttons["Answer call"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))
        capture("Incoming call - " + expected)
        let start = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.50))
        let end = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.91, dy: 0.50))
        start.press(forDuration: 0.15, thenDragTo: end)
        XCTAssertTrue(note.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertEqual(note.value as? String, "Rose")
        capture("Restored note - " + expected)
    }

    func testClosePreservesConfiguredName() {
        launch()
        capture("Editable Notes")
        preview("Close")
        performCall(expected: "Jamie")
    }

    func testUseSelectsNewName() {
        launch()
        preview("Use")
        performCall(expected: "Morgan")
    }

    func testUnconfiguredUserHasNoShareAction() {
        launch(profile: "disabled")
        XCTAssertFalse(share.exists)
        capture("Notes without Inject")
    }
}

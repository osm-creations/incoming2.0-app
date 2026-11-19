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
        XCTAssertEqual(note.value as? String ?? "", profile == "empty" ? "" : "Rose")
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
        XCTAssertTrue(alert.staticTexts["Taylor Anderson"].exists)
        capture("Selection - " + choice)
        alert.buttons[choice].tap()
    }

    private func performCall(expected: String, expectedNote: String = "Rose", checkDelay: Bool = false) {
        note.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        XCTAssertTrue(note.waitForNonExistence(timeout: 5), app.debugDescription)
        // Wait for the crossfade to finish before revealing from the black screen.
        Thread.sleep(forTimeInterval: 0.4)
        app.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        let caller = app.staticTexts[expected]
        if checkDelay {
            // Start after the original synthesized input. XCTest includes a short idle wait.
            let afterFirst = ProcessInfo.processInfo.systemUptime
            Thread.sleep(forTimeInterval: 2.2)
            XCTAssertFalse(caller.exists, "Call appeared before the five-second delay")
            let beforeRepeat = ProcessInfo.processInfo.systemUptime
            app.tap(withNumberOfTaps: 3, numberOfTouches: 1)
            let untilEarlySample = (afterFirst + 3.75) - ProcessInfo.processInfo.systemUptime
            if untilEarlySample > 0 { Thread.sleep(forTimeInterval: untilEarlySample) }
            XCTAssertFalse(caller.exists, "Call appeared before the timer was due")
            XCTAssertTrue(caller.waitForExistence(timeout: 3.5), app.debugDescription)
            let observed = ProcessInfo.processInfo.systemUptime
            print("Call observed after first input: \(observed-afterFirst)s; after repeated input: \(observed-beforeRepeat)s")
            XCTAssertLessThan(observed-beforeRepeat, 4.95, "Repeated taps restarted the five-second timer")
        } else {
            XCTAssertTrue(caller.waitForExistence(timeout: 12), app.debugDescription)
        }
        let slider = app.buttons["Answer call"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))
        capture("Incoming call - " + expected)
        let start = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.50))
        let end = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.91, dy: 0.50))
        start.press(forDuration: 0.15, thenDragTo: end)
        XCTAssertTrue(note.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertEqual(note.value as? String, expectedNote)
        capture("Restored note - " + expected)
    }

    func testTripleTapWhileEditingPreservesText() {
        launch(profile: "empty")
        note.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 8))
        note.typeText("Rehearsal")
        performCall(expected: "Jamie", expectedNote: "Rehearsal")
    }

    func testNotesReadingAndEditing() {
        launch(profile: "empty")
        XCTAssertTrue(share.waitForExistence(timeout: 5))
        capture("Empty note - reading")
        note.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 8), app.debugDescription)
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        capture("Empty note - editing with keyboard")
        note.typeText("Rehearsal")
        done.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
        XCTAssertEqual(note.value as? String, "Rehearsal")
    }

    func testPerformerInjectLabels() {
        app.launchEnvironment["FIXTURE_PROFILE"] = "performer"
        app.launch()
        let field = app.textFields["Inject User ID"]
        XCTAssertTrue(field.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertEqual(field.label, "Inject User ID")
        XCTAssertEqual(field.placeholderValue, "Inject User ID")
        XCTAssertTrue(app.staticTexts["Inject User ID"].exists)
        XCTAssertTrue(app.staticTexts["Enter your Inject User ID to enable Inject."].exists)
        capture("Performer Inject settings")
    }

    func testClosePreservesConfiguredName() {
        launch()
        capture("Editable Notes")
        preview("Close")
        performCall(expected: "Jamie")
    }

    func testUseSelectsNewName() {
        launch()
        for attempt in 0..<3 {
            preview("Use")
            performCall(expected: "Taylor Anderson", checkDelay: attempt == 0)
        }
    }

    func testUnconfiguredUserHasNoShareAction() {
        launch(profile: "disabled")
        XCTAssertFalse(share.exists)
        capture("Notes without Inject")
    }
}

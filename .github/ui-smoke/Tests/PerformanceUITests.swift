import XCTest

final class PerformanceUITests: XCTestCase {
    private let app = XCUIApplication()
    private let rawNote = "ivy lee\nsecond line"
    private var note: XCUIElement { app.textViews.firstMatch }

    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ profile: String) {
        app.launchEnvironment["FIXTURE_PROFILE"] = profile
        app.launch()
        XCTAssertTrue(note.waitForExistence(timeout: 18), app.debugDescription)
        XCTAssertEqual(note.value as? String, rawNote)
        print("CALLER-QA launched", profile, app.frame)
    }

    private func capture(_ label: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = label
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func reveal(_ name: String, capture label: String, plain: Bool = false) {
        note.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        XCTAssertTrue(note.waitForNonExistence(timeout: 6), app.debugDescription)
        Thread.sleep(forTimeInterval: 0.4)
        app.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        let caller = plain ? app.buttons[name] : app.staticTexts[name]
        XCTAssertTrue(caller.waitForExistence(timeout: 12), app.debugDescription)
        XCTAssertEqual(caller.label, name)
        // The caller becomes accessible at the beginning of the production crossfade.
        Thread.sleep(forTimeInterval: 0.65)
        capture(label)
        print("CALLER-QA", label, "displayed", caller.label)
        if plain {
            caller.tap()
        } else {
            let slider = app.buttons["Answer call"]
            XCTAssertTrue(slider.exists)
            let from = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.5))
            let to = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.91, dy: 0.5))
            from.press(forDuration: 0.15, thenDragTo: to)
        }
        XCTAssertTrue(note.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(note.value as? String, rawNote)
        print("CALLER-QA original lowercase note preserved after", label)
    }

    func testStandardStoredInjectAndNoteNames() {
        launch("standard")
        reveal("Jamie Rose", capture: "Standard Saved")
        app.buttons["notes.checklist"].press(forDuration: 0.9)
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 8), app.debugDescription)
        let preview = alert.staticTexts["Taylor Anderson"]
        XCTAssertTrue(preview.exists)
        XCTAssertEqual(preview.label, "Taylor Anderson")
        capture("Inject Preview")
        alert.buttons["Use"].tap()
        reveal("Taylor Anderson", capture: "Standard Inject")
        app.buttons["notes.compose"].tap()
        let aa = app.buttons["notes.formatting"]
        XCTAssertTrue(aa.waitForExistence(timeout: 8))
        aa.tap()
        XCTAssertEqual(aa.value as? String, "On")
        app.buttons["notes.done"].tap()
        reveal("Ivy Lee", capture: "Standard Note")
    }

    func testPlainPreservesMixedCase() {
        launch("plain")
        reveal("AJ McDonald", capture: "Plain Mixed", plain: true)
    }
}

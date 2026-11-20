import XCTest

final class PerformanceUITests: XCTestCase {
    func testCaptureAppClipNoteAndReveal() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["FIXTURE_PROFILE"] = "plain"
        app.launch()

        let note = app.textViews.firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 20), app.debugDescription)
        XCTAssertEqual(note.value as? String, "Rose")
        XCTAssertTrue(app.buttons["notes.getCallerName"].exists, app.debugDescription)
        Thread.sleep(forTimeInterval: 0.85)
        capture("04-clip-note")
        note.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        XCTAssertTrue(note.waitForNonExistence(timeout: 6), app.debugDescription)
        Thread.sleep(forTimeInterval: 0.45)
        app.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        let caller = app.buttons["Jamie Rose"]
        XCTAssertTrue(caller.waitForExistence(timeout: 14), app.debugDescription)
        Thread.sleep(forTimeInterval: 0.85)
        capture("05-clip-reveal")
        caller.tap()
        XCTAssertTrue(note.waitForExistence(timeout: 6), app.debugDescription)
        XCTAssertEqual(note.value as? String, "Rose")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

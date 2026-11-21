import CoreFoundation
import XCTest

final class PerformanceUITests: XCTestCase {
    let app = XCUIApplication()
    var note: XCUIElement { app.textViews.firstMatch }

    func capture(_ label: String) {
        Thread.sleep(forTimeInterval: 0.75)
        let item = XCTAttachment(data: XCUIScreen.main.screenshot().pngRepresentation, uniformTypeIdentifier: "public.png")
        item.name = label
        item.lifetime = .keepAlways
        add(item)
    }

    func testStandardNoteAndVolumeTriggeredSimulatedCall() {
        continueAfterFailure = false
        app.launchEnvironment["QA_CLIP_LINK"] = "compact"
        app.launch()
        XCTAssertTrue(note.waitForExistence(timeout: 25), app.debugDescription)
        XCTAssertEqual(note.value as? String, "Rose")
        XCTAssertTrue(app.buttons["notes.checklist"].exists)
        capture("08-standard-clip-note")
        note.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        XCTAssertTrue(note.waitForNonExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 1)
        XCTAssertFalse(app.alerts["Volume trigger unavailable"].exists, app.debugDescription)
        let signal = CFNotificationName(rawValue: "com.osmcreations.qa.volume18.high" as CFString)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), signal, nil, nil, true)
        let caller = app.staticTexts["Jamie Rose"]
        XCTAssertTrue(caller.waitForExistence(timeout: 14), app.debugDescription)
        capture("09-standard-call")
        let slider = app.buttons["Answer call"]
        XCTAssertTrue(slider.exists, app.debugDescription)
        let from = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.50))
        let to = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.91, dy: 0.50))
        from.press(forDuration: 0.15, thenDragTo: to)
        XCTAssertTrue(note.waitForExistence(timeout: 8))
        app.terminate()
        app.launchEnvironment["QA_CLIP_LINK"] = "legacy"
        app.launch()
        XCTAssertTrue(note.waitForExistence(timeout: 25), app.debugDescription)
        XCTAssertEqual(note.value as? String, "Rose")
    }
}

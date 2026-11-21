import CoreFoundation
import XCTest

final class PerformanceUITests: XCTestCase {
    let app = XCUIApplication()
    var note: XCUIElement { app.textViews.firstMatch }
    var caller: XCUIElement { app.staticTexts["Jamie Rose"] }

    private func open(_ scenario: String) {
        continueAfterFailure = false
        app.launchEnvironment["QA_CLIP_LINK"] = scenario
        app.launch()
        XCTAssertTrue(note.waitForExistence(timeout: 25), app.debugDescription)
        XCTAssertEqual(note.value as? String, "Rose")
    }

    private func arm() {
        note.doubleTap()
        XCTAssertTrue(note.waitForNonExistence(timeout: 6), app.debugDescription)
        Thread.sleep(forTimeInterval: 0.7)
        XCTAssertFalse(app.alerts["Volume trigger unavailable"].exists, app.debugDescription)
        XCTAssertFalse(caller.exists)
    }

    private func setVolume(_ level: String) {
        let name = CFNotificationName(rawValue: ("com.osmcreations.qa.clip21." + level) as CFString)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), name, nil, nil, true)
    }

    private func capture(_ label: String) {
        Thread.sleep(forTimeInterval: 0.65)
        let image = XCTAttachment(data: XCUIScreen.main.screenshot().pngRepresentation, uniformTypeIdentifier: "public.png")
        image.name = label
        image.lifetime = .keepAlways
        add(image)
    }

    func testPlainStartStopRestartAndReveal() {
        open("compact")
        capture("04-clip-note")
        arm()
        capture("10-black-waiting")
        setVolume("low")
        Thread.sleep(forTimeInterval: 5.5)
        XCTAssertFalse(note.exists)
        XCTAssertFalse(caller.exists, "Volume Down while idle must leave the black screen armed.")

        setVolume("high")
        Thread.sleep(forTimeInterval: 1.4)
        setVolume("mid")
        Thread.sleep(forTimeInterval: 5.5)
        XCTAssertFalse(note.exists)
        XCTAssertFalse(caller.exists, "The cancelled countdown fired.")

        setVolume("high")
        Thread.sleep(forTimeInterval: 2.4)
        setVolume("higher")
        Thread.sleep(forTimeInterval: 3.2)
        XCTAssertFalse(caller.exists, "The first countdown survived the second Volume Up.")
        XCTAssertTrue(caller.waitForExistence(timeout: 5), app.debugDescription)
        capture("05-clip-reveal")
        caller.tap()
        XCTAssertTrue(note.waitForExistence(timeout: 6))
        XCTAssertEqual(note.value as? String, "Rose")
    }

    func testStandardReturnAndSimulatedCall() {
        open("legacy")
        XCTAssertTrue(app.buttons["notes.checklist"].exists)
        capture("08-standard-clip-note")

        note.tap()
        note.typeText(" Petal")
        let edited = note.value as? String
        XCTAssertTrue(edited?.contains("Petal") ?? false, String(describing: edited))
        arm()
        app.swipeDown()
        XCTAssertFalse(note.exists, "A one-finger swipe unexpectedly returned to Notes.")
        setVolume("high")
        let swipe = expectation(description: "Two synchronized simulator touch paths delivered")
        QASwipeDownWithTwoContacts(app.frame) { success, message in
            XCTAssertTrue(success, message ?? "")
            swipe.fulfill()
        }
        wait(for: [swipe], timeout: 6)
        XCTAssertTrue(note.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(note.value as? String, edited)
        Thread.sleep(forTimeInterval: 5.3)
        XCTAssertTrue(note.exists, "The timer fired after the swipe returned to the note.")
        XCTAssertFalse(caller.exists)

        arm()
        setVolume("higher")
        XCTAssertTrue(caller.waitForExistence(timeout: 9), app.debugDescription)
        capture("09-standard-call")
        let slider = app.buttons["Answer call"]
        XCTAssertTrue(slider.exists)
        slider.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.50))
            .press(forDuration: 0.15, thenDragTo: slider.coordinate(withNormalizedOffset: CGVector(dx: 0.91, dy: 0.50)))
        XCTAssertTrue(note.waitForExistence(timeout: 8))
        XCTAssertEqual(note.value as? String, edited)
    }

    func testZeroDelayIsImmediateOnIncrease() {
        open("zero")
        arm()
        setVolume("low")
        Thread.sleep(forTimeInterval: 0.7)
        XCTAssertFalse(caller.exists)
        let start = ProcessInfo.processInfo.systemUptime
        setVolume("mid")
        XCTAssertTrue(caller.waitForExistence(timeout: 3), app.debugDescription)
        XCTAssertLessThan(ProcessInfo.processInfo.systemUptime - start, 3)
    }
}

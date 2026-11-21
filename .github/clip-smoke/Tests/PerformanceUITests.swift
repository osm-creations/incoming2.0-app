import CoreFoundation
import XCTest
import UIKit

final class PerformanceUITests: XCTestCase {
    let app = XCUIApplication()
    var note: XCUIElement { app.textViews.firstMatch }
    var caller: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Jamie Rose")).firstMatch
    }

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

    private func inspectNativeControl(_ stage: String) {
        Thread.sleep(forTimeInterval: 0.5)
        let name = CFNotificationName(rawValue: ("com.osmcreations.qa.clip24.native." + stage) as CFString)
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), name, nil, nil, true)
        Thread.sleep(forTimeInterval: 0.45)
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
        inspectNativeControl("notes")
        arm()
        inspectNativeControl("armed")
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
        inspectNativeControl("revealed")
        caller.tap()
        inspectNativeControl("returned")
        XCTAssertTrue(note.waitForExistence(timeout: 6))
        XCTAssertEqual(note.value as? String, "Rose")
    }

    func testStandardReturnAndSimulatedCall() {
        open("legacy")
        XCTAssertTrue(app.buttons["notes.checklist"].exists)
        capture("08-standard-clip-note")
        app.buttons["notes.checklist"].press(forDuration: 0.8)
        let standardLookup = app.alerts["Use this caller name?"]
        XCTAssertTrue(standardLookup.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(standardLookup.staticTexts["Morgan Finch"].exists)
        XCTAssertFalse(standardLookup.staticTexts["Taylor Anderson"].exists)
        standardLookup.buttons["Close"].tap()

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

    // Simulator volume changes arrive through the fixture. They exercise the public
    // audio observation path without asking iOS to show its hardware indicator.
    private func checkBlackScreen(_ label: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(data: screenshot.pngRepresentation, uniformTypeIdentifier: "public.png")
        attachment.name = "qa-black-" + label
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertFalse(app.descendants(matching: .any)["performance.volumeMeter"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["performance.blackScreen"].exists)
    }

    func testVolumeChangesHaveNoAppOwnedIndicator() {
        open("meter")
        arm()
        let surface = app.descendants(matching: .any)["performance.blackScreen"]
        surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        checkBlackScreen("tap")
        setVolume("high")
        Thread.sleep(forTimeInterval: 0.24)
        checkBlackScreen("up")
        inspectNativeControl("afterUp")
        setVolume("low")
        Thread.sleep(forTimeInterval: 0.24)
        checkBlackScreen("down")
        inspectNativeControl("afterDown")
        XCTAssertFalse(caller.exists)
    }

    func testPlainToolsFetchesOnlyTheSelectedAccount() {
        open("zero")
        app.buttons["Tools"].tap()
        let item = app.buttons["notes.tools.inject"]
        XCTAssertTrue(item.waitForExistence(timeout: 4), app.debugDescription)
        capture("11-simple-tools-inject")
        item.tap()
        let popup = app.alerts["Use this caller name?"]
        XCTAssertTrue(popup.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(popup.staticTexts["Taylor Anderson"].exists)
        XCTAssertFalse(popup.staticTexts["Morgan Finch"].exists)
        popup.buttons["Use"].tap()
        arm()
        setVolume("high")
        XCTAssertTrue(app.buttons["Taylor Anderson"].waitForExistence(timeout: 4))
        XCTAssertFalse(caller.exists)
        app.terminate()
        open("missing")
        app.buttons["Tools"].tap()
        app.buttons["notes.tools.inject"].tap()
        let setup = app.alerts["Set up Inject"]
        XCTAssertTrue(setup.waitForExistence(timeout: 4), app.debugDescription)
        XCTAssertFalse(app.alerts["Use this caller name?"].exists)
    }

    func testZeroDelayIsImmediateOnIncrease() {
        open("zero")
        arm()
        setVolume("mid")
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertFalse(caller.exists, "An unchanged volume must not trigger a zero-delay reveal.")
        setVolume("low")
        Thread.sleep(forTimeInterval: 0.7)
        XCTAssertFalse(caller.exists)
        let start = ProcessInfo.processInfo.systemUptime
        setVolume("mid")
        XCTAssertTrue(caller.waitForExistence(timeout: 3), app.debugDescription)
        XCTAssertLessThan(ProcessInfo.processInfo.systemUptime - start, 3)
    }
}

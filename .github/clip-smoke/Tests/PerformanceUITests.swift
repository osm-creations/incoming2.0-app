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
        let name = CFNotificationName(rawValue: ("com.osmcreations.qa.clip23.native." + stage) as CFString)
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

    // Downsample the screen to observe what is actually rendered without waiting
    // for accessibility-query quiescence while the short-lived bar is visible.
    private func hasMeter(_ shot: XCUIScreenshot) -> Bool {
        guard let cg = shot.image.cgImage else { return false }
        let width = 160, height = 348
        var samples = [UInt8](repeating: 0, count: width * height)
        return samples.withUnsafeMutableBufferPointer { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            var marked = 0
            // Left-center safe-area track. Ignore unrelated system surfaces outside this region.
            for y in (height / 2 - 25)...(height / 2 + 25) {
                for x in 2..<16 where buffer[y * width + x] > 7 {
                    marked += 1
                }
            }
            return marked > 22
        }
    }

    func testPassiveHardwareMeter() {
        open("meter")
        arm()
        let surface = app.descendants(matching: .any)["performance.blackScreen"]
        surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        XCTAssertFalse(hasMeter(XCUIScreen.main.screenshot()), "Tapping black must leave it black.")
        setVolume("mid")
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertFalse(hasMeter(XCUIScreen.main.screenshot()), "An unchanged fixture volume must not flash a meter.")
        setVolume("high")
        Thread.sleep(forTimeInterval: 0.28)
        let image = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(data: image.pngRepresentation, uniformTypeIdentifier: "public.png")
        attachment.name = "12-hardware-volume-indicator"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertTrue(hasMeter(image), "No meter appeared after Volume Up.")
        setVolume("low")
        Thread.sleep(forTimeInterval: 0.20)
        XCTAssertTrue(hasMeter(XCUIScreen.main.screenshot()), "No meter appeared after Volume Down.")

        // Repeated changes should keep the indicator visible until the last timeout.
        setVolume("mid")
        Thread.sleep(forTimeInterval: 0.75)
        setVolume("low")
        Thread.sleep(forTimeInterval: 0.68)
        XCTAssertTrue(hasMeter(XCUIScreen.main.screenshot()), "Meter hid at the first change's old deadline.")
        Thread.sleep(forTimeInterval: 1.3)
        XCTAssertFalse(hasMeter(XCUIScreen.main.screenshot()), "Meter remained beyond its fade.")
        XCTAssertTrue(surface.exists)
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

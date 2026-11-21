import XCTest

final class ShippingClipTests: XCTestCase {
    func testActualClipLaunchAndBlackScreen() {
        continueAfterFailure = false
        let clip = XCUIApplication(bundleIdentifier: "com.osmcreations.incoming2.Clip")
        let invocation = URL(string: "https://incoming2-0-server.incoming-osmcreations.workers.dev/c/AAAAAAAAAAAAAAAAAAAAAA")!
        clip.launchEnvironment["_XCAppClipURL"] = invocation.absoluteString
        clip.launch()
        XCTAssertTrue(clip.wait(for: .runningForeground, timeout: 15))
        let note = clip.textViews.firstMatch
        if !note.waitForExistence(timeout: 10) {
            clip.open(invocation)
        }
        XCTAssertTrue(note.waitForExistence(timeout: 25), clip.debugDescription)
        XCTAssertEqual(note.value as? String, "Rose")
        note.doubleTap()
        let black = clip.descendants(matching: .any).matching(identifier: "performance.blackScreen").firstMatch
        XCTAssertTrue(black.waitForExistence(timeout: 8), clip.debugDescription)
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(clip.wait(for: .runningForeground, timeout: 2))
        XCTAssertFalse(clip.alerts["Volume trigger unavailable"].exists, clip.debugDescription)
        XCTAssertTrue(black.exists)
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "actual-shipping-clip-black"
        capture.lifetime = .keepAlways
        add(capture)
    }
}

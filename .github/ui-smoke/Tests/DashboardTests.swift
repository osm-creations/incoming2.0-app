import XCTest

final class DashboardTests: XCTestCase {
    let app = XCUIApplication()
    var picker: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "settings.revealDelay").firstMatch
    }
    var save: XCUIElement { app.buttons["Set & Save"] }

    func testSavedDelayRoundTrip() {
        continueAfterFailure = false
        app.launchEnvironment["QA_RESTORE_TOKEN"] = "fixture-delay"
        app.launch()
        let settings = app.buttons["dashboard.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 30), app.debugDescription)
        settings.tap()
        openDelay()
        assertPicker(seconds: 5)
        var previous = 5
        for seconds in [0, 60, 5] {
            picker.tap()
            Thread.sleep(forTimeInterval: 0.8)
            choose(seconds, movingFrom: previous)
            XCTAssertTrue(save.isEnabled, app.debugDescription)
            save.tap()
            let saved = NSPredicate(format: "exists == true AND enabled == false")
            let confirmation = XCTNSPredicateExpectation(predicate: saved, object: save)
            XCTAssertEqual(XCTWaiter.wait(for: [confirmation], timeout: 10), .completed, app.debugDescription)
            app.navigationBars.buttons.element(boundBy: 0).tap()
            openDelay()
            assertPicker(seconds: seconds)
            XCTAssertFalse(save.isEnabled)
            previous = seconds
        }
    }

    func openDelay() {
        let link = app.buttons["App Clip Settings"]
        XCTAssertTrue(link.waitForExistence(timeout: 10), app.debugDescription)
        link.tap()
        XCTAssertTrue(picker.waitForExistence(timeout: 15), app.debugDescription)
    }

    func title(_ value: Int) -> String {
        value == 0 ? "0 s (immediate)" : "\(value) s"
    }

    func assertPicker(seconds: Int) {
        let text = title(seconds)
        let reported = [picker.label, picker.value as? String ?? ""].joined(separator: " ")
        let visibleLabel = app.staticTexts[text]
        XCTAssertTrue(reported.contains(text) || visibleLabel.exists, app.debugDescription)
    }

    func choose(_ seconds: Int, movingFrom previous: Int) {
        let text = title(seconds)
        let choice = app.buttons.matching(NSPredicate(format: "label == %@", text)).firstMatch
        for _ in 0..<30 {
            if choice.exists && choice.isHittable {
                let frame = choice.frame
                let screen = app.frame
                app.coordinate(withNormalizedOffset: CGVector(dx: frame.midX / screen.width, dy: frame.midY / screen.height)).tap()
                return
            }
            let cells = app.buttons.matching(NSPredicate(format: "label MATCHES %@", "[0-9]+ s( \\(immediate\\))?")).allElementsBoundByIndex
            let visible = cells.filter { $0.isHittable && $0.frame.width > 20 && $0.frame.height > 12 }
            guard let row = visible.dropFirst(visible.count / 2).first else {
                XCTFail("No visible entries in delay menu. \(app.debugDescription)")
                return
            }
            let screen = app.frame
            let x = min(0.9, max(0.1, row.frame.midX / screen.width))
            let direction: CGFloat = seconds > previous ? -1 : 1
            let y = min(0.72, max(0.28, row.frame.midY / screen.height))
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y - direction * 0.12))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y + direction * 0.12))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
            Thread.sleep(forTimeInterval: 0.35)
        }
        XCTFail("Could not scroll to \(text). \(app.debugDescription)")
    }
}

import XCTest

final class PerformanceUITests: XCTestCase {
    let app = XCUIApplication()
    var note: XCUIElement { app.textViews.firstMatch }
    var keyboard: XCUIElement { app.keyboards.firstMatch }
    func button(_ key: String) -> XCUIElement { app.buttons["notes." + key] }

    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func inspect(_ keys: [String], aboveKeyboard: Bool = false) {
        for key in keys {
            let item = button(key)
            XCTAssertTrue(item.exists, key + ": " + app.debugDescription)
            let frame = item.frame
            print("NOTE-LAYOUT", key, frame)
            XCTAssertTrue(item.isHittable, key)
            XCTAssertGreaterThanOrEqual(frame.width, 43, key)
            XCTAssertGreaterThanOrEqual(frame.height, 43, key)
            XCTAssertGreaterThanOrEqual(frame.minX, -1, key)
            XCTAssertLessThanOrEqual(frame.maxX, app.frame.width + 1, key)
            if aboveKeyboard {
                XCTAssertLessThanOrEqual(frame.maxY, keyboard.frame.minY + 1, key)
            }
        }
    }

    func dismissKeyboardWelcome() {
        let proceed = app.descendants(matching: .any).matching(
            NSPredicate(format: "label ==[c] 'Continue'")
        ).firstMatch
        if proceed.waitForExistence(timeout: 3), proceed.isHittable {
            proceed.tap()
        } else if keyboard.keys.count < 10 {
            // On some iOS runtimes the first-run keyboard card is in a remote view.
            keyboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.87)).tap()
        }
        XCTAssertTrue(keyboard.keys.element(boundBy: 9).waitForExistence(timeout: 6), app.debugDescription)
    }

    func testNotesReadingAndEditing() {
        continueAfterFailure = false
        app.launchEnvironment["FIXTURE_PROFILE"] = "empty-disabled"
        app.launch()
        XCTAssertTrue(note.waitForExistence(timeout: 20), app.debugDescription)
        let width = app.frame.width
        print("NOTE-LAYOUT", "screen", app.frame)
        if ProcessInfo.processInfo.environment["NOTES_SIZE"] == "small" {
            XCTAssertLessThan(width, 400)
        }
        if ProcessInfo.processInfo.environment["NOTES_SIZE"] == "large" {
            XCTAssertGreaterThanOrEqual(width, 428)
        }
        inspect(["back", "share", "more", "checklist", "attachment", "markup", "compose"])
        XCTAssertLessThan(button("back").frame.maxX, button("share").frame.minX)
        XCTAssertLessThan(button("markup").frame.maxX, button("compose").frame.minX)
        for key in ["checklist", "attachment", "markup", "compose"] {
            let bottomInset = app.frame.maxY - button(key).frame.maxY
            print("NOTE-LAYOUT", "resting bottom inset", key, bottomInset)
            XCTAssertGreaterThanOrEqual(bottomInset, 27, key)
            XCTAssertLessThanOrEqual(bottomInset, 40, key)
        }
        capture("01-Reading")
        for key in ["checklist", "attachment", "markup", "more", "share"] {
            button(key).tap()
            XCTAssertFalse(keyboard.exists)
            XCTAssertEqual(note.value as? String ?? "", "")
        }
        button("compose").tap()
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10), app.debugDescription)
        dismissKeyboardWelcome()
        inspect(["done", "formatting", "checklist", "table", "attachment"], aboveKeyboard: true)
        XCTAssertLessThan(button("more").frame.maxX, button("done").frame.minX)
        let keyboardGap = keyboard.frame.minY - button("formatting").frame.maxY
        print("NOTE-LAYOUT", "keyboard gap", keyboardGap)
        XCTAssertEqual(keyboardGap, 10, accuracy: 2)
        capture("02-Editing")
        note.typeText("Jamie")
        for key in ["formatting", "checklist", "table", "attachment"] {
            button(key).tap()
            XCTAssertTrue(keyboard.exists)
            XCTAssertEqual(note.value as? String, "Jamie", key)
        }
        let last = button("bold")
        let anchor = button("table")
        let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: app.frame.width - 37, dy: anchor.frame.midY))
        let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 42, dy: anchor.frame.midY))
        start.press(forDuration: 0.12, thenDragTo: end)
        inspect(["markup", "bold"], aboveKeyboard: true)
        last.tap()
        XCTAssertEqual(note.value as? String, "Jamie")
        capture("03-Editing-scrolled")
        button("done").tap()
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 6))
        XCTAssertEqual(note.value as? String, "Jamie")
        app.terminate()
        app.launchEnvironment["FIXTURE_PROFILE"] = "empty"
        app.launch()
        XCTAssertTrue(note.waitForExistence(timeout: 15))
        button("share").press(forDuration: 0.95)
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 8))
        XCTAssertTrue(alert.staticTexts["Taylor Anderson"].exists)
        alert.buttons["Close"].tap()
    }
}

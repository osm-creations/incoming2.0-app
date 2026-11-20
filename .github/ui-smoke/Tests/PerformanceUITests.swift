import XCTest

final class PerformanceUITests: XCTestCase {
    private let app = XCUIApplication()
    private var note: XCUIElement { app.textViews.firstMatch }
    private var keyboard: XCUIElement { app.keyboards.firstMatch }
    private var aa: XCUIElement { app.buttons["notes.formatting"] }
    private var checklist: XCUIElement { app.buttons["notes.checklist"] }
    private func clock() -> TimeInterval { ProcessInfo.processInfo.systemUptime }

    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ profile: String) {
        app.launchEnvironment["FIXTURE_PROFILE"] = profile
        app.launch()
        XCTAssertTrue(note.waitForExistence(timeout: 18), app.debugDescription)
        XCTAssertEqual(note.value as? String ?? "", "")
        print("CLIP-QA profile", profile, app.frame)
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func edit(plain: Bool = false) {
        if plain { note.tap() } else { app.buttons["notes.compose"].tap() }
        XCTAssertTrue(keyboard.waitForExistence(timeout: 10), app.debugDescription)
    }

    private func typeLetters(_ name: String) {
        for letter in name {
            let key = keyboard.keys.matching(NSPredicate(format: "label ==[c] %@", String(letter))).firstMatch
            XCTAssertTrue(key.waitForExistence(timeout: 5) && key.isHittable, app.debugDescription)
            key.tap()
        }
        XCTAssertEqual((note.value as? String)?.lowercased(), name.lowercased())
    }

    private func toggle(_ selected: Bool) {
        aa.tap()
        XCTAssertEqual(aa.value as? String, selected ? "On" : "Off")
    }

    private func lookup(_ control: XCUIElement, choose: String, longPress: Bool = true) {
        XCTAssertTrue(control.isHittable, control.description)
        if longPress { control.press(forDuration: 0.9) } else { control.tap() }
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 7), app.debugDescription)
        XCTAssertTrue(alert.staticTexts["Taylor Anderson"].exists)
        capture("Inject preview " + choose)
        alert.buttons[choose].tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 6))
    }

    private func reveal(_ expected: String, plain: Bool = false, verifyTiming: Bool = false) {
        note.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        XCTAssertTrue(note.waitForNonExistence(timeout: 5), app.debugDescription)
        Thread.sleep(forTimeInterval: 0.45) // Let the Notes-to-black crossfade finish.
        let caller = plain ? app.buttons[expected] : app.staticTexts[expected]
        XCTAssertFalse(caller.exists)
        let start = clock()
        app.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        var repeated: TimeInterval?
        if verifyTiming {
            Thread.sleep(forTimeInterval: 1.65)
            XCTAssertFalse(caller.exists, "Caller was revealed early")
            repeated = clock()
            app.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        }
        XCTAssertTrue(caller.waitForExistence(timeout: 11), app.debugDescription)
        let elapsed = clock() - start
        print("CLIP-QA caller", expected, "delay", elapsed, "seconds")
        XCTAssertGreaterThanOrEqual(elapsed, 4.9)
        if let repeated {
            XCTAssertLessThan(clock() - repeated, 5.0, "The repeat triple restarted the timer")
        }
        capture((plain ? "Plain " : "Standard ") + expected)
        if plain {
            caller.tap()
        } else {
            let slider = app.buttons["Answer call"]
            XCTAssertTrue(slider.exists)
            let from = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.50))
            let to = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.91, dy: 0.50))
            from.press(forDuration: 0.15, thenDragTo: to)
        }
        XCTAssertTrue(note.waitForExistence(timeout: 9), app.debugDescription)
    }

    func testStandardNameSourcesAndChecklist() {
        launch("standard")
        app.buttons["notes.share"].press(forDuration: 0.95)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        checklist.tap()
        XCTAssertFalse(app.alerts.firstMatch.exists)
        edit()
        XCTAssertEqual(aa.value as? String, "Off")
        toggle(true)
        typeLetters("Lin")
        let name = note.value as! String
        lookup(checklist, choose: "Close")
        XCTAssertEqual(aa.value as? String, "On")
        reveal(name, verifyTiming: true)
        XCTAssertEqual(note.value as? String, name)

        edit()
        XCTAssertEqual(aa.value as? String, "On")
        toggle(false)
        app.buttons["notes.done"].tap()
        reveal("Jamie")

        edit()
        toggle(true)
        app.buttons["notes.done"].tap()
        lookup(checklist, choose: "Use")
        edit()
        XCTAssertEqual(aa.value as? String, "Off")
        toggle(true)
        toggle(false)
        reveal("Taylor Anderson")
    }

    func testPlainNotesSelectionAndWhiteReveal() {
        launch("plain")
        app.buttons["Tools"].tap()
        let menu = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier == %@ OR label == %@", "notes.useNoteAsCallerName", "Use note as caller name")).firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 5), app.debugDescription)
        menu.tap()
        edit(plain: true)
        typeLetters("Ivy")
        let name = note.value as! String
        let lookupControl = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier == %@ OR label == %@", "notes.getCallerName", "Get caller name")).firstMatch
        lookup(lookupControl, choose: "Close")
        reveal(name, plain: true)
        XCTAssertEqual(note.value as? String, name)
        lookup(lookupControl, choose: "Use", longPress: false)
        reveal("Taylor Anderson", plain: true)
    }

    func testDisabledProfileDoesNotFetchOrInheritSelection() {
        launch("disabled")
        checklist.press(forDuration: 0.9)
        app.buttons["notes.share"].press(forDuration: 0.9)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        edit()
        XCTAssertEqual(aa.value as? String, "Off")
        reveal("Jamie")
    }
}

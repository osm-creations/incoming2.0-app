import XCTest


final class DashboardTests: XCTestCase {
    private let app = XCUIApplication()
    private var inject: XCUIElement { app.textFields["settings.injectUserID"] }
    private var save: XCUIElement { app.buttons["settings.saveInjectUserID"] }
    private var settings: XCUIElement { app.buttons["SETTINGS"] }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func restore(_ token: String) {
        app.terminate()
        app.launchEnvironment["QA_RESTORE_TOKEN"] = token
        app.launch()
        app.launchEnvironment.removeValue(forKey: "QA_RESTORE_TOKEN")
        XCTAssertTrue(settings.waitForExistence(timeout: 15), app.debugDescription)
        print("DASHBOARD-QA restored fixture session")
    }

    private func reveal(_ item: XCUIElement) {
        if item.isHittable { return }
        for _ in 0..<4 {
            // Scroll the list above the keyboard, within content a person can touch.
            let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.28))
            let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.54))
            bottom.press(forDuration: 0.05, thenDragTo: top)
            if item.isHittable { return }
        }
        XCTAssertTrue(item.isHittable, item.description)
    }

    private func signIn(_ login: String) {
        let username = app.textFields["User ID or email"]
        let password = app.secureTextFields["Password"]
        let submit = app.buttons["Login"]
        XCTAssertTrue(username.waitForExistence(timeout: 15), app.debugDescription)
        username.tap()
        username.typeText(login)
        password.tap()
        password.typeText("fixturepass")
        reveal(submit)
        submit.tap()
        XCTAssertTrue(settings.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Incoming"].exists, app.debugDescription)
        XCTAssertTrue(app.buttons["NOTES INPUT"].exists)
        XCTAssertFalse(app.buttons["INJECT INPUT"].exists)
        print("DASHBOARD-QA logged in", login)
    }

    private func openSettings(_ expected: String) {
        reveal(settings)
        settings.tap()
        XCTAssertTrue(inject.waitForExistence(timeout: 12), app.debugDescription)
        let value = inject.value as? String ?? ""
        if expected.isEmpty {
            XCTAssertTrue(value.isEmpty || value == inject.placeholderValue)
        } else {
            XCTAssertEqual(value, expected)
        }
        XCTAssertFalse(save.isEnabled)
        print("DASHBOARD-QA opened Settings with expected ID")
    }

    private func returnToDashboard() {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(back.waitForExistence(timeout: 6), app.debugDescription)
        back.tap()
        XCTAssertTrue(settings.waitForExistence(timeout: 8), app.debugDescription)
    }

    private func updateID(from old: String, to new: String, success: String) {
        inject.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        for _ in 0..<2 {
            inject.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
            // Delete the current value before replacing it. One extra harmless delete
            // handles the case where the system interrupted a partially typed edit.
            let current = inject.value as? String ?? old
            inject.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 1))
            if !new.isEmpty { inject.typeText(new) }
            let text = inject.value as? String ?? ""
            if text == new || (new.isEmpty && text == inject.placeholderValue) { break }
        }
        let text = inject.value as? String ?? ""
        XCTAssertTrue(text == new || (new.isEmpty && text == inject.placeholderValue), "Unexpected edited ID")
        XCTAssertTrue(save.isEnabled, app.debugDescription)
        reveal(save)
        save.tap()
        XCTAssertTrue(app.staticTexts[success].waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertFalse(save.isEnabled)
        print("DASHBOARD-QA saved ID; cleared =", new.isEmpty)
    }

    private func signOut() {
        let logout = app.buttons["LOG OUT"]
        reveal(logout)
        logout.tap()
        XCTAssertTrue(app.buttons["Login"].waitForExistence(timeout: 10), app.debugDescription)
    }

    func testLoginDashboardAndAccountInjectSettings() {
        continueAfterFailure = false
        app.launch()
        print("DASHBOARD-QA screen", app.frame)
        XCTAssertTrue(app.buttons["Login"].waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Incoming 2.0"].exists)
        XCTAssertTrue(app.staticTexts["By OSM Creations"].exists)
        capture("01-Login")
        restore("qa-alice-initial")
        XCTAssertTrue(app.staticTexts["Incoming"].exists)
        XCTAssertTrue(app.buttons["NOTES INPUT"].exists)
        XCTAssertFalse(app.buttons["INJECT INPUT"].exists)
        capture("02-Dashboard")
        openSettings("alpha_id")
        capture("03-Settings")
        updateID(from: "alpha_id", to: "updated_id", success: "Inject User ID saved.")
        returnToDashboard()
        openSettings("updated_id")
        signOut()

        restore("qa-bob")
        openSettings("beta_id")
        signOut()

        restore("qa-alice-return")
        openSettings("updated_id")
        updateID(from: "updated_id", to: "", success: "Inject is off.")
        returnToDashboard()
        openSettings("")
        print("DASHBOARD-QA verified persistence and account separation")
        signOut()
        signIn("bob")
    }
}

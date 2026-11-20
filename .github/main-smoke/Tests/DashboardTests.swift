import XCTest

final class DashboardTests: XCTestCase {
    private let app = XCUIApplication()

    private func capture(_ name: String) {
        Thread.sleep(forTimeInterval: 0.5)
        let image = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(data: image.pngRepresentation, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testReviewImages() {
        continueAfterFailure = false
        app.launchEnvironment["QA_CLEAR_SESSION"] = "1"
        app.launch()
        let signIn = app.buttons["Login"]
        XCTAssertTrue(signIn.waitForExistence(timeout: 25), app.debugDescription)
        let forgot = app.descendants(matching: .any).matching(identifier: "login.forgotPassword").firstMatch
        XCTAssertTrue(forgot.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(forgot.isHittable, app.debugDescription)
        capture("06-login")
        app.terminate()
        app.launchEnvironment["QA_CLEAR_SESSION"] = nil
        app.launchEnvironment["QA_RESTORE_TOKEN"] = "fixture-review"
        app.launch()
        let settings = app.buttons["dashboard.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 30), app.debugDescription)
        XCTAssertTrue(app.staticTexts["By OSM Creations"].exists)
        capture("01-main")

        settings.tap()
        let inject = app.textFields["settings.injectUserID"]
        XCTAssertTrue(inject.waitForExistence(timeout: 20), app.debugDescription)
        XCTAssertEqual(inject.value as? String, "performer_demo")
        capture("02-settings")
        app.buttons["App Clip Settings"].tap()
        let delay = app.descendants(matching: .any).matching(identifier: "settings.revealDelay").firstMatch
        XCTAssertTrue(delay.waitForExistence(timeout: 20), app.debugDescription)
        capture("07-clip-settings")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(inject.waitForExistence(timeout: 10), app.debugDescription)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let notes = app.buttons["dashboard.notes"]
        XCTAssertTrue(notes.waitForExistence(timeout: 10))
        notes.tap()
        let save = app.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Note"].exists)
        XCTAssertTrue(app.textViews.firstMatch.waitForExistence(timeout: 10), app.debugDescription)
        capture("03-notes-input")
    }
}

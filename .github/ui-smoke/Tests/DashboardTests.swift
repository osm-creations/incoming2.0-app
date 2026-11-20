import XCTest

final class DashboardTests: XCTestCase {
    private let app = XCUIApplication()

    private func capture(_ name: String) {
        let image = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(data: image.pngRepresentation, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testReviewImages() {
        continueAfterFailure = false
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

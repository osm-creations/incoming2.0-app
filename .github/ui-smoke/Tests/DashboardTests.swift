import XCTest

final class DashboardTests: XCTestCase {
    private let app = XCUIApplication()
    private var title: XCUIElement { app.staticTexts["dashboard.title"] }
    private var notes: XCUIElement { app.buttons["dashboard.notes"] }
    private var settings: XCUIElement { app.buttons["dashboard.settings"] }
    private var clear: XCUIElement { app.buttons["dashboard.clear"] }

    private func launch(_ token: String, largeText: Bool = false) {
        app.terminate()
        app.launchArguments = largeText ? ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] : []
        app.launchEnvironment["QA_RESTORE_TOKEN"] = token
        app.launch()
        XCTAssertTrue(title.waitForExistence(timeout: 20), app.debugDescription)
        XCTAssertEqual(title.label, "Incoming 2.0")
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func reachable(_ element: XCUIElement) {
        for _ in 0..<4 where !element.isHittable || !app.frame.contains(element.frame) {
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, element.description)
        XCTAssertGreaterThanOrEqual(element.frame.minX, 0)
        XCTAssertLessThanOrEqual(element.frame.maxX, app.frame.maxX + 0.5)
        XCTAssertGreaterThanOrEqual(element.frame.minY, 0)
        XCTAssertLessThanOrEqual(element.frame.maxY, app.frame.maxY + 0.5)
    }

    func testDashboardLayout() {
        continueAfterFailure = false
        launch("qa-alice-initial")
        let bounds = app.frame
        let initialTitleHeight = title.frame.height
        let isSE = bounds.width == 375 && bounds.height == 667
        print("DASHBOARD-QA screen", bounds, "title", title.frame, "notes", notes.frame, "settings", settings.frame, "clear", clear.frame)
        XCTAssertTrue(title.isHittable)
        XCTAssertLessThan(title.frame.midY, bounds.height * 0.32)
        XCTAssertTrue(app.staticTexts["By OSM Creations"].isHittable)
        for button in [notes, settings, clear] {
            XCTAssertTrue(button.isHittable, button.description)
            XCTAssertTrue(bounds.insetBy(dx: -0.5, dy: -0.5).contains(button.frame))
            XCTAssertGreaterThanOrEqual(button.frame.height, 43)
        }
        XCTAssertGreaterThan(notes.frame.minY, title.frame.maxY)
        XCTAssertGreaterThan(notes.frame.midY, bounds.height * 0.5)
        XCTAssertLessThanOrEqual(notes.frame.maxY, min(settings.frame.minY, clear.frame.minY))
        XCTAssertFalse(settings.frame.intersects(clear.frame))
        let bottomGap = bounds.maxY - max(settings.frame.maxY, clear.frame.maxY)
        print("DASHBOARD-QA bottom gap", bottomGap)
        XCTAssertEqual(bottomGap, isSE ? 22 : 56, accuracy: 3.0)
        capture("Dashboard-portrait")

        if isSE {
            launch("qa-alice-return", largeText: true)
            print("DASHBOARD-QA enlarged title height", title.frame.height, "initial height", initialTitleHeight)
            XCTAssertGreaterThan(title.frame.height, initialTitleHeight + 10)
            XCTAssertTrue(title.isHittable)
            capture("Dashboard-large-text-top")
            for button in [notes, settings, clear] { reachable(button) }
            print("DASHBOARD-QA enlarged controls", notes.frame, settings.frame, clear.frame)
            XCTAssertGreaterThanOrEqual(clear.frame.minY, settings.frame.maxY - 0.5)
            capture("Dashboard-large-text-actions")
        }
    }
}

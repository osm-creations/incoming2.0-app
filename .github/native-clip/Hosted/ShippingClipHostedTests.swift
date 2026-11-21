import XCTest
import SwiftUI
import UIKit
import MediaPlayer
@testable import IncomingClip

@MainActor
final class ShippingClipHostedTests: XCTestCase {
    private func eventually(_ check: () -> Bool) async -> Bool {
        for _ in 0..<150 {
            if check() { return true }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return false
    }

    private func hierarchy(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(hierarchy)
    }

    func testShippingClipWindowContainsRealVolumeViewOnlyOnBlack() async throws {
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.osmcreations.incoming2.Clip")
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String, "23")
        XCTAssertEqual(Bundle.main.executableURL?.lastPathComponent, "IncomingClip")
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, "http://localhost:8743")
        let coordinator = ClipCoordinator()
        let invoked = URL(string: "https://incoming2-0-server.incoming-osmcreations.workers.dev/c/AAAAAAAAAAAAAAAAAAAAAA")!
        await coordinator.handle(url: invoked)
        guard case let .notes(text, session) = coordinator.state else {
            XCTFail("The real production coordinator did not bootstrap the fixture")
            return
        }
        XCTAssertEqual(text,"Rose")
        let windowReady = await eventually { UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows).contains { $0.isKeyWindow } }
        XCTAssertTrue(windowReady)
        let window = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows).first { $0.isKeyWindow })
        let original = try XCTUnwrap(window.rootViewController)
        let rendered = UIHostingController(rootView: ClipRootView().environmentObject(coordinator))
        rendered.modalPresentationStyle = .fullScreen
        original.present(rendered, animated: false)
        defer { rendered.dismiss(animated: false) }
        let noteVisible = await eventually { self.hierarchy(window).contains { ($0 as? UITextView)?.text == "Rose" } }
        XCTAssertTrue(noteVisible)
        XCTAssertFalse(hierarchy(window).contains { $0.accessibilityIdentifier == "performance.systemVolumeView" })
        coordinator.enterBlack(text: text, session: session)
        let blackVisible = await eventually { self.hierarchy(window).contains { $0.accessibilityIdentifier == "performance.systemVolumeView" && $0.window === window && !$0.bounds.isEmpty } }
        XCTAssertTrue(blackVisible)
        let candidates = hierarchy(window).filter { $0.accessibilityIdentifier == "performance.systemVolumeView" }
        XCTAssertEqual(candidates.count, 1)
        let volume = try XCTUnwrap(candidates.first as? MPVolumeView)
        XCTAssertEqual(volume.superview?.accessibilityIdentifier, "performance.blackScreen")
        XCTAssertTrue(volume.window === window)
        XCTAssertFalse(volume.isHidden)
        XCTAssertEqual(volume.alpha, 1)
        XCTAssertTrue(volume.showsVolumeSlider)
        XCTAssertFalse(volume.isUserInteractionEnabled)
        XCTAssertTrue(volume.accessibilityElementsHidden)
        XCTAssertTrue(window.bounds.contains(volume.convert(volume.bounds, to: window)))
        print("SHIPPING-BLACK-PROBE bundle=\(Bundle.main.bundleIdentifier!) executable=\(Bundle.main.executableURL!.lastPathComponent) view=\(NSStringFromClass(type(of: volume))) bounds=\(volume.bounds) attached=true")
        coordinator.returnToNote(text: text, session: session)
        let removed = await eventually { !self.hierarchy(window).contains { $0.accessibilityIdentifier == "performance.systemVolumeView" } && self.hierarchy(window).contains { ($0 as? UITextView)?.text == "Rose" } }
        XCTAssertTrue(removed)
    }
}

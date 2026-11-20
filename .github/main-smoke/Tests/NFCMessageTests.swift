import CoreNFC
import XCTest

final class NFCMessageTests: XCTestCase {
    @MainActor
    func testCompactNDEFRecord() throws {
        let url = URL(string: "https://incoming2-0-server.incoming-osmcreations.workers.dev/c/AAAAAAAAAAAAAAAAAAAAAA")!
        let message = try XCTUnwrap(NFCWriterService.linkMessage(for: url))
        let record = try XCTUnwrap(message.records.first)
        XCTAssertEqual(message.records.count, 1)
        XCTAssertEqual(message.length, 82)
        XCTAssertEqual(record.payload.first, 0x04)
        XCTAssertEqual(record.wellKnownTypeURIPayload(), url)
    }
}

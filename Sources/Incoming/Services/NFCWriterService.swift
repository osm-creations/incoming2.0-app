import Foundation
import CoreNFC

@MainActor
final class NFCWriterService: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var message: String?
    private var session: NFCNDEFReaderSession?
    private var urlToWrite: URL?

    func write(url: URL) {
        guard NFCNDEFReaderSession.readingAvailable else { message = "NFC writing is not available on this device."; return }
        urlToWrite = url
        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        self.session = session
        session.alertMessage = "Hold your iPhone near the NFC tag."
        session.begin()
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in if (error as? NFCReaderError)?.code != .readerSessionInvalidationErrorFirstNDEFTagRead { self.message = error.localizedDescription } }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) { }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard tags.count == 1 else { session.alertMessage = "More than one tag detected."; session.restartPolling(); return }
        let tag = tags[0]
        session.connect(to: tag) { error in
            if let error { session.invalidate(errorMessage: error.localizedDescription); return }
            tag.queryNDEFStatus { status, _, error in
                if let error { session.invalidate(errorMessage: error.localizedDescription); return }
                guard status == .readWrite else { session.invalidate(errorMessage: "This NFC tag is not writable."); return }
                Task { @MainActor in
                    guard let url = self.urlToWrite, let payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) else { session.invalidate(errorMessage: "Could not create NFC payload."); return }
                    tag.writeNDEF(NFCNDEFMessage(records: [payload])) { error in
                        if let error { session.invalidate(errorMessage: error.localizedDescription) }
                        else { session.alertMessage = "Incoming App Clip link written successfully."; session.invalidate(); Task { @MainActor in self.message = "NFC tag written successfully." } }
                    }
                }
            }
        }
    }
}

import Foundation
@preconcurrency import CoreNFC

@MainActor
final class NFCWriterService: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    @Published var message: String?

    private var session: NFCTagReaderSession?
    private var urlToWrite: URL?

    func write(url: URL) {
        guard NFCTagReaderSession.readingAvailable else {
            message = "NFC writing is not available on this device."
            return
        }

        urlToWrite = url

        // NTAG / MIFARE Ultralight tags use ISO 14443. ISO 15693 is also
        // included so common long-range NDEF tags can be written as well.
        guard let reader = NFCTagReaderSession(
            pollingOption: [.iso14443, .iso15693],
            delegate: self,
            queue: nil
        ) else {
            message = "Could not start the NFC reader session."
            return
        }

        session = reader
        reader.alertMessage = "Hold your iPhone near the NFC tag."
        reader.begin()
    }

    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    nonisolated func tagReaderSession(
        _ session: NFCTagReaderSession,
        didInvalidateWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            guard let service = self else { return }

            let nfcError = error as? NFCReaderError
            switch nfcError?.code {
            case .readerSessionInvalidationErrorUserCanceled,
                 .readerSessionInvalidationErrorSessionTimeout:
                break
            default:
                service.message = error.localizedDescription
            }

            service.session = nil
        }
    }

    nonisolated func tagReaderSession(
        _ session: NFCTagReaderSession,
        didDetect tags: [NFCTag]
    ) {
        guard tags.count == 1, let tag = tags.first else {
            session.alertMessage = "More than one NFC tag detected. Remove the extra tag and try again."
            session.restartPolling()
            return
        }

        // Snapshot all MainActor-owned state before entering Core NFC's
        // concurrently-executing completion handlers. Keeping the immutable
        // service/url references avoids Swift 6's captured-var concurrency error.
        Task { @MainActor [weak self] in
            guard let service = self,
                  let url = service.urlToWrite,
                  let payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) else {
                session.invalidate(errorMessage: "Could not create the NFC payload.")
                return
            }

            let ndefMessage = NFCNDEFMessage(records: [payload])
            service.connectAndWrite(
                session: session,
                tag: tag,
                messageToWrite: ndefMessage
            )
        }
    }

    @MainActor
    private func connectAndWrite(
        session: NFCTagReaderSession,
        tag: NFCTag,
        messageToWrite: NFCNDEFMessage
    ) {
        // Capture an immutable actor-isolated reference. Do not weak-bind `self`
        // and then capture that mutable binding inside nested @Sendable callbacks.
        let service = self

        session.connect(to: tag) { error in
            if let error {
                session.invalidate(errorMessage: error.localizedDescription)
                return
            }

            guard let ndefTag = Self.ndefTag(from: tag) else {
                session.invalidate(errorMessage: "This NFC tag does not support NDEF data.")
                return
            }

            ndefTag.queryNDEFStatus { status, _, error in
                if let error {
                    session.invalidate(errorMessage: error.localizedDescription)
                    return
                }

                guard status == .readWrite else {
                    switch status {
                    case .readOnly:
                        session.invalidate(errorMessage: "This NFC tag is read-only.")
                    case .notSupported:
                        session.invalidate(errorMessage: "This NFC tag does not support NDEF data.")
                    default:
                        session.invalidate(errorMessage: "This NFC tag is not writable.")
                    }
                    return
                }

                ndefTag.writeNDEF(messageToWrite) { error in
                    if let error {
                        session.invalidate(errorMessage: error.localizedDescription)
                        return
                    }

                    session.alertMessage = "Incoming App Clip link written successfully."
                    session.invalidate()

                    Task { @MainActor in
                        service.message = "NFC tag written successfully."
                        service.session = nil
                    }
                }
            }
        }
    }

    nonisolated private static func ndefTag(from tag: NFCTag) -> NFCNDEFTag? {
        switch tag {
        case .miFare(let tag):
            return tag
        case .iso15693(let tag):
            return tag
        case .iso7816(let tag):
            return tag
        case .feliCa(let tag):
            return tag
        @unknown default:
            return nil
        }
    }
}

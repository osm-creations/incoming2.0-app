import SwiftUI

struct NotesReplicaView: View {
    let initialText: String
    @Binding var usesNoteAsCallerName: Bool
    let canFetchSelection: Bool
    let fetchSelection: () async throws -> String
    let onUseSelection: (String) -> Void
    let onTripleTap: (String) -> Void
    let usesPlainPresentation: Bool

    private enum LookupDialog {
        case selection(String)
        case failure(String)

        var message: String {
            switch self {
            case .selection(let name): return name.callerDisplayName
            case .failure(let message): return message
            }
        }
    }

    @State private var dialog: LookupDialog?
    @State private var isLookingUp = false

    var body: some View {
        IncomingNotesView(
            initialText: initialText,
            onTripleTap: onTripleTap,
            usesNoteAsCallerName: $usesNoteAsCallerName,
            onGetCallerName: canFetchSelection ? { isLookingUp = true } : nil,
            isFetchingCallerName: isLookingUp,
            usesPlainPresentation: usesPlainPresentation
        )
        .task(id: isLookingUp) {
            guard isLookingUp else { return }
            do {
                let name = try await fetchSelection()
                guard !Task.isCancelled else { return }
                dialog = .selection(name)
            } catch {
                guard !Task.isCancelled else { return }
                dialog = .failure(error.localizedDescription)
            }
            isLookingUp = false
        }
        .alert(dialogTitle, isPresented: Binding(
            get: { dialog != nil },
            set: { if !$0 { dialog = nil } }
        ), presenting: dialog) { result in
            if case .selection(let name) = result {
                Button("Use") { onUseSelection(name) }
            }
            Button("Close", role: .cancel) {}
        } message: { result in
            Text(verbatim: result.message)
        }
    }

    private var dialogTitle: String {
        if case .selection? = dialog { return "Use this caller name?" }
        return "Selection unavailable"
    }
}

import SwiftUI
import UIKit

enum IncomingTheme {
    static let background = Color(red: 0.02, green: 0.03, blue: 0.06)
    static let card = Color(red: 0.04, green: 0.07, blue: 0.12)
    static let border = Color(red: 0.25, green: 0.43, blue: 0.70)
    static let accent = Color(red: 0.30, green: 0.62, blue: 1.0)
    static let secondary = Color(red: 0.57, green: 0.68, blue: 0.84)
    static let notesYellow = Color(red: 1.0, green: 0.76, blue: 0.0)
}

struct IncomingCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(IncomingTheme.card.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(IncomingTheme.border.opacity(0.65), lineWidth: 1)
                    )
                    .shadow(color: IncomingTheme.accent.opacity(0.08), radius: 24)
            )
    }
}

struct IncomingButtonStyle: ButtonStyle {
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        prominent
                            ? IncomingTheme.accent.opacity(configuration.isPressed ? 0.65 : 0.90)
                            : IncomingTheme.card
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(IncomingTheme.border, lineWidth: 1)
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// Editable Notes surface shared by the performer and spectator interfaces.
@MainActor
struct IncomingNotesView: View {
    let showsSave: Bool
    let onBack: (() -> Void)?
    let onTextChanged: (String) -> Void
    let onSave: ((String) -> Void)?
    let onTripleTap: ((String) -> Void)?
    let onShareLongPress: (() -> Void)?
    let shareIsLoading: Bool

    @State private var noteText: String
    @State private var openedAt = Date()
    @StateObject private var editor = NoteEditorController()

    init(
        initialText: String,
        showsSave: Bool = false,
        onBack: (() -> Void)? = nil,
        onTextChanged: @escaping (String) -> Void = { _ in },
        onSave: ((String) -> Void)? = nil,
        onTripleTap: ((String) -> Void)? = nil,
        onShareLongPress: (() -> Void)? = nil,
        shareIsLoading: Bool = false
    ) {
        self.showsSave = showsSave
        self.onBack = onBack
        self.onTextChanged = onTextChanged
        self.onSave = onSave
        self.onTripleTap = onTripleTap
        self.onShareLongPress = onShareLongPress
        self.shareIsLoading = shareIsLoading
        _noteText = State(initialValue: initialText)
    }

    var body: some View {
        VStack(spacing: 0) {
            notesTopBar
                .padding(.horizontal, 16)
                .padding(.top, 4)

            Text(openedAt.formatted(date: .long, time: .shortened))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 12)

            IncomingTripleTapTextView(
                text: $noteText,
                editor: editor,
                onTextChanged: onTextChanged,
                onTripleTap: onTripleTap
            )
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            notesBottomBar
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
        .tint(IncomingTheme.notesYellow)
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .background(Color.black.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(false)
    }

    private var notesTopBar: some View {
        HStack(spacing: 8) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                        .incomingGlassCircle()
                }
                .accessibilityLabel("Back")
            } else {
                Text("Notes")
                    .font(.headline)
                    .foregroundStyle(IncomingTheme.notesYellow)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 4)

            if let onShareLongPress {
                ZStack {
                    if shareIsLoading {
                        ProgressView().tint(IncomingTheme.notesYellow)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .frame(width: 44, height: 44)
                .incomingGlassCircle()
                .contentShape(Circle())
                .onLongPressGesture(minimumDuration: 0.55, perform: onShareLongPress)
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(shareIsLoading ? "Fetching selection" : "Share")
                .accessibilityHint("Fetches a caller name for this performance")
                .accessibilityAction { onShareLongPress() }
                .disabled(shareIsLoading)
            }

            Menu {
                Button {
                    UIPasteboard.general.string = noteText
                } label: {
                    Label("Copy Note", systemImage: "doc.on.doc")
                }
                .disabled(noteText.isEmpty)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 44, height: 44)
                    .incomingGlassCircle()
            }
            .accessibilityLabel("Note options")

            if showsSave {
                Button {
                    onTextChanged(noteText)
                    onSave?(noteText)
                    editor.textView?.resignFirstResponder()
                } label: {
                    Image(systemName: "checkmark")
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                        .background(IncomingTheme.notesYellow, in: Circle())
                }
                .accessibilityLabel("Save note")
            }
        }
        .font(.title3.weight(.medium))
    }

    private var notesBottomBar: some View {
        HStack {
            HStack(spacing: 4) {
                Button { editor.textView?.undoManager?.undo() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Undo typing")
                .disabled(!editor.canUndo)

                Button { editor.insertListItem() } label: {
                    Image(systemName: "list.bullet")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Insert bullet")
            }
            .padding(.horizontal, 4)
            .incomingGlassCapsule()

            Spacer()

            Button {
                if editor.isEditing {
                    editor.textView?.resignFirstResponder()
                } else {
                    editor.textView?.becomeFirstResponder()
                }
            } label: {
                Image(systemName: editor.isEditing ? "keyboard.chevron.compact.down" : "square.and.pencil")
                    .frame(width: 44, height: 44)
                    .incomingGlassCircle()
            }
            .accessibilityLabel(editor.isEditing ? "Hide keyboard" : "Edit note")
        }
        .font(.title3)
    }
}

@MainActor
private final class NoteEditorController: ObservableObject {
    weak var textView: UITextView?
    @Published var isEditing = false
    @Published var canUndo = false

    func insertListItem() {
        guard let textView else { return }
        textView.becomeFirstResponder()
        guard let range = textView.selectedTextRange else { return }
        let before = textView.textRange(from: textView.beginningOfDocument, to: range.start)
        let previousText = before.flatMap { textView.text(in: $0) } ?? ""
        textView.insertText(previousText.isEmpty || previousText.hasSuffix("\n") ? "• " : "\n• ")
    }
}

private struct IncomingGlassCircleModifier: ViewModifier {
    let tint: Color?

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Circle())
            .background(
                Circle()
                    .fill((tint ?? Color.white).opacity(tint == nil ? 0.035 : 0.22))
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.7)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 5, y: 2)
    }
}

private struct IncomingGlassCapsuleModifier: ViewModifier {
    let tint: Color?

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Capsule())
            .background(
                Capsule()
                    .fill((tint ?? Color.white).opacity(tint == nil ? 0.035 : 0.22))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.7)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 5, y: 2)
    }
}

extension View {
    func incomingGlassCircle(tint: Color? = nil) -> some View {
        modifier(IncomingGlassCircleModifier(tint: tint))
    }

    func incomingGlassCapsule(tint: Color? = nil) -> some View {
        modifier(IncomingGlassCapsuleModifier(tint: tint))
    }
}

@MainActor
private struct IncomingTripleTapTextView: UIViewRepresentable {
    @Binding var text: String
    let editor: NoteEditorController
    let onTextChanged: (String) -> Void
    let onTripleTap: ((String) -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        editor.textView = textView
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = UIColor(red: 1, green: 0.76, blue: 0, alpha: 1)
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.text = text
        textView.accessibilityLabel = "Note"
        textView.keyboardDismissMode = .interactive
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 2, left: 0, bottom: 18, right: 0)
        textView.textContainer.lineFragmentPadding = 0

        if onTripleTap != nil {
            let tripleTap = UITapGestureRecognizer(target: context.coordinator,
                                                  action: #selector(Coordinator.handleTripleTap(_:)))
            tripleTap.numberOfTapsRequired = 3
            textView.addGestureRecognizer(tripleTap)
            for case let tap as UITapGestureRecognizer in textView.gestureRecognizers ?? [] {
                if tap !== tripleTap && tap.numberOfTapsRequired >= 2 {
                    tap.require(toFail: tripleTap)
                }
            }
        }
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        if textView.markedTextRange == nil && textView.text != text {
            textView.text = text
        }
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: IncomingTripleTapTextView

        init(_ parent: IncomingTripleTapTextView) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) { parent.editor.isEditing = true }
        func textViewDidEndEditing(_ textView: UITextView) { parent.editor.isEditing = false }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.onTextChanged(textView.text)
            parent.editor.canUndo = textView.undoManager?.canUndo ?? false
        }

        @objc func handleTripleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended, let textView = recognizer.view as? UITextView else { return }
            textView.resignFirstResponder()
            parent.onTripleTap?(textView.text)
        }
    }
}

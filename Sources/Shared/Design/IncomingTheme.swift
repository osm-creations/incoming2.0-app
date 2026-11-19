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
    let showsSystemShare: Bool

    @State private var noteText: String
    @State private var openedAt = Date()
    @State private var isInsertingLink = false
    @State private var linkDraft = ""
    @StateObject private var editor = NoteEditorController()

    init(
        initialText: String,
        showsSave: Bool = false,
        onBack: (() -> Void)? = nil,
        onTextChanged: @escaping (String) -> Void = { _ in },
        onSave: ((String) -> Void)? = nil,
        onTripleTap: ((String) -> Void)? = nil,
        onShareLongPress: (() -> Void)? = nil,
        shareIsLoading: Bool = false,
        showsSystemShare: Bool = false
    ) {
        self.showsSave = showsSave
        self.onBack = onBack
        self.onTextChanged = onTextChanged
        self.onSave = onSave
        self.onTripleTap = onTripleTap
        self.onShareLongPress = onShareLongPress
        self.shareIsLoading = shareIsLoading
        self.showsSystemShare = showsSystemShare
        _noteText = State(initialValue: initialText)
    }

    var body: some View {
        VStack(spacing: 0) {
            notesTopBar
                .padding(.horizontal, 16)
                .padding(.top, 2)

            Text(openedAt.formatted(date: .long, time: .shortened))
                .font(.footnote)
                .foregroundStyle(Color(white: 0.57))
                .padding(.top, 7)

            IncomingTripleTapTextView(
                text: $noteText, editor: editor,
                onTextChanged: onTextChanged, onTripleTap: onTripleTap
            )
            .padding(.horizontal, 24)
            .padding(.top, 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if editor.isEditing {
                editingTools
                    .padding(.horizontal, 8)
                    .padding(.bottom, 7)
            } else {
                idleTools
                    .padding(.horizontal, 23)
                    .padding(.bottom, 2)
            }
        }
        .tint(IncomingTheme.notesYellow)
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .background(Color.black.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(false)
        .alert("Insert Link", isPresented: $isInsertingLink) {
            TextField("https://example.com", text: $linkDraft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            Button("Insert") { editor.insert(linkDraft.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .disabled(linkDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) {}
        }
    }

    private var notesTopBar: some View {
        HStack(spacing: 10) {
            Button {
                if let onBack { onBack() }
                else { editor.textView?.resignFirstResponder() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .noteControlBackground(Circle())
            }
            .accessibilityLabel(onBack == nil ? "End editing" : "Back")
            .disabled(onBack == nil && !editor.isEditing)

            Spacer(minLength: 4)

            HStack(spacing: 0) {
                if let onShareLongPress {
                    Group {
                        if shareIsLoading { ProgressView().tint(IncomingTheme.notesYellow) }
                        else { Image(systemName: "square.and.arrow.up") }
                    }
                    .frame(width: 48, height: 42)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 0.55, perform: onShareLongPress)
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(shareIsLoading ? "Fetching selection" : "Share")
                    .accessibilityHint("Fetches a caller name for this performance")
                    .accessibilityAction { onShareLongPress() }
                    .disabled(shareIsLoading)
                } else if showsSystemShare {
                    ShareLink(item: noteText) {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 48, height: 42)
                    }
                    .accessibilityLabel("Share")
                    .disabled(noteText.isEmpty)
                    .opacity(noteText.isEmpty ? 0.32 : 1)
                }
                Menu {
                    Button { UIPasteboard.general.string = noteText } label: {
                        Label("Copy Note", systemImage: "doc.on.doc")
                    }
                    .disabled(noteText.isEmpty)
                    if showsSave {
                        Button { finishEditing() } label: {
                            Label("Save Note", systemImage: "checkmark")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 48, height: 42)
                }
                .accessibilityLabel("Note options")
            }
            .noteControlBackground(Capsule())

            if editor.isEditing {
                Button(action: finishEditing) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color(red: 0.94, green: 0.71, blue: 0), in: Circle())
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.7))
                }
                .accessibilityLabel(showsSave ? "Save note" : "Done")
            }
        }
        .font(.system(size: 19, weight: .medium))
    }

    private func finishEditing() {
        onTextChanged(noteText)
        onSave?(noteText)
        editor.textView?.resignFirstResponder()
    }

    private var idleTools: some View {
        HStack {
            HStack(spacing: 4) {
                checklistButton
                linkButton
                drawingSymbol
            }
            .padding(.horizontal, 4)
            .noteControlBackground(Capsule())

            Spacer()
            Button { editor.textView?.becomeFirstResponder() } label: {
                Image(systemName: "square.and.pencil")
                    .frame(width: 44, height: 44)
                    .noteControlBackground(Circle())
            }
            .accessibilityLabel("Edit note")
        }
        .font(.system(size: 19))
    }

    private var editingTools: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                Menu {
                    Button("Uppercase") { editor.changeCase(uppercase: true) }
                    Button("Lowercase") { editor.changeCase(uppercase: false) }
                } label: {
                    Text("Aa").font(.system(size: 19))
                        .frame(width: 52, height: 44)
                }
                .accessibilityLabel("Text case")

                checklistButton.frame(width: 58)
                Button { editor.insertLine("Column 1\tColumn 2\n") } label: {
                    Image(systemName: "tablecells").frame(width: 56, height: 44)
                }
                .accessibilityLabel("Insert tabbed columns")
                linkButton.frame(width: 54)
                drawingSymbol.frame(width: 52)
                Button { editor.textView?.undoManager?.undo() } label: {
                    Image(systemName: "arrow.uturn.backward").frame(width: 48, height: 44)
                }
                .accessibilityLabel("Undo")
                .disabled(!editor.canUndo)
            }
        }
        .font(.system(size: 19))
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .noteControlBackground(Capsule())
        .clipShape(Capsule())
    }

    private var checklistButton: some View {
        Button { editor.insertLine("☐ ") } label: {
            Image(systemName: "checklist").frame(width: 44, height: 44)
        }
        .accessibilityLabel("Insert checklist item")
    }

    private var linkButton: some View {
        Button {
            linkDraft = ""
            isInsertingLink = true
        } label: {
            Image(systemName: "paperclip").frame(width: 44, height: 44)
        }
        .accessibilityLabel("Insert link")
    }

    // This editor stores plain text. Drawings cannot be saved with a note.
    private var drawingSymbol: some View {
        Image(systemName: "pencil.tip.crop.circle")
            .foregroundStyle(Color(white: 0.40))
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)
    }
}

private extension View {
    func noteControlBackground<S: InsettableShape>(_ shape: S) -> some View {
        background(Color(white: 0.12), in: shape)
            .overlay(shape.strokeBorder(
                LinearGradient(colors: [Color.white.opacity(0.17), Color.white.opacity(0.04)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 0.8
            ))
    }
}

@MainActor
private final class NoteEditorController: ObservableObject {
    weak var textView: UITextView?
    @Published var isEditing = false
    @Published var canUndo = false

    func insert(_ value: String) {
        guard let textView else { return }
        textView.becomeFirstResponder()
        textView.insertText(value)
    }

    func insertLine(_ line: String) {
        guard let textView, let range = textView.selectedTextRange else { return }
        let before = textView.textRange(from: textView.beginningOfDocument, to: range.start)
        let precedingText = before.flatMap { textView.text(in: $0) } ?? ""
        insert(precedingText.isEmpty || precedingText.hasSuffix("\n") ? line : "\n" + line)
    }

    func changeCase(uppercase: Bool) {
        guard let textView else { return }
        let text = (textView.text ?? "") as NSString
        let selection = textView.selectedRange
        guard NSMaxRange(selection) <= text.length else { return }
        let range = selection.length == 0 ? text.paragraphRange(for: selection) : selection
        guard range.length > 0 else { return }
        let original = text.substring(with: range)
        textView.selectedRange = range
        insert(uppercase ? original.uppercased() : original.lowercased())
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
        context.coordinator.styleNote(textView)
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
            context.coordinator.styleNote(textView)
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
            styleNote(textView)
        }

        func styleNote(_ textView: UITextView) {
            guard textView.markedTextRange == nil else { return }
            let text = (textView.text ?? "") as NSString
            let firstLineBreak = text.rangeOfCharacter(from: .newlines).location
            let titleLength = min(firstLineBreak, text.length)
            let title = UIFontMetrics(forTextStyle: .title1).scaledFont(
                for: .systemFont(ofSize: 28, weight: .bold)
            )
            let body = UIFont.preferredFont(forTextStyle: .body)
            let storage = textView.textStorage
            storage.beginEditing()
            storage.addAttribute(.font, value: title, range: NSRange(location: 0, length: titleLength))
            storage.addAttribute(.font, value: body, range: NSRange(location: titleLength, length: text.length - titleLength))
            storage.endEditing()
            textView.typingAttributes = [.font: textView.selectedRange.location <= titleLength ? title : body,
                                         .foregroundColor: UIColor.white]
        }

        @objc func handleTripleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended, let textView = recognizer.view as? UITextView else { return }
            textView.resignFirstResponder()
            parent.onTripleTap?(textView.text)
        }
    }
}

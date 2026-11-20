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

struct IncomingLogo: View {
    let size: CGFloat

    var body: some View {
        Image(decorative: "IncomingLogo")
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .accessibilityHidden(true)
    }
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
    let onSave: ((String) -> Void)?
    let onTripleTap: ((String) -> Void)?
    let usesNoteAsCallerName: Binding<Bool>?
    let onGetCallerName: (() -> Void)?
    let isFetchingCallerName: Bool
    let showsSystemShare: Bool
    let usesPlainPresentation: Bool

    @State private var noteText: String
    @State private var openedAt = Date()
    @StateObject private var editor = NoteEditorController()

    init(
        initialText: String,
        showsSave: Bool = false,
        onBack: (() -> Void)? = nil,
        onSave: ((String) -> Void)? = nil,
        onTripleTap: ((String) -> Void)? = nil,
        usesNoteAsCallerName: Binding<Bool>? = nil,
        onGetCallerName: (() -> Void)? = nil,
        isFetchingCallerName: Bool = false,
        showsSystemShare: Bool = false,
        usesPlainPresentation: Bool
    ) {
        self.showsSave = showsSave
        self.onBack = onBack
        self.onSave = onSave
        self.onTripleTap = onTripleTap
        self.usesNoteAsCallerName = usesNoteAsCallerName
        self.onGetCallerName = onGetCallerName
        self.isFetchingCallerName = isFetchingCallerName
        self.showsSystemShare = showsSystemShare
        self.usesPlainPresentation = usesPlainPresentation
        _noteText = State(initialValue: initialText)
    }

    var body: some View {
        Group {
            if usesPlainPresentation {
                plainNotes
            } else {
                GeometryReader { geometry in
                    standardNotes(bottomSafeInset: geometry.safeAreaInsets.bottom)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(false)
    }

    private func standardNotes(bottomSafeInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            notesTopBar
                .padding(.horizontal, 20)

            Text(openedAt.formatted(date: .long, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.56))
                .padding(.top, 9)

            IncomingTripleTapTextView(
                text: $noteText, editor: editor,
                onTripleTap: onTripleTap
            )
            .padding(.horizontal, 28)
            .padding(.top, 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if editor.isEditing {
                editingTools
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            } else {
                idleTools
                    .padding(.horizontal, 28)
                    .padding(.bottom, max(0, 28 - bottomSafeInset))
            }
        }
        .tint(IncomingTheme.notesYellow)
        .foregroundStyle(.white)
        .buttonStyle(NoteToolbarButtonStyle())
        .background(Color.black.ignoresSafeArea())
    }

    private var plainNotes: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                if let onBack { Button("Back", action: onBack) }
                Text("Note").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Spacer()
                Menu("Tools") {
                    if let usesNoteAsCallerName {
                        Toggle("Use note as caller name", isOn: usesNoteAsCallerName)
                            .accessibilityIdentifier("notes.useNoteAsCallerName")
                    }
                    Button("Copy note") { UIPasteboard.general.string = noteText }
                        .disabled(noteText.isEmpty)
                    Button("Insert checklist item") { editor.insertLine("☐ ") }
                    Button("Insert tabbed columns") { editor.insertLine("Column 1\tColumn 2\n") }
                    Button("Uppercase") { editor.changeCase(uppercase: true) }
                    Button("Lowercase") { editor.changeCase(uppercase: false) }
                    Button("Undo") { editor.textView?.undoManager?.undo() }.disabled(!editor.canUndo)
                }
                if showsSave || editor.isEditing {
                    Button(showsSave ? "Save" : "Done", action: finishEditing)
                }
            }
            IncomingTripleTapTextView(
                text: $noteText, editor: editor,
                onTripleTap: onTripleTap,
                isPlain: true
            )
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 6))

            if let onGetCallerName {
                Text(isFetchingCallerName ? "Fetching caller name…" : "Get caller name")
                    .foregroundStyle(IncomingTheme.accent)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .gesture(LongPressGesture(minimumDuration: 0.55).exclusively(before: TapGesture())
                        .onEnded { _ in onGetCallerName() })
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("notes.getCallerName")
                    .accessibilityAction { onGetCallerName() }
                    .disabled(isFetchingCallerName)
            } else if showsSystemShare {
                ShareLink("Share note", item: noteText).disabled(noteText.isEmpty)
            }
        }
        .padding(16)
        .tint(IncomingTheme.accent)
        .background(IncomingTheme.background.ignoresSafeArea())
    }

    private var notesTopBar: some View {
        HStack(spacing: 12) {
            Button {
                if let onBack { onBack() } else { editor.textView?.resignFirstResponder() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .noteControlBackground(Circle())
            .accessibilityLabel(onBack == nil ? "End editing" : "Back")
            .accessibilityIdentifier("notes.back")

            Spacer(minLength: 0)

            HStack(spacing: 0) {
                accessory("square.and.arrow.up", label: "Share", id: "notes.share", width: 51, height: 44)
                    .foregroundStyle(Color(white: 0.33))
                accessory("ellipsis", label: "Note options", id: "notes.more", width: 50, height: 44)
            }
            .noteControlBackground(Capsule())

            if editor.isEditing {
                Button(action: finishEditing) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .noteControlBackground(Circle(), tint: Color(red: 0.87, green: 0.68, blue: 0.19))
                .accessibilityLabel(showsSave ? "Save caller name" : "Done")
                .accessibilityIdentifier("notes.done")
            }
        }
    }

    private func finishEditing() {
        onSave?(noteText)
        editor.textView?.resignFirstResponder()
    }

    private var idleTools: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                checklistControl(width: 56)
                accessory("paperclip", label: "Attachment", id: "notes.attachment", width: 56)
                accessory("pencil.tip.crop.circle", label: "Markup", id: "notes.markup", width: 56)
            }
            .noteControlBackground(Capsule())

            Spacer(minLength: 4)
            Button { editor.beginEditing() } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 23))
                    .foregroundStyle(noteText.isEmpty ? Color(white: 0.33) : .white)
                    .frame(width: 48, height: 48)
                    .contentShape(Circle())
            }
            .noteControlBackground(Circle())
            .accessibilityLabel("Edit note")
            .accessibilityIdentifier("notes.compose")
        }
    }

    private var editingTools: some View {
        GeometryReader { proxy in
            // Match the spacing of the five leading tools while leaving the next tool discoverable.
            let stride = min(80, max(48, (proxy.size.width - 6) / 5.35))
            ScrollView(.horizontal) {
                HStack(spacing: stride - 44) {
                    formattingControl
                    checklistControl(width: 44)
                    accessory("tablecells", label: "Table", id: "notes.table")
                    accessory("paperclip", label: "Attachment", id: "notes.attachment")
                    accessory("pencil.tip.crop.circle", label: "Markup", id: "notes.markup")
                    accessory("bold", label: "Bold", id: "notes.bold")
                }
                .padding(.horizontal, 7)
            }
            .scrollIndicators(.hidden)
            .clipShape(Capsule())
            .noteControlBackground(Capsule())
        }
        .frame(height: 48)
    }

    @ViewBuilder
    private var formattingControl: some View {
        let button = Button {
            usesNoteAsCallerName?.wrappedValue.toggle()
        } label: {
            Text("Aa")
                .font(.system(size: 22))
                .foregroundStyle(usesNoteAsCallerName?.wrappedValue == true ? IncomingTheme.notesYellow : .white)
                .frame(width: 44, height: 48)
                .contentShape(Rectangle())
        }
        .accessibilityIdentifier("notes.formatting")

        if let usesNoteAsCallerName {
            button
                .accessibilityLabel("Use note as caller name")
                .accessibilityValue(usesNoteAsCallerName.wrappedValue ? "On" : "Off")
                .accessibilityAddTraits(usesNoteAsCallerName.wrappedValue ? .isSelected : [])
        } else {
            button.accessibilityLabel("Formatting")
        }
    }

    @ViewBuilder
    private func checklistControl(width: CGFloat) -> some View {
        let button = accessory("checklist", label: "Checklist", id: "notes.checklist", width: width)
        if let onGetCallerName {
            button
                .foregroundStyle(isFetchingCallerName ? Color.clear : .white)
                .overlay {
                    if isFetchingCallerName { ProgressView().tint(.white).allowsHitTesting(false) }
                }
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.55).onEnded { _ in onGetCallerName() })
                .accessibilityHint("Long-press to fetch a caller name for this performance")
                .accessibilityAction { onGetCallerName() }
                .disabled(isFetchingCallerName)
        } else {
            button
        }
    }

    private func accessory(_ symbol: String, label: String, id: String,
                           width: CGFloat = 44, height: CGFloat = 48) -> some View {
        Button(action: {}) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .frame(width: width, height: height)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text(label))
        .accessibilityIdentifier(id)
    }
}

private struct NoteToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.55 : 1)
    }
}

private extension View {
    @ViewBuilder
    func noteControlBackground<S: InsettableShape>(_ shape: S, tint: Color? = nil) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(tint).interactive(), in: shape)
        } else {
            noteFallbackBackground(shape, tint: tint)
        }
        #else
        noteFallbackBackground(shape, tint: tint)
        #endif
    }

    private func noteFallbackBackground<S: InsettableShape>(_ shape: S, tint: Color?) -> some View {
        background(tint ?? Color(white: 0.12), in: shape)
            .overlay(shape.strokeBorder(
                LinearGradient(colors: [Color.white.opacity(0.17), Color.white.opacity(0.04)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 0.8
            ).allowsHitTesting(false))
    }
}

@MainActor
private final class NoteEditorController: ObservableObject {
    weak var textView: UITextView?
    @Published var isEditing = false
    @Published var canUndo = false

    // Spectator mode opens the keyboard only after a single tap has been
    // distinguished from the performance gesture.
    private(set) var isActivatingEditor = false

    func beginEditing() {
        isActivatingEditor = true
        defer { isActivatingEditor = false }
        textView?.becomeFirstResponder()
    }

    func insert(_ value: String) {
        guard let textView else { return }
        beginEditing()
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
    let onTripleTap: ((String) -> Void)?
    var isPlain = false

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        editor.textView = textView
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = isPlain ? UIColor(IncomingTheme.accent) : UIColor(red: 1, green: 0.76, blue: 0, alpha: 1)
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
            let triple = NoteTapRecognizer(target: context.coordinator,
                                           action: #selector(Coordinator.handleTripleTap(_:)))
            triple.numberOfTapsRequired = 3
            triple.delaysTouchesBegan = true
            triple.delegate = context.coordinator
            textView.addGestureRecognizer(triple)

            let single = NoteTapRecognizer(target: context.coordinator,
                                           action: #selector(Coordinator.handleReadingTap(_:)))
            single.require(toFail: triple)
            single.delegate = context.coordinator
            textView.addGestureRecognizer(single)
            context.coordinator.readingTap = single
            context.coordinator.performanceTap = triple
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
    final class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var parent: IncomingTripleTapTextView
        weak var readingTap: UITapGestureRecognizer?
        weak var performanceTap: UITapGestureRecognizer?

        init(_ parent: IncomingTripleTapTextView) {
            self.parent = parent
        }

        func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
            parent.onTripleTap == nil || parent.editor.isActivatingEditor || UIAccessibility.isVoiceOverRunning
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if gestureRecognizer === readingTap { return parent.editor.textView?.isFirstResponder == false }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Query at gesture time because UIKit can add text-selection
            // recognizers after the text view is created or starts editing.
            gestureRecognizer === performanceTap && otherGestureRecognizer is UITapGestureRecognizer
        }

        @objc func handleReadingTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended, let textView = recognizer.view as? UITextView else { return }
            parent.editor.beginEditing()
            if let point = textView.closestPosition(to: recognizer.location(in: textView)) {
                textView.selectedTextRange = textView.textRange(from: point, to: point)
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) { parent.editor.isEditing = true }
        func textViewDidEndEditing(_ textView: UITextView) { parent.editor.isEditing = false }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.editor.canUndo = textView.undoManager?.canUndo ?? false
            styleNote(textView)
        }

        func styleNote(_ textView: UITextView) {
            guard !parent.isPlain, textView.markedTextRange == nil else { return }
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

// A native selection recognizer may recognize an earlier contact in the same
// tap sequence. Keep observing so it cannot cancel the spectator gesture.
private final class NoteTapRecognizer: UITapGestureRecognizer {
    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}

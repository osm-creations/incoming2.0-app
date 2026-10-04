import SwiftUI
import UIKit

struct NotesReplicaView: View {
    let initialText: String
    let onTextChanged: (String) -> Void
    let onTripleTap: (String) -> Void

    @State private var noteText: String
    private let yellow = Color(red: 1.0, green: 0.78, blue: 0.0)

    init(
        initialText: String,
        onTextChanged: @escaping (String) -> Void,
        onTripleTap: @escaping (String) -> Void
    ) {
        self.initialText = initialText
        self.onTextChanged = onTextChanged
        self.onTripleTap = onTripleTap
        _noteText = State(initialValue: initialText)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: {}) {
                        Label("Back", systemImage: "chevron.left")
                    }

                    Spacer()

                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.title2)

                    Image(systemName: "arrow.uturn.forward.circle")
                        .font(.title2)
                        .opacity(0.35)

                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .padding(.leading, 16)

                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .opacity(0.35)
                }
                .foregroundStyle(yellow)
                .padding(.horizontal, 18)
                .padding(.top, 10)

                Text(Date.now.formatted(date: .long, time: .shortened))
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)

                TripleTapTextEditor(
                    text: $noteText,
                    onTextChanged: onTextChanged,
                    onTripleTap: {
                        onTextChanged(noteText)
                        onTripleTap(noteText)
                    }
                )
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack {
                    Image(systemName: "checklist")
                    Spacer()
                    Image(systemName: "paperclip")
                    Spacer()
                    Image(systemName: "pencil.tip.crop.circle")
                    Spacer()
                    Image(systemName: "square.and.pencil")
                }
                .foregroundStyle(yellow)
                .font(.title2)
                .padding(.horizontal, 35)
                .padding(.bottom, 20)
            }
        }
        .statusBarHidden(false)
    }
}

/// Editable notes text view that reserves a triple tap for the performance gesture.
///
/// UITextView already uses multi-tap gestures for text/paragraph selection. A normal
/// SwiftUI `.onTapGesture(count: 3)` therefore loses to the editor and shows the
/// selection/copy menu. This wrapper installs the secret triple-tap recognizer on the
/// UITextView itself and gives it priority over the editor's competing multi-tap
/// recognizers while preserving ordinary single-tap editing.
private struct TripleTapTextEditor: UIViewRepresentable {
    @Binding var text: String
    let onTextChanged: (String) -> Void
    let onTripleTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            onTextChanged: onTextChanged,
            onTripleTap: onTripleTap
        )
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.tintColor = UIColor(red: 1.0, green: 0.78, blue: 0.0, alpha: 1.0)
        textView.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        textView.text = text

        textView.isEditable = true
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.keyboardDismissMode = .interactive
        textView.alwaysBounceVertical = true

        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        textView.textContainer.lineFragmentPadding = 0

        let tripleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTripleTap(_:))
        )
        tripleTap.numberOfTapsRequired = 3
        tripleTap.numberOfTouchesRequired = 1

        // Important: cancel the UITextView's paragraph-selection action for the
        // three-tap sequence. Normal one- and two-tap editing stays available.
        tripleTap.cancelsTouchesInView = true
        tripleTap.delaysTouchesBegan = false
        tripleTap.delegate = context.coordinator

        textView.addGestureRecognizer(tripleTap)
        context.coordinator.tripleTapRecognizer = tripleTap

        // UITextView has private/system recognizers for double/triple-tap selection.
        // Only competing multi-tap recognizers wait for our secret gesture, so normal
        // cursor placement remains immediate.
        for recognizer in textView.gestureRecognizers ?? [] {
            guard recognizer !== tripleTap,
                  let tap = recognizer as? UITapGestureRecognizer,
                  tap.numberOfTapsRequired >= 2 else {
                continue
            }
            tap.require(toFail: tripleTap)
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }

        context.coordinator.text = $text
        context.coordinator.onTextChanged = onTextChanged
        context.coordinator.onTripleTap = onTripleTap
    }

    final class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var text: Binding<String>
        var onTextChanged: (String) -> Void
        var onTripleTap: () -> Void
        weak var tripleTapRecognizer: UITapGestureRecognizer?

        init(
            text: Binding<String>,
            onTextChanged: @escaping (String) -> Void,
            onTripleTap: @escaping () -> Void
        ) {
            self.text = text
            self.onTextChanged = onTextChanged
            self.onTripleTap = onTripleTap
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
            onTextChanged(textView.text)
        }

        @objc func handleTripleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }

            if let textView = recognizer.view as? UITextView {
                // Close the keyboard / edit menu before changing to the black screen.
                textView.resignFirstResponder()
                text.wrappedValue = textView.text
                onTextChanged(textView.text)
            }

            onTripleTap()
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            false
        }
    }
}

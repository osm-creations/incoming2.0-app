import SwiftUI

/// Legacy compatibility view.
///
/// Incoming 2.0 no longer presents multiple App Clip menu options. New App Clip
/// sessions open directly into the editable Notes experience. This view stays in
/// the project only so older project references/build files continue to compile.
struct ClipMenuView: View {
    let configuration: SpectatorConfiguration
    let session: ClipSession

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .tint(.white)

                Text("Opening Notes…")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(configuration.name)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

import SwiftUI

@MainActor
struct BlackPerformanceView: View {
    let onReveal: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingReveal: Task<Void, Never>?

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture(count: 3, perform: scheduleReveal)
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { cancelReveal() }
            }
            .onDisappear(perform: cancelReveal)
    }

    private func scheduleReveal() {
        guard scenePhase == .active, pendingReveal == nil else { return }
        pendingReveal = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(5))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            onReveal()
        }
    }

    private func cancelReveal() {
        pendingReveal?.cancel()
        pendingReveal = nil
    }
}

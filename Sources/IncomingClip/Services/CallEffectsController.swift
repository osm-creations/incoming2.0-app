import Combine
import UIKit

@MainActor
final class CallEffectsController: ObservableObject {
    private var vibrationTask: Task<Void, Never>?

    static func confirmCue() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func start() {
        guard vibrationTask == nil else { return }
        vibrationTask = Task { @MainActor in
            let generator = UINotificationFeedbackGenerator()
            while !Task.isCancelled {
                generator.prepare()
                generator.notificationOccurred(.warning)
                do {
                    try await Task.sleep(for: .milliseconds(1150))
                } catch {
                    return
                }
            }
        }
    }

    func stop() {
        vibrationTask?.cancel()
        vibrationTask = nil
    }

    deinit { vibrationTask?.cancel() }
}

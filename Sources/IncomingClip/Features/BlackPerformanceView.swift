import AVFAudio
import Combine
import SwiftUI
import UIKit

@MainActor
struct BlackPerformanceView: View {
    let delaySeconds: Int
    let onReveal: () -> Void
    let onReturnToNote: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var trigger = VolumeRevealTrigger()

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active {
                    trigger.arm(delaySeconds: delaySeconds, onReveal: onReveal)
                } else {
                    trigger.cancel()
                }
            }
            .onDisappear { trigger.cancel() }
            .alert("Volume trigger unavailable", isPresented: $trigger.activationFailed) {
                Button("Return to note", action: onReturnToNote)
            } message: {
                Text("The iPhone’s audio session could not be opened. Return to the note and try again.")
            }
    }
}

@MainActor
private final class VolumeRevealTrigger: ObservableObject {
    @Published var activationFailed = false

    private let audio = AVAudioSession.sharedInstance()
    private var observation: AnyCancellable?
    private var countdown: Task<Void, Never>?
    private var armedID: UUID?
    private var previousIdleTimerSetting: Bool?

    func arm(delaySeconds: Int, onReveal: @escaping () -> Void) {
        guard observation == nil, countdown == nil else { return }
        do {
            // Ambient audio mixes with other apps. We never play audio or set the user's volume.
            try audio.setCategory(.ambient)
            try audio.setActive(true)
        } catch {
            activationFailed = true
            return
        }

        activationFailed = false
        let id = UUID()
        armedID = id
        var previousVolume = audio.outputVolume
        var previousOutputs = audio.currentRoute.outputs.map(\.uid)
        var routeChangeTime: ContinuousClock.Instant?
        let volumeChanges = audio.publisher(for: \.outputVolume, options: [.new]).map { Optional($0) }
        let routeChanges = NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification, object: audio)
            .map { _ in Optional<Float>.none }

        observation = volumeChanges.merge(with: routeChanges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self, armedID == id, UIApplication.shared.applicationState == .active else { return }
                let outputs = audio.currentRoute.outputs.map(\.uid)
                if previousOutputs != outputs {
                    // Switching between the speaker and headphones can change volume without a press.
                    previousOutputs = outputs
                    previousVolume = audio.outputVolume
                    routeChangeTime = .now
                    return
                }
                guard let value, value != previousVolume else { return }
                previousVolume = value
                if let routeChangeTime, routeChangeTime.duration(to: .now) < .milliseconds(400) { return }
                scheduleReveal(after: delaySeconds, onReveal: onReveal)
            }
    }

    func cancel() {
        stopListening()
        countdown?.cancel()
        countdown = nil
        restoreIdleTimer()
    }

    private func restoreIdleTimer() {
        if let previousIdleTimerSetting {
            UIApplication.shared.isIdleTimerDisabled = previousIdleTimerSetting
            self.previousIdleTimerSetting = nil
        }
    }

    private func stopListening() {
        guard let observation else { return }
        armedID = nil
        observation.cancel()
        self.observation = nil
        try? audio.setActive(false)
    }

    private func scheduleReveal(after seconds: Int, onReveal: @escaping () -> Void) {
        stopListening()
        CallEffectsController.confirmCue()
        if seconds == 0 {
            onReveal()
            return
        }
        previousIdleTimerSetting = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true
        countdown = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            countdown = nil
            restoreIdleTimer()
            guard UIApplication.shared.applicationState == .active else { return }
            onReveal()
        }
    }
}

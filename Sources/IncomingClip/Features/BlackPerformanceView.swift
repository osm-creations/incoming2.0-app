import AVFAudio
import Combine
import SwiftUI
import UIKit
#if canImport(MediaPlayer)
import MediaPlayer
#endif

@MainActor
struct BlackPerformanceView: View {
    let delaySeconds: Int
    let onReveal: () -> Void
    let onReturnToNote: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var trigger = VolumeRevealTrigger()

    var body: some View {
        ZStack(alignment: .leading) {
            BlackGestureSurface(onReturn: returnToNote)
                .ignoresSafeArea()
            if let volume = trigger.meterVolume {
                GeometryReader { bounds in
                    ZStack(alignment: .bottom) {
                        Capsule().fill(Color(white: 0.12))
                        Capsule().fill(Color(white: 0.32))
                            .frame(height: bounds.size.height * CGFloat(volume))
                    }
                }
                .frame(width: 6, height: 96)
                .padding(.leading, 14)
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Media volume")
                .accessibilityValue(Text("\(Int((volume * 100).rounded())) percent"))
                .accessibilityIdentifier("performance.volumeMeter")
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: trigger.meterVolume != nil)
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
            Button("Return to note", action: returnToNote)
        } message: {
            Text("The iPhone’s audio session could not be opened. Return to the note and try again.")
        }
    }

    private func returnToNote() {
        trigger.cancel()
        onReturnToNote()
    }
}

private struct BlackGestureSurface: UIViewRepresentable {
    let onReturn: () -> Void

    func makeUIView(context: Context) -> Surface {
        let view = Surface()
        view.backgroundColor = .black
        view.isMultipleTouchEnabled = true
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = "performance.blackScreen"
        view.accessibilityLabel = "Black screen"
        view.accessibilityHint = "Use the escape gesture to return to the note."
        let swipe = UISwipeGestureRecognizer(target: view, action: #selector(Surface.swipedDown))
        swipe.numberOfTouchesRequired = 2
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
        #if canImport(MediaPlayer)
        installVolumeView(in: view)
        #endif
        return view
    }

    func updateUIView(_ view: Surface, context: Context) {
        view.onReturn = onReturn
    }

    #if canImport(MediaPlayer)
    private func installVolumeView(in surface: Surface) {
        // Device experiment: keep the native slider in the black screen's window.
        // The hardware cues and charcoal meter use AVAudioSession independently.
        let size = CGSize(width: 128, height: 28)
        let volumeView = MPVolumeView(frame: CGRect(origin: .zero, size: size))
        volumeView.translatesAutoresizingMaskIntoConstraints = false
        volumeView.showsVolumeSlider = true
        volumeView.showsRouteButton = false
        volumeView.backgroundColor = .black
        volumeView.isUserInteractionEnabled = false
        volumeView.isAccessibilityElement = false
        volumeView.accessibilityElementsHidden = true
        volumeView.accessibilityIdentifier = "performance.systemVolumeView"

        let imageBounds = CGRect(x: 0, y: 0, width: 16, height: 16)
        let blackImage = UIGraphicsImageRenderer(size: imageBounds.size).image { context in
            UIColor.black.setFill()
            context.fill(imageBounds)
        }.withRenderingMode(.alwaysOriginal)
        let track = blackImage.resizableImage(withCapInsets: .zero)
        volumeView.setMinimumVolumeSliderImage(track, for: .normal)
        volumeView.setMaximumVolumeSliderImage(track, for: .normal)
        volumeView.setVolumeThumbImage(blackImage, for: .normal)
        surface.addSubview(volumeView)
        NSLayoutConstraint.activate([
            volumeView.widthAnchor.constraint(equalToConstant: size.width),
            volumeView.heightAnchor.constraint(equalToConstant: size.height),
            volumeView.centerXAnchor.constraint(equalTo: surface.safeAreaLayoutGuide.centerXAnchor),
            volumeView.bottomAnchor.constraint(equalTo: surface.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }
    #endif

    final class Surface: UIView {
        var onReturn: (() -> Void)?

        @objc func swipedDown() { onReturn?() }

        override func accessibilityPerformEscape() -> Bool {
            onReturn?()
            return true
        }
    }
}

@MainActor
private final class VolumeRevealTrigger: ObservableObject {
    @Published var activationFailed = false
    @Published private(set) var meterVolume: Float?

    private let audio = AVAudioSession.sharedInstance()
    private var observation: AnyCancellable?
    private var countdown: Task<Void, Never>?
    private var meterDismissal: Task<Void, Never>?
    private var armedID: UUID?
    private var previousIdleTimerSetting: Bool?

    func arm(delaySeconds: Int, onReveal: @escaping () -> Void) {
        guard observation == nil else { return }
        do {
            // Ambient audio mixes with other apps. We never play audio or set the user's volume.
            try audio.setCategory(.ambient)
            try audio.setActive(true)
        } catch {
            activationFailed = true
            return
        }

        activationFailed = false
        previousIdleTimerSetting = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true
        let id = UUID()
        armedID = id
        var previousVolume: Float?
        var previousOutputs = audio.currentRoute.outputs.map(\.uid)
        var routeChangeTime: ContinuousClock.Instant?
        let volumeChanges = audio.publisher(for: \.outputVolume, options: [.initial, .new]).map { Optional($0) }
        let routeChanges = NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification, object: audio)
            .map { _ in Optional<Float>.none }

        observation = volumeChanges.merge(with: routeChanges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self, armedID == id, UIApplication.shared.applicationState == .active else { return }
                let outputs = audio.currentRoute.outputs.map(\.uid)
                if previousOutputs != outputs {
                    // A new output may have a different volume without a button press.
                    previousOutputs = outputs
                    previousVolume = audio.outputVolume
                    routeChangeTime = .now
                    hideMeter()
                    cancelCountdown()
                    return
                }
                guard let value else { return }
                let last = previousVolume
                previousVolume = value
                guard let last, value != last else { return }
                if let routeChangeTime, routeChangeTime.duration(to: .now) < .milliseconds(400) { return }
                showMeter(at: value)
                if value > last {
                    scheduleReveal(after: delaySeconds, onReveal: onReveal)
                } else {
                    cancelCountdown()
                }
            }
    }

    func cancel() {
        stopListening()
        cancelCountdown()
    }

    private func cancelCountdown() {
        countdown?.cancel()
        countdown = nil
    }

    private func showMeter(at volume: Float) {
        meterDismissal?.cancel()
        meterVolume = min(max(volume, 0), 1)
        meterDismissal = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(1200))
            } catch {
                return
            }
            meterVolume = nil
            meterDismissal = nil
        }
    }

    private func hideMeter() {
        meterDismissal?.cancel()
        meterDismissal = nil
        meterVolume = nil
    }

    private func stopListening() {
        hideMeter()
        guard let observation else { return }
        armedID = nil
        observation.cancel()
        self.observation = nil
        try? audio.setActive(false)
        if let previousIdleTimerSetting {
            UIApplication.shared.isIdleTimerDisabled = previousIdleTimerSetting
            self.previousIdleTimerSetting = nil
        }
    }

    private func scheduleReveal(after seconds: Int, onReveal: @escaping () -> Void) {
        // Keep observing until the reveal so down can cancel and up can restart.
        countdown?.cancel()
        CallEffectsController.confirmCue()
        if seconds == 0 {
            cancel()
            onReveal()
            return
        }
        countdown = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            countdown = nil
            stopListening()
            guard UIApplication.shared.applicationState == .active else { return }
            onReveal()
        }
    }
}

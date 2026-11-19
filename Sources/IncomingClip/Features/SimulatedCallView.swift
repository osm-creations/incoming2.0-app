import SwiftUI

@MainActor
struct SimulatedCallView: View {
    let caller: String
    let onEnd: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var effects = CallEffectsController()
    @State private var progress: CGFloat = 0
    @State private var answered = false

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 530
            VStack(spacing: 0) {
                VStack(spacing: 5) {
                    Text(caller)
                        .font(.system(.largeTitle, weight: .regular))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.68)
                        .accessibilityAddTraits(.isHeader)
                    Text(answered ? "Call Failed" : "mobile")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 24)
                .padding(.top, compact ? 8 : min(68, proxy.size.height * 0.075))

                Spacer(minLength: 8)

                VStack(spacing: compact ? 12 : 32) {
                    HStack {
                        CallUtilityLabel(title: "Remind Me", icon: "alarm.fill")
                        Spacer()
                        CallUtilityLabel(title: "Message", icon: "message.fill")
                    }
                    .padding(.horizontal, 28)
                    .accessibilityHidden(true)

                    answerSlider(height: compact ? 58 : 72)
                }
                .frame(maxWidth: 390)
                .padding(.horizontal, min(32, proxy.size.width * 0.065))
                .padding(.bottom, compact ? 9 : min(44, proxy.size.height * 0.045))
                .opacity(answered ? 0 : 1)
                .disabled(answered)
                .accessibilityHidden(answered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .foregroundStyle(.white)
        .background {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.23, green: 0.27, blue: 0.36),
                             Color(red: 0.13, green: 0.16, blue: 0.22),
                             Color(red: 0.05, green: 0.06, blue: 0.1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                RadialGradient(colors: [.white.opacity(0.12), .clear],
                               center: .topTrailing, startRadius: 0, endRadius: 410)
            }
            .ignoresSafeArea()
        }
        .statusBarHidden(false)
        .persistentSystemOverlays(.visible)
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active && !answered {
                effects.start()
            } else {
                effects.stop()
            }
        }
        .onDisappear { effects.stop() }
        .task(id: answered) {
            guard answered else { return }
            do {
                try await Task.sleep(for: .milliseconds(1250))
                try Task.checkCancellation()
                onEnd()
            } catch { /* The performance was dismissed. */ }
        }
    }

    private func answerSlider(height: CGFloat) -> some View {
        GeometryReader { geometry in
            let inset: CGFloat = 4
            let knob = height - 2 * inset
            let travel = max(1, geometry.size.width - knob - 2 * inset)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.thinMaterial)
                    .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))

                SlidePrompt(animate: !reduceMotion && !answered && scenePhase == .active)
                    .padding(.leading, knob + 8)
                    .padding(.trailing, 14)
                    .frame(maxWidth: .infinity)
                    .opacity(1 - Double(progress))
                    .accessibilityHidden(true)

                Image(systemName: "phone.fill")
                    .font(.system(size: knob * 0.41, weight: .semibold))
                    .foregroundStyle(Color(red: 0.13, green: 0.69, blue: 0.31))
                    .frame(width: knob, height: knob)
                    .background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
                    .contentShape(Circle())
                    .offset(x: inset + progress * travel)
                    .gesture(
                        DragGesture(minimumDistance: 2, coordinateSpace: .global)
                            .onChanged { drag in
                                guard !answered else { return }
                                progress = min(1, max(0, drag.translation.width / travel))
                            }
                            .onEnded { drag in
                                if drag.translation.width >= travel * 0.78 {
                                    answer()
                                } else {
                                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                                        progress = 0
                                    }
                                }
                            }
                    )
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Answer call")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { answer() }
    }

    private func answer() {
        guard !answered else { return }
        effects.stop()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.24)) {
            progress = 1
            answered = true
        }
    }
}

private struct CallUtilityLabel: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2.weight(.medium))
                .frame(width: 50, height: 50)
                .background(.white.opacity(0.13), in: Circle())
            Text(title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct SlidePrompt: View {
    let animate: Bool
    private let label = Text("slide to answer")

    var body: some View {
        label
            .font(.title3)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(.white.opacity(0.76))
            .overlay {
                if animate {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        GeometryReader { geometry in
                            let width = geometry.size.width
                            let band = width * 0.60
                            let time = context.date.timeIntervalSinceReferenceDate
                            let phase = CGFloat(time.truncatingRemainder(dividingBy: 2.4) / 2.4)
                            LinearGradient(colors: [.clear, .white, .clear],
                                           startPoint: .leading, endPoint: .trailing)
                                .frame(width: band)
                                .offset(x: -band + (width + band) * phase)
                        }
                    }
                    .mask(label.font(.title3).lineLimit(1).minimumScaleFactor(0.7))
                }
            }
    }
}

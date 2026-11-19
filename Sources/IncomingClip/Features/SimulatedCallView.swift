import SwiftUI

@MainActor
struct SimulatedCallView: View {
    let caller: String
    let onEnd: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1
    @StateObject private var effects = CallEffectsController()
    @State private var progress: CGFloat = 0
    @State private var answered = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let landscape = size.width > size.height
            let width = min(size.width, landscape ? size.height : 480)
            let utilityDiameter = width * 0.102
            let utilityCenterY = size.height * (landscape ? 0.54 : 0.715)
            let sliderCenterY = size.height * (landscape ? 0.82 : 0.863)
            let sliderWidth = width * 0.835

            ZStack(alignment: .top) {
                CallBackdrop()

                VStack(spacing: width * 0.007) {
                    Text(answered ? "Call Failed" : "mobile")
                        .font(.system(size: width * 0.049 * typeScale, weight: .semibold))
                        .foregroundStyle(.white.opacity(answered ? 0.95 : 0.58))
                    Text(caller)
                        .font(.system(size: width * 0.080 * typeScale, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.65)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.horizontal, width * 0.06)
                .padding(.top, size.height * (landscape ? 0.055 : 0.110))

                HStack(alignment: .top, spacing: 0) {
                    CallUtilityLabel(title: "Message", icon: "message.fill", diameter: utilityDiameter)
                        .frame(width: width * 0.28)
                    Spacer(minLength: 0)
                    CallUtilityLabel(title: "Remind Me", icon: "alarm.fill", diameter: utilityDiameter)
                        .frame(width: width * 0.28)
                }
                .frame(width: width * 0.90)
                .padding(.top, utilityCenterY - utilityDiameter / 2)
                .opacity(answered ? 0 : 1)
                .accessibilityHidden(true)

                answerSlider(width: sliderWidth, height: width * 0.216)
                    .position(x: size.width / 2, y: sliderCenterY)
                    .opacity(answered ? 0 : 1)
                    .disabled(answered)
                    .accessibilityHidden(answered)
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea(.container, edges: .vertical)
        .foregroundStyle(.white)
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

    private func answerSlider(width: CGFloat, height: CGFloat) -> some View {
        let inset = height * 0.067
        let knob = height - 2 * inset
        let travel = max(1, width - knob - 2 * inset)
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.165))
                .overlay(Capsule().strokeBorder(CallGlass.edge, lineWidth: 1))
                .shadow(color: .black.opacity(0.10), radius: 2, y: 1)

            SlidePrompt(size: height * 0.253 * typeScale,
                        animate: !reduceMotion && !answered && scenePhase == .active)
                .padding(.leading, knob + inset)
                .padding(.trailing, inset * 2.7)
                .frame(maxWidth: .infinity)
                .opacity(1 - Double(progress))
                .accessibilityHidden(true)

            Image(systemName: "phone.fill")
                .font(.system(size: knob * 0.38, weight: .semibold))
                .foregroundStyle(Color(red: 0.14, green: 0.82, blue: 0.34))
                .frame(width: knob, height: knob)
                .background(.white, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
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
        .frame(width: width, height: height)
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
    let diameter: CGFloat
    @ScaledMetric(relativeTo: .footnote) private var typeScale: CGFloat = 1

    var body: some View {
        VStack(spacing: diameter * 0.14) {
            Image(systemName: icon)
                .font(.system(size: diameter * 0.415, weight: .medium))
                .frame(width: diameter, height: diameter)
                .background(.white.opacity(0.18), in: Circle())
                .overlay(Circle().strokeBorder(CallGlass.edge, lineWidth: 0.75))
                .shadow(color: .black.opacity(0.14), radius: 1, y: 1)
            Text(title)
                .font(.system(size: diameter * 0.345 * typeScale))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}

private enum CallGlass {
    static let edge = LinearGradient(colors: [.white.opacity(0.64), .white.opacity(0.14),
                                              .black.opacity(0.10), .white.opacity(0.49)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)
}

private struct CallBackdrop: View {
    // Two vertical color fields preserve the warm red bloom on the left
    // and the softer, olive-brown falloff on the right.
    private func stop(_ red: Double, _ green: Double, _ blue: Double, at position: CGFloat) -> Gradient.Stop {
        Gradient.Stop(color: Color(red: red / 255, green: green / 255, blue: blue / 255), location: position)
    }

    var body: some View {
        ZStack {
            LinearGradient(stops: [
                stop(112, 107, 92, at: 0), stop(99, 82, 55, at: 0.30),
                stop(107, 57, 46, at: 0.48), stop(134, 40, 47, at: 0.70),
                stop(133, 45, 49, at: 0.77), stop(115, 69, 57, at: 0.92), stop(109, 79, 61, at: 1)
            ], startPoint: .top, endPoint: .bottom)

            LinearGradient(stops: [
                stop(102, 100, 91, at: 0), stop(88, 81, 65, at: 0.30),
                stop(101, 90, 82, at: 0.48), stop(95, 74, 65, at: 0.70),
                stop(93, 71, 60, at: 0.77), stop(96, 79, 61, at: 0.92), stop(98, 83, 64, at: 1)
            ], startPoint: .top, endPoint: .bottom)
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0.20),
                                         .init(color: .white, location: 0.90)],
                                 startPoint: .leading, endPoint: .trailing))
        }
        .accessibilityHidden(true)
    }
}

private struct SlidePrompt: View {
    let size: CGFloat
    let animate: Bool

    private var label: some View {
        Text("slide to answer")
            .font(.system(size: size))
            .lineLimit(1)
            .minimumScaleFactor(0.65)
    }

    var body: some View {
        label
            .foregroundStyle(.white.opacity(animate ? 0.51 : 0.86))
            .overlay {
                if animate {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        GeometryReader { geometry in
                            let width = geometry.size.width
                            let band = width * 0.75
                            let time = context.date.timeIntervalSinceReferenceDate
                            let phase = CGFloat(time.truncatingRemainder(dividingBy: 2.4) / 2.4)
                            LinearGradient(colors: [.clear, .white, .clear],
                                           startPoint: .leading, endPoint: .trailing)
                                .frame(width: band)
                                .offset(x: -band + (width + band) * phase)
                        }
                    }
                    .mask(label)
                }
            }
    }
}

import SwiftUI

struct SimulatedCallView: View {
    let caller: String
    let onEnd: (String) -> Void

    @StateObject private var effects = CallEffectsController()

    @State private var sliderOffset: CGFloat = 0
    @State private var shimmerPhase: CGFloat = -1.25
    @State private var callFailed = false
    @State private var isCompleting = false

    var body: some View {
        GeometryReader { proxy in
            let horizontalMargin: CGFloat = 22
            let sliderWidth = max(300, proxy.size.width - (horizontalMargin * 2))
            let knobSize: CGFloat = 68
            let innerInset: CGFloat = 6
            let travel = sliderWidth - knobSize - (innerInset * 2)

            ZStack {
                callBackground

                VStack(spacing: 0) {
                    // Keep the real iOS status bar visible. This view intentionally
                    // does not draw a fake time, battery, signal, or Dynamic Island.
                    Spacer()
                        .frame(height: 66)

                    Text("mobile")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.56))

                    Text(caller)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .padding(.horizontal, 30)
                        .padding(.top, 5)

                    Group {
                        if callFailed {
                            Text("Call Failed")
                                .foregroundStyle(.white.opacity(0.88))
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        } else {
                            Text(" ")
                        }
                    }
                    .font(.system(size: 18, weight: .medium))
                    .frame(height: 26)
                    .padding(.top, 5)

                    Spacer()

                    HStack {
                        SmallCallAction(
                            title: "Message",
                            icon: "message.fill",
                            action: {}
                        )

                        Spacer()

                        SmallCallAction(
                            title: "Remind Me",
                            icon: "alarm.fill",
                            action: {}
                        )
                    }
                    .padding(.horizontal, 69)
                    .padding(.bottom, 34)

                    answerSlider(
                        width: sliderWidth,
                        knobSize: knobSize,
                        innerInset: innerInset,
                        travel: travel
                    )
                    .padding(.horizontal, horizontalMargin)

                    Spacer()
                        .frame(height: 30)
                }
            }
            .onAppear {
                effects.start()

                withAnimation(
                    .linear(duration: 1.55)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerPhase = 1.25
                }
            }
            .onDisappear {
                effects.stop()
            }
        }
    }

    private var callBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.41, green: 0.42, blue: 0.46),
                    Color(red: 0.31, green: 0.32, blue: 0.36),
                    Color(red: 0.20, green: 0.21, blue: 0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear,
                    Color.black.opacity(0.13)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private func answerSlider(
        width: CGFloat,
        knobSize: CGFloat,
        innerInset: CGFloat,
        travel: CGFloat
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.white.opacity(0.22))
                .frame(width: width, height: 80)

            shimmeringSlideText
                .opacity(callFailed ? 0.35 : 1)

            HStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: knobSize, height: knobSize)
                        .shadow(color: .black.opacity(0.16), radius: 3, y: 1)

                    Image(systemName: "phone.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.green)
                }
                .offset(x: sliderOffset)
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            guard !callFailed, !isCompleting else { return }
                            sliderOffset = min(max(0, value.translation.width), travel)
                        }
                        .onEnded { _ in
                            guard !callFailed, !isCompleting else { return }

                            if sliderOffset >= travel * 0.74 {
                                completeSlide(travel: travel)
                            } else {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    sliderOffset = 0
                                }
                            }
                        }
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, innerInset)
            .frame(width: width, height: 80)
        }
    }

    private var shimmeringSlideText: some View {
        Text("slide to answer")
            .font(.system(size: 21, weight: .medium))
            .foregroundStyle(.black.opacity(0.66))
            .overlay {
                GeometryReader { geometry in
                    let bandWidth = max(140, geometry.size.width * 0.82)

                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: .white.opacity(0.10), location: 0.12),
                            .init(color: .white.opacity(0.95), location: 0.48),
                            .init(color: .white.opacity(0.18), location: 0.78),
                            .init(color: .clear, location: 1.00)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: bandWidth)
                    .offset(
                        x: shimmerPhase * (geometry.size.width + bandWidth)
                    )
                }
                .mask {
                    Text("slide to answer")
                        .font(.system(size: 21, weight: .medium))
                }
            }
            .compositingGroup()
    }

    private func completeSlide(travel: CGFloat) {
        guard !isCompleting else { return }
        isCompleting = true

        withAnimation(.easeOut(duration: 0.20)) {
            sliderOffset = travel
        }

        effects.stop()

        withAnimation(.easeInOut(duration: 0.22)) {
            callFailed = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.15))
            onEnd("FAILED")
        }
    }
}

private struct SmallCallAction: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 58, height: 58)

                    Image(systemName: icon)
                        .font(.system(size: 23, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.system(size: 15.5, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

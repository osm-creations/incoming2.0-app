import SwiftUI

enum IncomingTheme {
    static let background = Color(red: 0.02, green: 0.03, blue: 0.06)
    static let card = Color(red: 0.04, green: 0.07, blue: 0.12)
    static let border = Color(red: 0.25, green: 0.43, blue: 0.70)
    static let accent = Color(red: 0.30, green: 0.62, blue: 1.0)
    static let secondary = Color(red: 0.57, green: 0.68, blue: 0.84)
}

struct IncomingCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(IncomingTheme.card.opacity(0.82))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(IncomingTheme.border.opacity(0.65), lineWidth: 1))
                    .shadow(color: IncomingTheme.accent.opacity(0.08), radius: 24)
            )
    }
}

struct IncomingButtonStyle: ButtonStyle {
    let prominent: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(prominent ? IncomingTheme.accent.opacity(configuration.isPressed ? 0.65 : 0.9) : IncomingTheme.card)
            )
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(IncomingTheme.border, lineWidth: 1))
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

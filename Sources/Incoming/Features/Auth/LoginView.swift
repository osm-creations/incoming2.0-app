import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: AppSession
    @State private var login = ""
    @State private var password = ""
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                loginForm(logoSize: geometry.size.height < 500 ? 64 : 96)
                    .padding(24)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(IncomingTheme.background.ignoresSafeArea())
    }

    private func loginForm(logoSize: CGFloat) -> some View {
        VStack(spacing: 22) {
            IncomingLogo(size: logoSize)
            VStack(spacing: 4) {
                Text("Incoming 2.0")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("By OSM Creations").foregroundStyle(.secondary)
            }
            IncomingCard {
                VStack(spacing: 14) {
                    TextField("User ID or email", text: $login)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                        .padding()
                        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 13))
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 13))
                    if let error {
                        Text(error).font(.footnote).foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button(busy ? "Signing in…" : "Login") { Task { await signIn() } }
                        .buttonStyle(IncomingButtonStyle(prominent: true))
                        .disabled(busy || login.isEmpty || password.isEmpty)
                }
            }
            Text("Forgot your password? Ask your administrator to reset it.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func signIn() async {
        busy = true; error = nil; defer { busy = false }
        do { try await session.login(login: login, password: password) }
        catch { self.error = error.localizedDescription }
    }
}

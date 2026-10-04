import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var session: AppSession
    var body: some View {
        NavigationStack {
            ZStack {
                IncomingTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "phone.down.fill").font(.system(size: 48)).frame(width: 92, height: 92).background(RoundedRectangle(cornerRadius: 27).fill(.blue.gradient)).shadow(color: .blue.opacity(0.4), radius: 24)
                            Text("Incoming").font(.system(size: 36, weight: .medium))
                            Text("By OSM Creations").foregroundStyle(.secondary)
                        }.padding(.top, 24).padding(.bottom, 20)
                        NavigationLink { NotesInputView() } label: { DashboardTile(icon: "doc.text.fill", title: "NOTES INPUT") }
                        NavigationLink { InjectInputView() } label: { DashboardTile(icon: "syringe.fill", title: "INJECT INPUT") }
                        HStack(spacing: 14) {
                            NavigationLink { ClearInjectionView() } label: { Label("CLEAR", systemImage: "sparkles").frame(maxWidth: .infinity) }.buttonStyle(IncomingButtonStyle(prominent: false))
                            NavigationLink { SettingsView() } label: { Label("SETTINGS", systemImage: "gearshape.fill").frame(maxWidth: .infinity) }.buttonStyle(IncomingButtonStyle(prominent: false))
                        }
                        ActiveSessionMiniView()
                    }.padding(22).frame(maxWidth: 620)
                }
            }.navigationBarHidden(true)
        }.tint(IncomingTheme.accent)
    }
}
private struct DashboardTile: View { let icon: String; let title: String; var body: some View { VStack(spacing: 12){ Image(systemName: icon).font(.system(size: 34)).foregroundStyle(IncomingTheme.accent); Text(title).font(.title3) }.frame(maxWidth:.infinity,minHeight:150).background(RoundedRectangle(cornerRadius:24).fill(IncomingTheme.card.opacity(0.75))).overlay(RoundedRectangle(cornerRadius:24).stroke(IncomingTheme.border.opacity(0.65), lineWidth:1)) } }
private struct ActiveSessionMiniView: View {
    @EnvironmentObject var session: AppSession
    @State private var sessions: [PerformanceSession] = []

    var body: some View {
        Group {
            if let first = sessions.first {
                IncomingCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("ACTIVE SESSION")
                                .font(.caption)
                                .foregroundStyle(IncomingTheme.accent)
                            Text(first.configName)
                                .font(.headline)
                            Text(first.status.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .task {
            let data: PerformanceSessionsData? = try? await session.authenticated("/api/v1/performance/sessions")
            sessions = data?.sessions ?? []
        }
    }
}

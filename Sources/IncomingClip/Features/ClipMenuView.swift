import SwiftUI

struct ClipMenuView: View {
    @EnvironmentObject var coordinator:ClipCoordinator
    let configuration:SpectatorConfiguration; let session:ClipSession
    var body:some View{NavigationStack{List(configuration.options){option in Button(option.value){Task{await coordinator.select(option,configuration:configuration,session:session)}}.foregroundStyle(.primary)}.scrollContentBackground(.hidden).background(Color.black).navigationTitle(configuration.name)}}
}

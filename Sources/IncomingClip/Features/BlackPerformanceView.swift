import SwiftUI
struct BlackPerformanceView:View{let ready:Bool;let onTripleTap:()->Void;var body:some View{Color.black.ignoresSafeArea().contentShape(Rectangle()).onTapGesture(count:3){if ready{onTripleTap()}}.statusBarHidden(true).persistentSystemOverlays(.hidden)}}

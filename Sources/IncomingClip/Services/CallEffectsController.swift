import Foundation
import AVFoundation
import UIKit

@MainActor
final class CallEffectsController: ObservableObject {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    func start() {
        if let url=Bundle.main.url(forResource:"ringtone",withExtension:"wav") { player=try? AVAudioPlayer(contentsOf:url);player?.numberOfLoops = -1;player?.volume=0.8;player?.play() }
        let haptic=UINotificationFeedbackGenerator();haptic.prepare();haptic.notificationOccurred(.warning)
        timer=Timer.scheduledTimer(withTimeInterval:1.4,repeats:true){_ in Task{@MainActor in let g=UINotificationFeedbackGenerator();g.notificationOccurred(.warning)}}
    }
    func stop(){player?.stop();player=nil;timer?.invalidate();timer=nil}
    deinit { timer?.invalidate(); player?.stop() }
}

import Foundation
import SwiftUI
import ClipModel
import AVKit
import Combine

@available(iOS 13.0, *)
struct AudioView: View {
    let audio: ClipModel.Audio
    @State var isVisible: Bool = true

    var body: some View {
        AVPlayerView(audio: audio, isVisible: isVisible)
            .onDisappear {
                isVisible = false
            }
            .onAppear {
                isVisible = true
            }
            .frame(height: 44)
    }
}

@available(iOS 13.0, *)
private struct AVPlayerView: UIViewControllerRepresentable {
    let audio: Audio
    let isVisible: Bool

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if !isVisible {
            context.coordinator.pause()
        }
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        context.coordinator.controller
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(audio: audio)
    }

    class Coordinator {
        let player: AVPlayer
        let controller: AVPlayerViewController
        fileprivate var cancellables: Set<AnyCancellable> = []

        init(audio: Audio) {
            self.controller = AVPlayerViewController()
            controller.allowsPictureInPicturePlayback = false

            let videoAsset = AVURLAsset.init(url: audio.sourceURL)
            let playerItem = AVPlayerItem(asset: videoAsset)
            self.player = AVPlayer(playerItem: playerItem)
            self.player.isMuted = false

            controller.player = self.player

            if audio.looping {
                NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
                    .receive(on: DispatchQueue.main)
                    .compactMap { $0.object as? AVPlayerItem }
                    .sink { [weak self] _ in
                        guard let self = self else { return }
                        self.player.seek(to: .zero)
                        self.player.play()
                    }
                    .store(in: &cancellables)
            }

            if audio.allowBackground {

                let audioSession = AVAudioSession()
                try? audioSession.setCategory(.playback, mode: .moviePlayback)
                try? audioSession.setActive(true)

                NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
                    .removeDuplicates()
                    .receive(on: DispatchQueue.main)
                    .sink { _ in
                        self.controller.player = nil
                    }
                    .store(in: &cancellables)

                NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                    .removeDuplicates()
                    .receive(on: DispatchQueue.main)
                    .sink { _ in
                        self.controller.player = self.player
                    }
                    .store(in: &cancellables)
            }

            if audio.autoPlay {
                player.play()
            }
        }

        func pause() {
            player.pause()
        }
    }
}

@available(iOS 13.0, *)
private extension ClipModel.Video.ResizingMode {
    var avPlayerGravity: AVLayerVideoGravity {
        switch self {
        case .scaleToFill:
            return .resizeAspectFill
        case .scaleToFit:
            return .resizeAspect
        }
    }
}

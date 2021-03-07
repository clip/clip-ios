import Foundation
import SwiftUI
import ClipModel
import AVKit
import Combine

@available(iOS 13.0, *)
struct VideoView: View {
    let video: ClipModel.Video
    @State var isVisible: Bool = true

    var body: some View {
        AVPlayerView(video: video, isVisible: isVisible)
            .onDisappear {
                isVisible = false
            }
            .onAppear {
                isVisible = true
            }
    }
}

@available(iOS 13.0, *)
private struct AVPlayerView: UIViewControllerRepresentable {
    let video: Video
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
        Coordinator(video: video)
    }

    class Coordinator {
        let video: Video
        let player: AVPlayer
        let controller: AVPlayerViewController
        fileprivate var cancellables: Set<AnyCancellable> = []

        init(video: Video) {
            self.video = video
            self.controller = AVPlayerViewController()
            controller.showsPlaybackControls = video.showControls
            controller.allowsPictureInPicturePlayback = false
            controller.videoGravity = video.resizingMode.avPlayerGravity

            let videoAsset = AVURLAsset(url: video.sourceURL)
            let playerItem = AVPlayerItem(asset: videoAsset)

            if video.removeAudio {
                let zeroMix = AVMutableAudioMix()
                zeroMix.inputParameters = videoAsset.tracks(withMediaType: .audio).map { track in
                    let audioInputParams = AVMutableAudioMixInputParameters()
                    audioInputParams.setVolume(0, at: .zero)
                    audioInputParams.trackID = track.trackID
                    return audioInputParams
                }

                playerItem.audioMix = zeroMix
            }

            self.player = AVPlayer(playerItem: playerItem)
            controller.player = self.player

            if let posterImageURL = video.posterImageURL {
                ClipManager.sharedInstance.downloader.enqueue(url: posterImageURL, priority: .high) { [weak self] result in
                    guard let imageData = try? result.get(),
                          let posterImage = UIImage(data: imageData)
                    else {
                        return
                    }

                    DispatchQueue.main.async {
                        self?.updatePosterImage(posterImage)
                    }
                }
            }

            if video.looping {
                NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: controller.player?.currentItem)
                    .receive(on: DispatchQueue.main)
                    .compactMap { $0.object as? AVPlayerItem }
                    .sink { [weak self] playerItem in
                        guard let self = self else { return }
                        self.player.seek(to: .zero)
                        self.player.play()
                    }
                    .store(in: &cancellables)
            }

            if video.allowBackground {
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

            if video.autoPlay {
                controller.player?.play()
            }
        }

        func pause() {
            player.pause()
        }

        fileprivate func updatePosterImage(_ posterImage: UIImage) {

            func removePoster() {
                controller.contentOverlayView?.subviews.forEach {
                    $0.removeFromSuperview()
                }
            }

            func showPoster() {
                let posterImageView = UIImageView(image: posterImage)
                posterImageView.frame = controller.contentOverlayView?.frame ?? .zero
                posterImageView.contentMode = video.resizingMode == .scaleToFill ? .scaleAspectFill : .scaleAspectFit
                posterImageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
                controller.contentOverlayView?.addSubview(posterImageView)
            }

            func isPosterVisible() -> Bool {
                guard let contentOverlayView = controller.contentOverlayView else { return false }
                return !contentOverlayView.subviews.isEmpty
            }

            guard let player = controller.player else { return }

            showPoster()

            player.publisher(for: \.timeControlStatus)
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { status in
                    if isPosterVisible(), status == .playing {
                        removePoster()
                    }
                }
                .store(in: &cancellables)
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

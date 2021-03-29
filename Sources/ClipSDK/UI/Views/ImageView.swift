// Copyright (c) 2020-present, Rover Labs, Inc. All rights reserved.
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Rover.
//
// This copyright notice shall be included in all copies or substantial portions of 
// the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import SwiftUI
import ClipModel
import os.log

@available(iOS 13.0, *)
struct ImageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dataItem) private var dataItem
    
    var image: ClipModel.Image
    
    var body: some View {
        ImageFetcherHost(image: image, dataItem: dataItem)
            // in lieu of .onChange(), use this outer view with a .id() modifier to ensure the image is re-evaluated when the colorScheme changes.
            .id(colorScheme)
    }
}

@available(iOS 13.0, *)
private struct ImageFetcherHost: View {
    private let image: ClipModel.Image
    
    @State private var fetcher: ImageFetcher
        
    init(image: ClipModel.Image, dataItem: DataItem?) {
        self.image = image
        self._fetcher = State(wrappedValue: ImageFetcher(image: image, dataItem: dataItem))
    }
        
    var body: some View {
        ImageFromFetcher(image: image, fetcher: fetcher)
    }
}

@available(iOS 13.0, *)
private struct ImageFromFetcher: View {
    let image: ClipModel.Image
    @ObservedObject var fetcher: ImageFetcher
    
    @Environment(\.colorScheme) private var colorScheme
    
    /// A debugging feature to force the image to be always displayed as a blurhash.
    private let alwaysShowBlurhash = false
    
    /// A clear, dummy view that mimics the sizing behaviour of the image.
    @ViewBuilder
    private var dummyView: some View {
        switch image.resizingMode {
        case .originalSize:
            SwiftUI.Rectangle().fill(Color.clear)
                .frame(
                    width: image.estimatedImageScaledFrameWidth(darkMode: self.colorScheme == .dark),
                    height: image.estimatedImageScaledFrameHeight(darkMode: self.colorScheme == .dark)
                )
        case .scaleToFill:
            SwiftUI.Rectangle().fill(Color.clear)
        case .scaleToFit:
            SwiftUI.Rectangle().fill(Color.clear)
                .aspectRatio(image.estimatedImageAspectRatio(darkMode: self.colorScheme == .dark), contentMode: ContentMode.fit)
        case .tile:
            SwiftUI.Rectangle().fill(Color.clear)
        case .stretch:
            SwiftUI.Rectangle().fill(Color.clear)
        }
    }
    
    @ViewBuilder
    private var redactedView: some View {
        if #available(iOS 14.0, *) {
            dummyView
                .redacted(reason: .placeholder)
        } else {
            dummyView
        }
    }
    
    @ViewBuilder
    var body: some View {
        Group {
            if let image = fetcher.image(darkMode: colorScheme == .dark), !alwaysShowBlurhash {
                if image.isAnimated {
                    animatedImage(uiImage: image)
                        .transition(.opacity)
                } else {
                    staticImage(uiImage: image)
                        .transition(.opacity)
                }
            } else {
                blurhash.transition(.opacity)
                    .onAppear {
                        fetcher.startFetch(darkMode: colorScheme == .dark)
                    }
            }
        }
    }
    
    @ViewBuilder
    private func staticImage(uiImage: UIImage) -> some View {
        switch image.resizingMode {
        case .originalSize:
            SwiftUI.Image(uiImage: uiImage)
                .resizable()
                .frame(
                    width: image.estimatedImageScaledFrameWidth(darkMode: colorScheme == .dark) ?? (uiImage.size.width / (!image.resolution.isZero ? image.resolution : 1)),
                    height: image.estimatedImageScaledFrameHeight(darkMode: colorScheme == .dark) ?? (uiImage.size.height / (!image.resolution.isZero ? image.resolution : 1))
                )
        case .scaleToFill:
                SwiftUI.Rectangle().fill(Color.clear)
                    .overlay(
                        SwiftUI.Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    ).clipped()
        case .scaleToFit:
            SwiftUI.Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        case .tile:
            TilingImage(uiImage: uiImage, resolution: image.resolution)
        case .stretch:
            SwiftUI.Image(uiImage: uiImage)
                .resizable()
        }
    }
    
    @ViewBuilder
    private func animatedImage(uiImage: UIImage) -> some View {
        switch image.resizingMode {
        case .originalSize:
            AnimatedImageView(uiImage: uiImage, contentMode: .center)
                .frame(
                    width: uiImage.size.width / image.resolution,
                    height: uiImage.size.height / image.resolution
                )
        case .scaleToFit:
            AnimatedImageView(uiImage: uiImage, contentMode: .scaleAspectFit)
                .scaledToFit()
        case .scaleToFill:
            AnimatedImageView(uiImage: uiImage, contentMode: .scaleAspectFill)
                .scaledToFill()
        case .tile:
            // Tiling animated images is not supported -- fallback to static image.
            TilingImage(uiImage: uiImage, resolution: image.resolution)
        case .stretch:
            AnimatedImageView(uiImage: uiImage, contentMode: .scaleToFill)
        }
    }
    
    func blurhashSize(width: Int, height: Int) -> CGSize {
        // the blurhash algorithm is extremely expensive in unoptimized/debug builds (unoptimized Swift is sometimes hundreds of times slower), so backing off the resolution of rendered blurhashes in debug builds is very helpful.
        #if DEBUG
        // make the image 100x smaller. since it's blurry anyway and then gets scaled back up, there isn't much loss of fidelity.
        return CGSize(width: width / 10, height: height / 10)
        #else
        return CGSize(width: width, height: height)
        #endif
    }
    
    @ViewBuilder
    private var blurhash: some View {
        if colorScheme == .dark {
            if let blurhash = image.darkModeBlurHash ?? image.blurHash, let imageWidth = image.darkModeImageWidth ?? image.imageWidth, let imageHeight = image.darkModeImageHeight ?? image.imageHeight, let uiImage = UIImage(blurHash: blurhash, size: blurhashSize(width: imageWidth, height: imageHeight)) {
                staticImage(uiImage: uiImage)
            } else {
                redactedView
            }
        } else {
            if let blurhash = image.blurHash, let imageWidth = image.imageWidth, let imageHeight = image.imageHeight, let uiImage = UIImage(blurHash: blurhash, size: blurhashSize(width: imageWidth, height: imageHeight)) {
                staticImage(uiImage: uiImage)
            } else {
                redactedView
            }
        }
    }
}

@available(iOS 13.0, *)
private class ImageFetcher: ObservableObject {
    private let image: ClipModel.Image
    private let dataItem: DataItem?
    
    init(image: ClipModel.Image, dataItem: DataItem?) {
        self.image = image
        self.dataItem = dataItem
    }
    
    private enum State: Equatable {
        case loading
        case loaded(uiImage: UIImage)
        case failed
    }
    
    @Published private var state: State = .loading
    
    /// False if still loading (or, already successfully loaded).
    var failed: Bool {
        return state == .failed
    }
    
    func image(darkMode: Bool) -> UIImage? {
        let url: URL
        switch (darkMode, image.darkModeImageURL) {
        case (true, let darkModeImageURL?):
            if let override = image.overrides["darkModeValue"],
               let overriddenURL = dataItem?[override.dataKey] as? URL {
                url = overriddenURL
            } else {
                if let darkModeImage = image.darkModeInlineImage {
                    return darkModeImage
                }
                
                url = darkModeImageURL
            }
        default:
            if let override = image.overrides["defaultValue"],
               let overriddenURL = dataItem?[override.dataKey] as? URL {
                url = overriddenURL
            } else {
                if let image = image.inlineImage {
                    return image
                }
                
                url = image.imageURL
            }
        }
        
        // first, if this image was already loaded, then return it.
        if case let State.loaded(uiImage) = state {
            return uiImage
        }
        
        // secondly, look in the image cache for an already decoded and in-memory copy.        
        if let cachedImage = ClipManager.sharedInstance.imageCache.object(forKey: url as NSURL) {
            return cachedImage
        }
        
        // thirdly, look in the HTTP cache for already downloaded copy if this is a smaller image, in order to avoid the async path (with a delay and animation) if an unexpired copy is present in the cache.
        if let cacheEntry = ClipManager.sharedInstance.assetsURLCache.cachedResponse(for: URLRequest(url: url)) {
            // when displaying the image directly from the cache, then just decode it synchronously on the main thread, blocking rendering: this is desirable to avoid a bit of async state for occurring while waiting for a decode to complete. The tradeoff changes for larger images (especially things like animated GIFs) which we'll fall back to decoding asynchronously on a background queue.
            if cacheEntry.data.count < 524288 {
                if let decoded = cacheEntry.data.loadUIImage() {
                    self.state = .loaded(uiImage: decoded)
                    ClipManager.sharedInstance.imageCache.setObject(decoded, forKey: url as NSURL)
                    return decoded
                } else {
                    clip_log(.error, "Failed to decode presumably corrupted cached image data. Removing it to allow for re-fetch.")
                    ClipManager.sharedInstance.urlCache.removeCachedResponse(for: URLRequest(url: url))
                }
            }
        }
        return nil
    }
    
    func startFetch(darkMode: Bool) {
        guard state == .loading else {
            return
        }
        
        let url: URL
        switch (darkMode, image.darkModeImageURL) {
        case (true, let darkModeImageURL?):
            if let override = image.overrides["darkModeValue"],
               let overriddenURL = dataItem?[override.dataKey] as? URL {
                url = overriddenURL
            } else {
                url = darkModeImageURL
            }
        default:
            if let override = image.overrides["defaultValue"],
               let overriddenURL = dataItem?[override.dataKey] as? URL {
                url = overriddenURL
            } else {
                url = image.imageURL
            }
        }
      
        func setState(_ state: State) {
            DispatchQueue.main.async {
                withAnimation {
                    self.state = state
                }
            }
        }
        
        ClipManager.sharedInstance.downloader.enqueue(url: url, priority: .high) { result in
            switch result {
            case let .failure(error):
                clip_log(.error, "Failed to fetch image data: %@", (error as NSError).userInfo.debugDescription)
                setState(.failed)
                return
            case let .success(data):
                ClipManager.sharedInstance.imageFetchAndDecodeQueue.async {
                    guard let decoded = data.loadUIImage() else {
                        clip_log(.error, "Failed to decode image data.")
                        setState(.failed)
                        return
                    }

                    DispatchQueue.main.async {
                        ClipManager.sharedInstance.imageCache.setObject(decoded, forKey: url as NSURL)
                    }
                    setState(.loaded(uiImage: decoded))
                }
            }
        }
    }
}

@available(iOS 13.0, *)
private extension Data {
    func loadUIImage() -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, nil) else {
            return nil
        }

        let animated = CGImageSourceGetCount(imageSource) > 1

        if !animated {
            guard let uiImage = UIImage(data: self, scale: 1.0) else {
                return nil
            }
            return uiImage
        }
        
        var images: [UIImage] = []
        var duration: Double = 0
        
        for imageIdx in 0..<CGImageSourceGetCount(imageSource) {
            if let cgImage = CGImageSourceCreateImageAtIndex(imageSource, imageIdx, nil) {
                images.append(UIImage(cgImage: cgImage, scale: 1.0, orientation: .up))
                duration += imageSource.gifAnimationDelay(imageAtIndex: imageIdx)
            }
        }
        guard let uiImage = UIImage.animatedImage(with: images, duration: duration) else {
            return nil
        }
        
        return uiImage
    }
}

private extension CGImageSource {
    func gifAnimationDelay(imageAtIndex imageIdx: Int) -> Double {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(self, imageIdx, nil) as? [String:Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return 0.05
        }

        if let unclampedDelayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
            return unclampedDelayTime
        } else if let gifDelayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
            return gifDelayTime
        }
        return 0.05
    }
}

private extension UIImage {
    var isAnimated: Bool {
        (self.images?.count).map { $0 > 1 } ?? false
    }
}

@available(iOS 13.0, *)
private extension ClipModel.Image {
    func estimatedImageAspectRatio(darkMode: Bool) -> CGFloat {
        let ratio: CGFloat
        if darkMode {
            ratio = CGFloat(darkModeImageWidth ?? imageWidth ?? 1) / CGFloat(darkModeImageHeight ?? imageHeight ?? 1)
        } else {
            ratio = CGFloat(imageWidth ?? 1) / CGFloat(imageHeight ?? 1)
        }
        guard !ratio.isNaN && !ratio.isInfinite else {
            return 1
        }
        return ratio
    }
    
    func estimatedImageScaledFrameWidth(darkMode: Bool) -> CGFloat? {
        guard resolution != 0 else {
            return nil
        }
        
        if darkMode {
            return darkModeImageWidth.map { CGFloat($0 == 0 ? 1 : $0) / resolution } ?? estimatedImageScaledFrameWidth(darkMode: false)
        } else {
            return imageWidth.map { CGFloat($0 == 0 ? 1 : $0) / resolution }
        }
    }
    
    func estimatedImageScaledFrameHeight(darkMode: Bool) -> CGFloat? {
        guard resolution != 0 else {
            return nil
        }
        
        if darkMode {
            return darkModeImageHeight.map { CGFloat($0 == 0 ? 1 : $0) / resolution } ?? estimatedImageScaledFrameHeight(darkMode: false)
        } else {
            return imageHeight.map { CGFloat($0 == 0 ? 1 : $0) / resolution }
        }
    }
}

@available(iOS 13.0, *)
private struct TilingImage: View {
    var uiImage: UIImage
    
    var resolution: CGFloat
    
    var body: some View {
        // tiling only uses the UIImage scale, it cannot be applied after .scaleEffect. so, generate a suitably large tiled image at the default 1x scale, and then scale the entire results down afterwards.
        if #available(iOS 14.0, *) {
            GeometryReader { geometry in
                SwiftUI.Image(uiImage: uiImage)
                    .resizable(resizingMode: .tile)
                    // make sure enough tile is generated to accommodate the scaleEffect below.
                    .frame(
                        width: geometry.size.width * resolution,
                        height: geometry.size.height * resolution
                    )
                    // then scale it down to the correct size for the resolution.
                    .scaleEffect(CGFloat(1) / resolution, anchor: .topLeading)
            }
        } else {
            // we cannot reliably use GeometryReader in all contexts on iOS 13, so instead, we'll just generate a default amount of tile that will accomodate most situations rather than the exact amount. this will waste some vram.
            SwiftUI.Rectangle()
                .fill(Color.clear)
                .overlay(
                    SwiftUI.Image(uiImage: uiImage)
                        .resizable(resizingMode: .tile)
                        // make sure enough tile is generated to accommodate the scaleEffect below.
                        .frame(
                            width: 600 * resolution,
                            height: 1000 * resolution
                        )
                        // then scale it down to the correct size for the resolution.
                        .scaleEffect(CGFloat(1) / resolution, anchor: .topLeading)
                    ,
                    alignment: .topLeading
                )
                .clipped()
        }
    }
}

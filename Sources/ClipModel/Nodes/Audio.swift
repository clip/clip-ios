import Foundation
import SwiftUI

@available(iOS 13.0, *)
public class Audio: Layer {

    /// Audio URL
    public let sourceURL: URL

    /// When true the audio will begin playing when the Screen is displayed.
    public let autoPlay: Bool

    /// When true the video will loop.
    public let looping: Bool

    /// When true the audio’s audio will continue to play when the app is put in the background.
    public let allowBackground: Bool

    public init(id: String = UUID().uuidString, name: String = "Audio", parent: Node? = nil, children: [Node] = [], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Node? = nil, overlay: Node? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, sourceURL: URL, autoPlay: Bool, looping: Bool, allowBackground: Bool) {
        self.sourceURL = sourceURL
        self.autoPlay = autoPlay
        self.looping = looping
        self.allowBackground = allowBackground
        super.init(id: id, name: name, parent: parent, children: children, ignoresSafeArea: ignoresSafeArea, aspectRatio: aspectRatio, padding: padding, frame: frame, layoutPriority: layoutPriority, offset: offset, shadow: shadow, opacity: opacity, background: background, overlay: overlay, mask: mask, action: action, accessibility: accessibility)
    }

    private enum CodingKeys: String, CodingKey {
        case sourceURL
        case autoPlay
        case looping
        case allowBackground
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sourceURL = try container.decode(URL.self, forKey: .sourceURL)
        autoPlay = try container.decode(Bool.self, forKey: .autoPlay)
        looping = try container.decode(Bool.self, forKey: .looping)
        allowBackground = try container.decode(Bool.self, forKey: .allowBackground)
        try super.init(from: decoder)
    }
}

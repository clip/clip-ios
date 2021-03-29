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

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public final class PageControl: Layer {
    /// The carousel node this Page Control is associated with.
    public var carousel: Carousel?
    /// The color of all non-selected page indicator bullets.
    public let pageIndicatorColor: ColorVariants
    /// The color of the selected page indicator bullet.
    public let currentPageIndicatorColor: ColorVariants
    /// If true, and the associated Carousel lacks more than one page,
    /// hides the page control.
    public let hidesForSinglePage: Bool
    
    public init(id: String = UUID().uuidString, name: String = "PageControl", parent: Node? = nil, children: [Node] = [], overrides: [String: Override], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Node? = nil, overlay: Node? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, carousel: Carousel? = nil, pageIndicatorColor: ColorVariants, currentPageIndicatorColor: ColorVariants, hidesForSinglePage: Bool) {
        self.carousel = carousel
        self.pageIndicatorColor = pageIndicatorColor
        self.currentPageIndicatorColor = currentPageIndicatorColor
        self.hidesForSinglePage = hidesForSinglePage
        super.init(id: id, name: name, parent: parent, children: children, overrides: overrides, ignoresSafeArea: ignoresSafeArea, aspectRatio: aspectRatio, padding: padding, frame: frame, layoutPriority: layoutPriority, offset: offset, shadow: shadow, opacity: opacity, background: background, overlay: overlay, mask: mask, action: action, accessibility: accessibility)
    }
        
    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
        case pageIndicatorColor
        case currentPageIndicatorColor
        case hidesForSinglePage
        case carouselID
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pageIndicatorColor = try container.decode(ColorVariants.self, forKey: .pageIndicatorColor)
        currentPageIndicatorColor = try container.decode(ColorVariants.self, forKey: .currentPageIndicatorColor)
        hidesForSinglePage = try container.decode(Bool.self, forKey: .hidesForSinglePage)

        try super.init(from: decoder)

        if container.contains(.carouselID) {
            let coordinator = decoder.userInfo[.decodingCoordinator] as! DecodingCoordinator
            let carouselID = try container.decode(Node.ID.self, forKey: .carouselID)
            coordinator.registerOneToOneRelationship(nodeID: carouselID, to: self, keyPath: \.carousel)
        }
    }
}


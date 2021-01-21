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

@available(iOS 13.0, *)
public final class Rectangle: Layer {
    public let fill: Fill
    public let border: Border?
    public let cornerRadius: Int
    
    public init(id: String = UUID().uuidString, name: String = "Rectangle", parent: Node? = nil, children: [Node] = [], ignoresSafeArea: Set<Edge>? = nil, aspectRatio: CGFloat? = nil, padding: Padding? = nil, frame: Frame? = nil, layoutPriority: CGFloat? = nil, offset: CGPoint? = nil, shadow: Shadow? = nil, opacity: CGFloat? = nil, background: Node? = nil, overlay: Node? = nil, mask: Node? = nil, action: Action? = nil, accessibility: Accessibility? = nil, fill: Fill, border: Border?, cornerRadius: Int) {
        self.fill = fill
        self.border = border
        self.cornerRadius = cornerRadius
        super.init(id: id, name: name, parent: parent, children: children, ignoresSafeArea: ignoresSafeArea, aspectRatio: aspectRatio, padding: padding, frame: frame, layoutPriority: layoutPriority, offset: offset, shadow: shadow, opacity: opacity, background: background, overlay: overlay, mask: mask, action: action, accessibility: accessibility)
    }
        
    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
        case fill
        case border
        case cornerRadius
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fill = try container.decode(Fill.self, forKey: .fill)
        border = try container.decodeIfPresent(Border.self, forKey: .border)
        cornerRadius = try container.decodeIfPresent(Int.self, forKey: .cornerRadius) ?? 0

        try super.init(from: decoder)
    }
}

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
import os.log

@available(iOS 13.0, *)
struct AnyNode: Decodable {
    let node: Node
    
    private enum CodingKeys: String, CodingKey {
        case typeName = "__typeName"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeName = try container.decode(String.self, forKey: .typeName)
        
        switch typeName {
        case Screen.typeName:
            node = try Screen(from: decoder)
        case HStack.typeName:
            node = try HStack(from: decoder)
        case Image.typeName:
            node = try Image(from: decoder)
        case Text.typeName:
            node = try Text(from: decoder)
        case Rectangle.typeName:
            node = try Rectangle(from: decoder)
        case ScrollContainer.typeName:
            node = try ScrollContainer(from: decoder)
        case Spacer.typeName:
            node = try Spacer(from: decoder)
        case Divider.typeName:
            node = try Divider(from: decoder)
        case VStack.typeName:
            node = try VStack(from: decoder)
        case WebView.typeName:
            node = try WebView(from: decoder)
        case ZStack.typeName:
            node = try ZStack(from: decoder)
        case Carousel.typeName:
            node = try Carousel(from: decoder)
        case PageControl.typeName:
            node = try PageControl(from: decoder)
        default:
            clip_log(.error, "Unsupported Node type: %@", typeName)
            node = Rectangle(name: "Rectangle", fill: .flat(.clear), border: nil, cornerRadius: 0)
        }
    }
}

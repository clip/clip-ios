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

@available(iOS 13.0, *)
public enum ButtonItem: Decodable {
    case done
    case close
    case label(text: String, action: Action)
    case glyph(icon: Icon, action: Action)
    
    private enum CodingKeys: String, CodingKey {
        case __typeName
        case text
        case icon
        case action
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        switch try container.decode(String.self, forKey: .__typeName) {
        case "DoneButtonItem":
            self = .done
        case "CloseButtonItem":
            self = .close
        case "LabelButtonItem":
            self = .label(
                text: try container.decode(String.self, forKey: .text),
                action: try container.decode(Action.self, forKey: .action)
            )
        case "GlyphButtonItem":
            self = .glyph(
                icon: try container.decode(Icon.self, forKey: .icon),
                action: try container.decode(Action.self, forKey: .action)
            )
        default:
            throw UnsupportedButtonType(type: try container.decode(String.self, forKey: .__typeName))
        }
    }
}

private struct UnsupportedButtonType: Error, LocalizedError {
    var type: String
    
    var errorDescription: String? {
        "Unsupported ButtonItem type: \(type)"
    }
}

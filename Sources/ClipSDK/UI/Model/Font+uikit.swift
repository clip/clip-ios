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

import ClipModel
import Foundation
import UIKit
import SwiftUI

@available(iOS 13.0, *)
extension ClipModel.Font {
    var uikitFont: UIFont? {
        switch self {
        case .dynamic(let textStyle):
            return UIFont.preferredFont(forTextStyle: textStyle.uiTextStyle)
        case .fixed(let size, let weight):
            let scaledSize = UIFontMetrics.default.scaledValue(for: size)
            return UIFont.systemFont(ofSize: scaledSize, weight: weight.uiWeight)
        case .custom(let fontName, let size, let isDynamic):
            let font: UIFont?
            if isDynamic {
                let scaledSize = UIFontMetrics.default.scaledValue(for: size)
                font = UIFont(name: fontName, size: scaledSize)
            } else {
                font = UIFont(name: fontName, size: size)
            }

            if font == nil {
                clip_log(.debug, "Missing font %@", fontName)
            }
            return font
        }
    }
}

@available(iOS 13.0, *)
extension SwiftUI.Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
            case .largeTitle:
                return .largeTitle
            case .title:
                return .title1
            case .title2:
                return .title2
            case .title3:
                return .title3
            case .headline:
                return .headline
            case .subheadline:
                return .subheadline
            case .body:
                return .body
            case .callout:
                return .callout
            case .footnote:
                return .footnote
            case .caption:
                return .caption1
            case .caption2:
                return .caption2
            @unknown default:
                return .body
        }
    }
}

@available(iOS 13.0, *)
extension SwiftUI.Font.Weight {
    var uiWeight: UIFont.Weight {
        switch self {
            case .black:
                return .black
            case .bold:
                return .bold
            case .heavy:
                return .heavy
            case .light:
                return .light
            case .medium:
                return .medium
            case .regular:
                return .regular
            case .semibold:
                return .semibold
            case .thin:
                return .thin
            case .ultraLight:
                return .ultraLight
            default:
                return .regular
        }
    }
}

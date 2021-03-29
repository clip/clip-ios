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

@available(iOS 13.0, *)
struct TextView: View {
    @Environment(\.dataItem) private var dataItem
    @Environment(\.stringTable) private var stringTable
    
    var text: ClipModel.Text
    
    var body: some View {
        RealizeColor(text.textColor) { textColor in
            SwiftUI.Text(transformed(stringTable.resolve(key: resolvedText)))
            .modifier(
                FontModifier(font: text.font)
            )
            .foregroundColor(textColor)
            .multilineTextAlignment(uiTextAlignment)
            .lineLimit(text.lineLimit)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var resolvedText: String {        
        if let override = text.overrides["text"] {
            if let text = dataItem?[override.dataKey] as? String {
                return text
            } else if let date = dataItem?[override.dataKey] as? Date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = override.dateFormat
                return dateFormatter.string(from: date)
            } else if let number = dataItem?[override.dataKey] as? Double {
                return NumberFormatter().string(from: number as NSNumber) ?? text.text
            } else {
                return text.text
            }
        } else {
            return text.text
        }
    }
    
    private func transformed(_ text: String) -> String {
        switch self.text.transform {
        case .lowercase:
            return text.lowercased()
        case .uppercase:
            return text.uppercased()
        case .none:
            return text
        }
    }
    
    private var uiTextAlignment: SwiftUI.TextAlignment {
        switch text.textAlignment {
        case .center:
            return .center
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        }
    }
}

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
struct ScrollContainerView: View {
    var scrollContainer: ScrollContainer
    
    var body: some View {
        ScrollView(axis, showsIndicators: !scrollContainer.disableScrollBar) {
            switch scrollContainer.axis {
            case .horizontal:
                SwiftUI.HStack(spacing: 0) {
                    ForEach(orderedLayers) {
                        LayerView(layer: $0)
                    }
                }
            case .vertical:
                SwiftUI.VStack(spacing: 0) {
                    ForEach(orderedLayers) {
                        LayerView(layer: $0)
                    }
                }
            }
        }
    }
    
    private var axis: Axis.Set {
        switch scrollContainer.axis {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
    
    private var orderedLayers: [Layer] {
        scrollContainer.children.compactMap { $0 as? Layer }
    }
}

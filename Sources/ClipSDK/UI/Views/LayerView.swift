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
struct LayerView: View {
    var layer: Layer
    
    var body: some View {
        content
            .modifier(
                AspectRatioModifier(node: layer)
            )
            .modifier(
                PaddingModifier(node: layer)
            )
            .modifier(
                FrameModifier(node: layer)
            )
            .modifier(
                LayoutPriorityModifier(node: layer)
            )
            .modifier(
                ShadowModifier(node: layer)
            )
            .modifier(
                OpacityModifier(node: layer)
            )
            .modifier(
                BackgroundModifier(node: layer)
            )
            .modifier(
                OverlayModifier(node: layer)
            )
            .modifier(
                MaskModifier(node: layer)
            )
            .contentShape(
                SwiftUI.Rectangle()
            )
            .modifier(
                AccessibilityModifier(node: layer)
            )
            .modifier(
                ActionModifier(layer: layer)
            )
            .modifier(
                OffsetModifier(node: layer)
            )
            .modifier(
                IgnoresSafeAreaModifier(node: layer)
            )
    }
    
    @ViewBuilder private var content: some View {
        switch layer {
        case let scrollContainer as ClipModel.ScrollContainer:
            ScrollContainerView(scrollContainer: scrollContainer)
        case let stack as ClipModel.HStack:
            HStackView(stack: stack)
        case let image as ClipModel.Image:
            ImageView(image: image)
        case let text as ClipModel.Text:
            TextView(text: text)
        case let rectangle as ClipModel.Rectangle:
            RectangleView(rectangle: rectangle)
        case let stack as ClipModel.VStack:
            VStackView(stack: stack)
        case _ as ClipModel.Spacer:
            SwiftUI.Spacer().frame(minWidth: 0, minHeight: 0).layoutPriority(-1)
        case let divider as ClipModel.Divider: 
            DividerView(divider: divider)
        case let webView as ClipModel.WebView:
            WebViewView(webView: webView)
                .environment(\.isEnabled, false)
        case let stack as ClipModel.ZStack:
            ZStackView(stack: stack)
        case let carousel as ClipModel.Carousel:
            CarouselView(carousel: carousel)
        case let pageControl as ClipModel.PageControl:
            PageControlView(pageControl: pageControl)
        case let video as ClipModel.Video:
            VideoView(video: video)
        case let audio as ClipModel.Audio:
            AudioView(audio: audio)
        default:
            EmptyView()
        }
    }
}


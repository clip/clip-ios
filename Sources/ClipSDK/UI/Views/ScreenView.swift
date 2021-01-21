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
public struct ScreenView: View {
    var screen: Screen
    
    /// Set this to
    var skipRootScrollView: Bool
    
    @State private var carouselState = CarouselState()
    
    @ViewBuilder
    var backgroundContents: some View {
        RealizeColor(screen.backgroundColor) { backgroundColor in
            if skipRootScrollView {
                Color.clear
            } else {
                backgroundColor.edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    var contents: some View {
        SwiftUI.ZStack {
            ForEach(orderedLayers) {
                LayerView(layer: $0)
            }
        }
        .background(backgroundContents)
        .environmentObject(carouselState)
    }
    
    public var body: some View {
        // allows for ScreenView to be used outside of ScreenViewController.
        if let navBarAppearance = screen.navBarAppearance {
            contents
                .environment(\.navBarAppearance, navBarAppearance)
        } else {
            contents
        }
    }
    
    private var orderedLayers: [Layer] {
        if skipRootScrollView, let scrollContainer = screen.children.first as? ScrollContainer {
            return scrollContainer.children.compactMap { $0 as? Layer }.reversed()
        } else {
            return screen.children.compactMap { $0 as? Layer }.reversed()
        }
    }
}

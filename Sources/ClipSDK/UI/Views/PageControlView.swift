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
struct PageControlView: View {
    var pageControl: PageControl
    
    @EnvironmentObject private var carouselState: CarouselState
    
    var body: some View {
        RealizeColor(pageControl.pageIndicatorColor) { pageIndicatorColor in
            RealizeColor(pageControl.currentPageIndicatorColor) { currentPageIndicatorColor in
                PageControlViewBody(
                    numberOfPages: pageControl.carousel?.children.count ?? 0,
                    currentPage: Binding {
                        carouselState.currentPageForCarousel[pageControl.carousel?.id ?? ""] ?? 0
                    } set: { pageIndex in
                        if let id = pageControl.carousel?.id {
                            carouselState.currentPageForCarousel[id] = pageIndex
                        }
                    },
                    hidesForSinglePage: pageControl.hidesForSinglePage,
                    pageIndicatorColor: pageIndicatorColor,
                    currentPageIndicatorColor: currentPageIndicatorColor
                )
            }
        }
    }
}

@available(iOS 13.0, *)
private struct PageControlViewBody: UIViewRepresentable {
    var numberOfPages: Int
    @Binding var currentPage: Int
    var hidesForSinglePage: Bool
    var pageIndicatorColor: UIColor
    var currentPageIndicatorColor: UIColor
    
    func makeCoordinator() -> Coordinator {
        Coordinator(currentPage: $currentPage)
    }

    func makeUIView(context: Context) -> UIPageControl {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = numberOfPages
        pageControl.hidesForSinglePage = hidesForSinglePage
        pageControl.pageIndicatorTintColor = pageIndicatorColor
        pageControl.currentPageIndicatorTintColor = currentPageIndicatorColor
        
        pageControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.updateCurrentPage(sender:)),
            for: .valueChanged
        )
        
        return pageControl
    }

    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.currentPage = currentPage
    }

    class Coordinator: NSObject {
        @Binding var currentPage: Int

        init(currentPage: Binding<Int>) {
            _currentPage = currentPage
        }
        
        @objc func updateCurrentPage(sender: UIPageControl) {
            currentPage = sender.currentPage
        }
    }
}

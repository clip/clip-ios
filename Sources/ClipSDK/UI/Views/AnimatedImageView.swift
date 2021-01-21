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
import UIKit

@available(iOS 13.0, *)
struct AnimatedImageView: UIViewRepresentable {
    let uiImage: UIImage
    
    let contentMode: UIImageView.ContentMode

    func makeUIView(context: Context) -> UIView {

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.clipsToBounds = true
        imageView.contentMode = contentMode
        imageView.animationImages = uiImage.images
        imageView.animationDuration = uiImage.duration
        imageView.startAnimating()
        return imageView
    }

    func updateUIView(_ view: UIView, context: Context) {

    }
}

private final class ScaledImageView: UIImageView {
    override var intrinsicContentSize: CGSize {
        guard let image = self.image ?? self.animationImages?.first else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        
        let scaledWidth = image.size.width / image.scale
        let scaledHeight = image.size.height / image.scale

        return CGSize(width: scaledWidth, height: scaledHeight)
    }
}

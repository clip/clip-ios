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
import UIKit
import SafariServices
import os.log

@available(iOS 13.0, *)
extension Action {
    func handle(document: Document, show: (UIViewController) -> Void, present: (UIViewController) -> Void, dismiss: () -> Void, dataItem: DataItem?, overrides: [String: Override]) {
        switch(self.actionType) {
        case .performSegue:
            guard let screen = self.screen else {
                return
            }
            
            switch segueStyle {
            case .modal:
                let viewController = ClipManager.sharedInstance.navBarViewController(document, screen, dataItem)
                switch modalPresentationStyle {
                case .sheet:
                    viewController.modalPresentationStyle = .pageSheet
                case .fullScreen:
                    viewController.modalPresentationStyle = .fullScreen
                default:
                    break
                }
                
                present(viewController)
            default:
                let viewController = ClipManager.sharedInstance.screenViewController(document, screen, dataItem)
                show(viewController)
            }
        case .openURL:
            let resolvedURL: URL
            if let override = overrides["url"],
               let url = dataItem?.rawValue[override.dataKey] as? URL {
                resolvedURL = url
            } else if let url = self.url {
                resolvedURL = url
            } else {
                return
            }
            
            UIApplication.shared.open(resolvedURL) { success in
                if !success {
                    clip_log(.error, "Unable to present unhandled URL: %@", resolvedURL.absoluteString)
                }
            }
        case .presentWebsite:
            let resolvedURL: URL
            if let override = overrides["url"],
               let url = dataItem?.rawValue[override.dataKey] as? URL {
                resolvedURL = url
            } else if let url = self.url {
                resolvedURL = url
            } else {
                return
            }
            
            let viewController = SFSafariViewController(url: resolvedURL)
            present(viewController)
        case .close:
            dismiss()
        }
    }
}

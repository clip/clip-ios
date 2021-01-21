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

import UIKit
import ClipSDK
import os.log

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        // handle universal links.
        if let userActivity = connectionOptions.userActivities.first,
           userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let incomingURL = userActivity.webpageURL,
           let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
           components.host == "myapp.clip.app" {
            
            // open the Clip:
            let clipViewController = ClipViewController(url: incomingURL)
            // present on top of the view controller you already have configured (eg. in a storyboard):
            DispatchQueue.main.async {
                self.window?.rootViewController?.present(clipViewController, animated: true)
            }
        }
        
        // handle deep link (when app starting from cold).
        if let urlContext = connectionOptions.urlContexts.first, let components = NSURLComponents(url: urlContext.url, resolvingAgainstBaseURL: true), components.scheme == "myapp", components.host == "openClip", let clipURLString = components.queryItems?.first(where: { $0.name == "url" })?.value, let clipURL = URL(string: clipURLString) {
            
            // open the Clip:
            let clipViewController = ClipViewController(url: clipURL)
            // present on top of the view controller you already have configured (eg. in a storyboard):
            DispatchQueue.main.async {
                self.window!.rootViewController!.present(clipViewController, animated: false)
            }
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // handle deep link if app already open.
        if let urlContext = URLContexts.first, let components = NSURLComponents(url: urlContext.url, resolvingAgainstBaseURL: true), components.scheme == "myapp", components.host == "openClip", let clipURLString = components.queryItems?.first(where: { $0.name == "url" })?.value, let clipURL = URL(string: clipURLString) {
            
            let clipViewController = ClipViewController(url: clipURL)
            
            self.window?.rootViewController?.present(clipViewController, animated: false)
        }
    }
}


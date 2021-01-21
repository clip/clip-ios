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
import SwiftUI
import ClipModel
import os.log

@available(iOS 13.0, *)
open class NavBarViewController: UINavigationController {
    let document: Document

    let screen: Screen
    
    let navBarAppearance: NavBarAppearance?
    
    private let screenViewController: ScreenViewController
    
    public init(document: Document, screen: Screen, navBarAppearance: NavBarAppearance?) {
        self.document = document
        self.screen = screen
        self.navBarAppearance = navBarAppearance
        screenViewController = ClipManager.sharedInstance.screenViewController(document, screen, navBarAppearance)
        super.init(nibName: nil, bundle: nil)
        self.restorationIdentifier = screen.id
        
        self.navigationBar.prefersLargeTitles = true
        
        switch self.screen.modalPresentationStyle {
        case .sheet:
            self.modalPresentationStyle = .pageSheet
        case .fullScreen:
            self.modalPresentationStyle = .fullScreen
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.show(screenViewController, sender: nil)
    }

    open override var childForStatusBarStyle: UIViewController? {
        visibleViewController
    }

    open override var childForStatusBarHidden: UIViewController? {
        visibleViewController
    }

    required public init?(coder: NSCoder) {
        fatalError("Clip's NavBarViewController is not supported in Interface Builder or Storyboards.")
    }
}

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
import ClipModel
import os.log

/// Use this View Controller to present Clips to the user.
///
/// - Tag: ClipViewController
open class ClipViewController: UIViewController {

    /// Initialize Clip View Controller for an Clip URL
    /// - Parameters:
    ///   - url: Clip URL
    ///   - ignoreCache: Optional. Ignore cached Clip, if any.
    public init(url: URL, ignoreCache: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        
        guard #available(iOS 13.0, *) else {
            return
        }
        
        var clipURL: URL = url
        var requestedInitialScreenID: Screen.ID? = nil
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let screenID = urlComponents.queryItems?.first(where: { $0.name.uppercased() == "screenID".uppercased() })?.value
        {
            requestedInitialScreenID = screenID
            
            urlComponents.query = nil
            clipURL = urlComponents.url!
        }
        
        if !ignoreCache, let document = ClipManager.sharedInstance.urlCache.cachedClip(url: clipURL) {
            loadClip(document: document, initialScreenID: requestedInitialScreenID ?? document.initialScreenID)
            return
        }
        
        retrieveClip(url: clipURL, ignoreCache: ignoreCache, initialScreenID: requestedInitialScreenID)
    }
    
    @available(iOS 13.0, *)
    private func retrieveClip(url: URL, ignoreCache: Bool = false, initialScreenID: Screen.ID?) {
        // TODO: needs visual async state while waiting for loading.
        ClipManager.sharedInstance.repository.retrieveClip(url: url, ignoreCache: ignoreCache) { result in
            switch result {
            case .failure(let error):
                clip_log(.error, "Error while trying to launch Clip: %@", error.debugDescription)
                
                if let recoverableError = error as? RecoverableError, recoverableError.canRecover {
                    self.presentRetrieveRetryDialog() {
                        self.retrieveClip(url: url, initialScreenID: initialScreenID)
                    }
                } else {
                    self.presentRetrieveErrorDialog()
                }
            case .success(let document):
                self.loadClip(document: document, initialScreenID: initialScreenID ?? document.initialScreenID)
            }
        }
    }
    
    open override func loadView() {
        if #available(iOS 13.0, *) {
            super.loadView()
        } else {
            super.loadView()
            self.view.backgroundColor = .white
            
            let title = UILabel()
            title.text = NSLocalizedString("iOS 13+ Required", bundle: Bundle.module, comment: "Clip upgrade operating system message title")
            title.font = UIFont.boldSystemFont(ofSize: 18)
            title.textAlignment = .center
            
            let explanation = UILabel()
            explanation.text = NSLocalizedString("Please update your operating system to view this content.", bundle: Bundle.module, comment: "Clip upgrade operating system CTA")
            explanation.numberOfLines = 0
            explanation.textAlignment = .center
            explanation.textColor = .black
            
            let closeButton = UIButton()
            closeButton.setTitle(NSLocalizedString("OK", bundle: Bundle.module, comment: "Clip OK action"), for: .normal)
            closeButton.setTitleColor(.blue, for: .normal)
            closeButton.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
            let stackView = UIStackView(arrangedSubviews: [title, explanation, closeButton])
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.spacing = 16
            
            self.view.addSubview(stackView)
            self.view.centerYAnchor.constraint(equalTo: stackView.centerYAnchor).isActive = true
            self.view.centerXAnchor.constraint(equalTo: stackView.centerXAnchor).isActive = true
            explanation.widthAnchor.constraint(lessThanOrEqualToConstant: 240).isActive = true
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor).isActive = true
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor).isActive = true
        }
    }
    
    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    /// Initialize Clip View Controller with a `Document`
    /// - Parameters:
    ///   - document: `Document` instance
    ///   - screenID: Optional. Override document's initial screen identifier.
    @available(iOS 13.0, *)
    public init(document: Document, screenID initialScreenID: Screen.ID? = nil) {
        super.init(nibName: nil, bundle: nil)
        loadClip(document: document, initialScreenID: initialScreenID ?? document.initialScreenID)
    }

    required public init?(coder: NSCoder) {
        fatalError("ClipViewController is not supported in Interface Builder or Storyboards.")
    }
    
    @available(iOS 13.0, *)
    private func loadClip(document: Document, initialScreenID: Screen.ID) {
        // determine which root container is on the path to the initial screen:
        let matchingScreen = document.nodes.first(where: { $0.id == initialScreenID }) as? Screen
        
        guard let initialScreen = matchingScreen ?? document.nodes.first(where: { $0 is Screen }) as? Screen else {
            clip_log(.error, "No screen to start the Clip from. Giving up.")
            return
        }

        // Register document fonts
        document.fonts.forEach { url in
            ClipManager.sharedInstance.downloader.enqueue(url: url, priority: .high) { result in
                do {
                    try self.registerFontIfNeeded(data: result.get())
                } catch {
                    clip_log(.error, "Document Font: ", error.localizedDescription)
                }
            }
        }

        let navViewController = ClipManager.sharedInstance.navBarViewController(document, initialScreen, nil)
        
        self.restorationIdentifier = "\(document.id)"
        self.setChildViewController(navViewController)
    }

    private func registerFontIfNeeded(data: Data) throws {
        struct FontRegistrationError: Swift.Error, LocalizedError {
            let message: String

            var errorDescription: String? {
                message
            }
        }

        guard let fontProvider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(fontProvider),
              let fontName = cgFont.postScriptName as String?
        else {
            throw FontRegistrationError(message: "Unable to register font from provided data.")
        }

        let queryCollection = CTFontCollectionCreateWithFontDescriptors(
            [
                CTFontDescriptorCreateWithAttributes(
                    [kCTFontNameAttribute: fontName] as CFDictionary
                )
            ] as CFArray, nil
        )

        let fontExists = (CTFontCollectionCreateMatchingFontDescriptors(queryCollection) as? [CTFontDescriptor])?.isEmpty == false
        if !fontExists {
            if !CTFontManagerRegisterGraphicsFont(cgFont, nil) {
                throw FontRegistrationError(message: "Unable to register font: \(fontName)")
            }

            NotificationCenter.default.post(name: .clipDidRegisterCustomFont, object: fontName)
        }
    }

    private func presentRetrieveRetryDialog(retry: @escaping () -> Void) {
        let alertController: UIAlertController

        alertController = UIAlertController(
            title: NSLocalizedString("Error", bundle: Bundle.module, comment: "Clip Error Dialog title"),
            message: NSLocalizedString("Failed to load Clip", bundle: Bundle.module, comment: "Clip Failed to load Clip error message"),
            preferredStyle: UIAlertController.Style.alert
        )
        let cancel = UIAlertAction(
            title: NSLocalizedString("Cancel", bundle: Bundle.module, comment: "Clip Cancel Action"),
            style: UIAlertAction.Style.cancel
        ) { _ in
            alertController.dismiss(animated: true) {
                self.dismiss(animated: true, completion: nil)
            }
        }
        let retry = UIAlertAction(
            title: NSLocalizedString("Try Again", bundle: Bundle.module, comment: "Clip Try Again Action"),
            style: UIAlertAction.Style.default
        ) { _ in
            alertController.dismiss(animated: true, completion: nil)

            retry()
        }

        alertController.addAction(cancel)
        alertController.addAction(retry)

        present(alertController, animated: true, completion: nil)
    }

    private func presentRetrieveErrorDialog() {
        let alertController = UIAlertController(
            title: NSLocalizedString("Error", bundle: Bundle.module, comment: "Clip Error Title"),
            message: NSLocalizedString("Something went wrong", bundle: Bundle.module, comment: "Clip Something Went Wrong message"),
            preferredStyle: UIAlertController.Style.alert
        )

        let ok = UIAlertAction(
            title: NSLocalizedString("OK", bundle: Bundle.module, comment: "Clip OK Action"),
            style: UIAlertAction.Style.default
        ) { _ in
            alertController.dismiss(animated: false) {
                self.dismiss(animated: true, completion: nil)
            }
        }

        alertController.addAction(ok)

        present(alertController, animated: true, completion: nil)
    }
    
    private func setChildViewController(_ childViewController: UIViewController) {
        if let existingChildViewController = self.children.first {
            existingChildViewController.willMove(toParent: nil)
            existingChildViewController.view.removeFromSuperview()
            existingChildViewController.removeFromParent()
        }
        
        addChild(childViewController)
        childViewController.view.frame = view.bounds
        view.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
    }

    open override var childForStatusBarStyle: UIViewController? {
        children.first
    }

    open override var childForStatusBarHidden: UIViewController? {
        children.first
    }
}

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
private struct ClipViewControllerRepresentable: UIViewControllerRepresentable {
    var document: Document

    func makeUIViewController(context: Context) -> ClipViewController {
        let vc = ClipViewController(document: document)
        return vc
    }

    func updateUIViewController(_ uiViewController: ClipViewController, context: Context) {

    }
}


@available(iOS 14.0, *)
struct ClipViewController_Previews : PreviewProvider {
    static var previews: some View {
        let document = try! Document(decode: testJSON.data(using: .utf8)!)
        ClipViewControllerRepresentable(document: document)
            .ignoresSafeArea()
            .previewDevice("iPhone 12")
    }

    static let testJSON = """
    {
      "id": 1,
      "clipRevisionID": 1,
      "nodes": [
        {
          "name": "Screen",
          "__typeName": "Screen",
          "id": "7BE71C5F-CE5E-4BC0-8AC1-7388B35862EF",
          "childIDs": [],
          "backgroundColor": {
            "systemName": "systemBackground",
            "default": {
              "red": 1,
              "green": 1,
              "blue": 1,
              "alpha": 1
            },
            "darkMode": {
              "red": 0,
              "green": 0,
              "blue": 0,
              "alpha": 1
            }
          }
        }
      ],
      "screenIDs": [
        "7BE71C5F-CE5E-4BC0-8AC1-7388B35862EF"
      ],
      "initialScreenID": "7BE71C5F-CE5E-4BC0-8AC1-7388B35862EF"
    }
    """
}

#endif

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
import SwiftUI
import Combine

@available(iOS 13.0, *)
open class ScreenViewController: UIViewController, UIScrollViewDelegate {
    let document: Document
    let screen: Screen
    
    private var carouselState = CarouselState()
    private var cancellables: Set<AnyCancellable> = []
    
    public init(document: Document, screen: Screen) {
        self.document = document
        self.screen = screen
        super.init(nibName: nil, bundle: nil)
        super.restorationIdentifier = screen.id
    }
    
    public required init?(coder: NSCoder) {
        fatalError("Clip's ScreenViewController is not supported in Interface Builder or Storyboards.")
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        switch screen.statusBarStyle {
        case .default:
            return .default
        case .light:
            return .lightContent
        case .dark:
            return .darkContent
        case .inverted:
            return traitCollection.userInterfaceStyle == .dark
                ? .darkContent
                : .lightContent
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // Back Button Style
        switch screen.backButtonStyle {
        case .default(let title):
            if #available(iOS 14.0, *) {
                navigationItem.backButtonDisplayMode = .default
            }
            
            navigationItem.backButtonTitle = document.localization.resolve(key: title)
        case .generic:
            if #available(iOS 14.0, *) {
                navigationItem.backButtonDisplayMode = .generic
            }
        case .minimal:
            if #available(iOS 14.0, *) {
                navigationItem.backButtonDisplayMode = .minimal
            }
        }
        
        // Background Color
        view.backgroundColor = screen.backgroundColor.uikitUIColor(
            colorScheme: traitCollection.colorScheme,
            colorSchemeContrast: traitCollection.colorSchemeContrast
        )
        
        showOrHideNavBarIfNeeded()

        self.configureNavBar()
        let cancellable = NotificationCenter.default.publisher(for: .clipDidRegisterCustomFont).sink { _ in
            self.configureNavBar()
        }
        cancellables.insert(cancellable)

        addChildren()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showOrHideNavBarIfNeeded()
        
        if let navBar = navBar {
            navigationController?.navigationBar.adjustTintColor(
                navBar: navBar,
                traits: traitCollection
            )
        }
    }

    private func configureNavBar() {
        if let navBar = navBar {
            navigationItem.configure(
                navBar: navBar,
                stringTable: document.localization,
                traits: traitCollection,
                buttonHandler: navBarButtonTapped
            )
        }
    }
    
    // MARK: - Nav Bar
    
    var navBar: NavBar? {
        screen.children.first { $0 is NavBar } as? NavBar
    }
    
    private func showOrHideNavBarIfNeeded() {
        navigationController?.isNavigationBarHidden = navBar == nil
    }
    
    private func navBarButtonTapped(_ navBarButton: NavBarButton) {
        switch navBarButton.style {
        case .close, .done:
            dismiss(animated: true)
        case .custom:
            navBarButton.action?.handle(
                document: self.document,
                show: {
                    self.show($0, sender: self)
                },
                present: {
                    self.present($0, animated: true)
                },
                dismiss: {
                    self.dismiss(animated: true)
                }
            )
        }
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navBar = navBar, navBar.titleDisplayMode == .inline else {
            return
        }
        
        let isScrolling = scrollView.contentOffset.y + scrollView.adjustedContentInset.top > 0
        navigationItem.configureInlineAppearance(
            navBar: navBar,
            traits: traitCollection,
            isScrolling: isScrolling
        )
        
        navigationController?.navigationBar.adjustTintColor(
            navBar: navBar,
            traits: traitCollection,
            isScrolling: isScrolling
        )
    }
    
    // MARK: - Children
    
    private func addChildren() {
        screen.children.compactMap { $0 as? Layer }.reversed().forEach { layer in
            addLayer(layer)
        }
    }
    
    private func addLayer(_ layer: Layer) {
        let rootView = viewForLayer(layer)
        
        let hostingController = UIHostingController(
            rootView: rootView,
            ignoreSafeArea: true
        )

        addChild(hostingController)

        let view = hostingController.view!
        view.backgroundColor = .clear

        self.view.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        let safeAreaLayoutGuide = self.view.safeAreaLayoutGuide

        if layer.ignoresSafeArea?.contains(.top) == true {
            view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        } else {
            view.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        }

        if layer.ignoresSafeArea?.contains(.leading) == true {
            view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        } else {
            view.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true
        }

        if layer.ignoresSafeArea?.contains(.bottom) == true {
            view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        } else {
            view.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
        }

        if layer.ignoresSafeArea?.contains(.trailing) == true {
            view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        } else {
            view.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
        }

        hostingController.didMove(toParent: self)
    }

    @ViewBuilder
    private func viewForLayer(_ layer: Layer) -> some View {
        if isRootScrollContainer(layer) {
            _viewForLayer(layer)
                .introspectScrollView { scrollView in
                    scrollView.delegate = self
                }
        } else {
            _viewForLayer(layer)
        }
    }
    
    private func _viewForLayer(_ layer: Layer) -> some View {
        LayerView(layer: layer)
            .environment(\.presentAction, { [weak self] viewController in
                self?.present(viewController, animated: true)
            })
            .environment(\.showAction, { [ weak self] viewController in
                self?.show(viewController, sender: self)
            })
            .environment(\.dismiss, { [ weak self] in
                self?.dismiss(animated: true)
            })
            .environmentObject(carouselState)
            .environment(\.document, document)
            .environment(\.stringTable, document.localization)
    }
    
    private func isRootScrollContainer(_ node: Node) -> Bool {
        guard let scrollContainer = node as? ScrollContainer else {
            return false
        }
        
        return scrollContainer.axis == .vertical
            && scrollContainer.aspectRatio == nil
            && scrollContainer.padding == nil
            && scrollContainer.frame == nil
            && scrollContainer.layoutPriority == nil
            && scrollContainer.offset == nil
    }
}

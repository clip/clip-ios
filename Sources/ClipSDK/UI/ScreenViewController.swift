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
import Combine

@available(iOS 13.0, *)
open class ScreenViewController: UIViewController {
    let document: Document
    let screen: Screen
    let navBarAppearance: NavBarAppearance?
    
    private var hostingController: UIHostingController<AnyView>!
    private var scrollView: UIScrollView = UIScrollView()
    private var cancellable: Set<AnyCancellable> = []

    // Standard navigation bar sizes
    private var knownNavigationBarSizes: (collapsed: CGFloat, expanded: CGFloat)?

    public init(document: Document, screen: Screen, navBarAppearance: NavBarAppearance?) {
        self.document = document
        self.screen = screen
        self.navBarAppearance = navBarAppearance

        super.init(nibName: nil, bundle: nil)
        
        super.restorationIdentifier = screen.id
    }
    
    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        // manually fixup the safe area insets for the native ScrollView. Different edges are handled differently with a few different interactions. 18 is a fudge-factor.
        if let scrollContainer = useNativeScrollContainer {
            if (scrollContainer.ignoresSafeArea?.contains(.bottom) == true), (scrollContainer.ignoresSafeArea?.contains(.top) == true) {
                // bottom AND TOP safe area off
                scrollView.contentInset.bottom = -view.safeAreaInsets.top - view.safeAreaInsets.bottom - 18
            } else if (scrollContainer.ignoresSafeArea?.contains(.bottom) == true) {
                // bottom safe area off alone
                scrollView.contentInset.bottom = 0
            } else if (scrollContainer.ignoresSafeArea?.contains(.top) == true) {
                // top safe area off alone
                scrollView.contentInset.bottom = -view.safeAreaInsets.top - 18
            } else {
                // bottom safe area on
                scrollView.contentInset.bottom = view.safeAreaInsets.bottom
            }
        }
    }
    
    private var useNativeScrollContainer: ScrollContainer? {
        if screen.children.count == 1, let scrollContainer = screen.children.first as? ScrollContainer,
           scrollContainer.axis == .vertical,
           scrollContainer.aspectRatio == nil,
           scrollContainer.padding == nil,
           scrollContainer.layoutPriority == nil,
           scrollContainer.offset == nil,
           scrollContainer.shadow == nil,
           scrollContainer.opacity == nil,
           scrollContainer.background == nil,
           scrollContainer.overlay == nil,
           scrollContainer.mask == nil {
            return scrollContainer
        } else {
            return nil
        }
    }
    
    // Used only in case of large title preferred,
    // to distinguish between expanded and collapsed navigation bar
    private func updateKnownNavigationBarSizes() {
        guard let navigationController = self.navigationController else { return }

        UIView.performWithoutAnimation {
            let prevValue = navigationItem.largeTitleDisplayMode

            navigationItem.largeTitleDisplayMode = .always
            navigationController.navigationBar.sizeToFit()
            let expandedHeight = navigationController.navigationBar.frame.height

            navigationItem.largeTitleDisplayMode = .never
            navigationController.navigationBar.sizeToFit()
            let collapsedHeight = navigationController.navigationBar.frame.height

            self.knownNavigationBarSizes = (collapsed: collapsedHeight, expanded: expandedHeight)

            navigationItem.largeTitleDisplayMode = prevValue
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if let scrollContainer = useNativeScrollContainer {
            // if the root layer is a scrollview, handle the ScrollView on the UIKit side, to avoid combining a SwiftUI-managed ScrollView with a manually managed UINavigationController.  If this is not done, then glitchiness can result.
            clip_log(.debug, "Root Layer of ScrollContainer is a ScrollContainer, using UIKit UIScrollView directly.")
            
            self.view.addSubview(scrollView)
            self.scrollView.translatesAutoresizingMaskIntoConstraints = false
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
                
            self.view.backgroundColor = screen.backgroundColor.uikitUIColor(colorScheme: ColorScheme(self.traitCollection.userInterfaceStyle), colorSchemeContrast: ColorSchemeContrast(increasedContrastEnabled: UIAccessibility.isDarkerSystemColorsEnabled))

            self.hostingController = UIHostingController(
                rootView: AnyView(ScreenView(screen: screen, skipRootScrollView: true)
                    .environment(\.presentAction, { [weak self] uiViewController in
                        self?.present(uiViewController, animated: true)
                    })
                    .environment(\.showAction, { [ weak self] uiViewController in
                        self?.show(uiViewController, sender: self)
                    })
                    .environment(\.dismiss, { [ weak self] in
                        self?.dismiss(animated: true)
                    })
                    .environment(\.document, document)
                    .environment(\.navBarAppearance, screen.navBarAppearance ?? self.navBarAppearance)
                    .edgesIgnoringSafeArea(scrollContainer.ignoresSafeArea.map { Edge.Set(set: $0) } ?? [])
                )
            )

            self.addChild(hostingController)
            scrollView.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor).isActive = true
            self.hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor).isActive = true
            self.hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor).isActive = true
            self.hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor).isActive = true
            
            if scrollContainer.axis == .horizontal {
                scrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
            } else {
                scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
            }

            // we manage the insets ourselves.
            scrollView.contentInsetAdjustmentBehavior = .never
            
            self.hostingController.didMove(toParent: self)
        } else {
            // nest SwiftUI directly.
            self.hostingController = UIHostingController(
                rootView: AnyView(ScreenView(screen: screen, skipRootScrollView: false)
                    .environment(\.presentAction, { [weak self] uiViewController in
                        self?.present(uiViewController, animated: true)
                    })
                    .environment(\.showAction, { [ weak self] uiViewController in
                        self?.show(uiViewController, sender: self)
                    })
                    .environment(\.dismiss, { [ weak self] in
                        self?.dismiss(animated: true)
                    })
                    .environment(\.document, document)
                    .environment(\.navBarAppearance, screen.navBarAppearance ?? self.navBarAppearance)
                )
            )

            self.addChild(hostingController)
            view.addSubview(hostingController.view)
            // TODO: check for safe area modifier on the scroll container layer.
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            self.hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            self.hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            self.hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.hostingController.didMove(toParent: self)
        }


        navigationItem.title = screen.navBar.title
        switch screen.navBar.titleDisplayMode {
        case .normal:
            navigationItem.largeTitleDisplayMode = .never
        case .large:
            updateKnownNavigationBarSizes()
            navigationItem.largeTitleDisplayMode = .always
            observeLargeTitleNavigationBarChanges()
        }

        navigationItem.backButtonTitle = screen.navBar.backButtonTitle
        switch screen.navBar.backButtonDisplayMode {
        case .default:
            if #available(iOS 14.0, *) {
                navigationItem.backButtonDisplayMode = .default
            }
        case .generic:
            if #available(iOS 14.0, *) {
                navigationItem.backButtonDisplayMode = .generic
            }
        case .minimal:
            if #available(iOS 14.0, *) {
                navigationItem.backButtonDisplayMode = .minimal
            }
        case .hidden:
            navigationItem.hidesBackButton = true
        }

        func configureBarItem(buttonItem: ButtonItem) -> UIBarButtonItem {
            switch buttonItem {
            case .done:
                return BarButtonItem(systemItem: .done, style: .plain) { item in
                    self.dismiss(animated: true)
                }
            case .close:
                return BarButtonItem(systemItem: .close, style: .plain) { item in
                    self.dismiss(animated: true)
                }
            case .label(text: let text, action: let action):
                return BarButtonItem(title: text, style: .plain) { item in
                    self.handleAction(action)
                }
            case .glyph(icon: let icon, action: let action):
                return BarButtonItem(image: UIImage(systemName: icon.symbolName), style: .plain) { item in
                    self.handleAction(action)
                }
            }
        }

        self.navigationItem.leftBarButtonItem = screen.navBar.leadingButtonItem.map { configureBarItem(buttonItem: $0) }
        self.navigationItem.rightBarButtonItem = screen.navBar.trailingButtonItem.map { configureBarItem(buttonItem: $0) }

        updateAppearance()
    }

    private enum LargeTitleNavigationBarState: String {
        case collapsed
        case expanded
    }
    
    private func observeLargeTitleNavigationBarChanges() {
        let navigationBarStatePublisher = CurrentValueSubject<LargeTitleNavigationBarState, Never>(.expanded)

        let cancellableNavigationBarFrame = navigationController!.navigationBar
            .publisher(for: \.frame)
            .removeDuplicates()
            .sink { navBarFrame in
                guard let knownNavigationBarSizes = self.knownNavigationBarSizes else { return }

                if navBarFrame.height <= knownNavigationBarSizes.collapsed {
                    navigationBarStatePublisher.send(.collapsed)
                } else if navBarFrame.height >= knownNavigationBarSizes.expanded {
                    navigationBarStatePublisher.send(.expanded)
                }
            }
        cancellable.insert(cancellableNavigationBarFrame)

        let cancellableNavigationBarState = navigationBarStatePublisher
            .removeDuplicates()
            .sink { state in
                guard let navBarAppearance = self.screen.navBarAppearance
                        ?? self.navBarAppearance else { return }

                let displayInDarkMode = self.traitCollection.userInterfaceStyle == .dark ? true : false
                switch state {
                    case .collapsed:
                        self.currentStatusBarStyle = navBarAppearance.standardConfiguration.statusBarStyle.uiStatusBarStyle(displayInDarkMode: displayInDarkMode)
                    case .expanded:
                        self.currentStatusBarStyle = navBarAppearance.largeTitleConfiguration.statusBarStyle.uiStatusBarStyle(displayInDarkMode: displayInDarkMode)
                }
                
                self.updateNavBarTintColor(largeTitleNavigationBarState: state)
            }
        cancellable.insert(cancellableNavigationBarState)
    }

    required public init?(coder: NSCoder) {
        fatalError("Clip's ScreenViewController is not supported in Interface Builder or Storyboards.")
    }
    
    private func handleAction(_ action: Action) {
        action.handle(
            document: document,
            navBarAppearance: navBarAppearance,
            show: {
                self.show($0, sender: self)
            },
            present: {
                self.present($0, animated: true)
            },
            dismiss: {
                self.dismiss(animated: true)
            })
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavBarTintColor()
    }
    
    /// The color of the chevron in the back button is configured by the `UINavigationBar`'s
    /// `tintColor` property. It can not be configured through a `UINavigationBarAppearance`
    /// object. This method reaches up into the navigation controller and manually sets the tint color to
    /// match the button color on the `NavBarAppearance`.
    private func updateNavBarTintColor(largeTitleNavigationBarState: LargeTitleNavigationBarState? = nil) {
        guard let navBar = navigationController?.navigationBar else {
            return
        }
        
        let colorScheme: ColorScheme = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        let colorSchemeContrast: ColorSchemeContrast = traitCollection.accessibilityContrast == .high ? .increased : .standard
        
        guard let navBarAppearance = (screen.navBarAppearance ?? navBarAppearance) else {
            navBar.tintColor = .blue
            return
        }
        
        let configuration: NavBarAppearance.Configuration
        switch largeTitleNavigationBarState {
        case .collapsed:
            configuration = navBarAppearance.standardConfiguration
        case .expanded:
            configuration = navBarAppearance.largeTitleConfiguration
        case .none:
            switch screen.navBar.titleDisplayMode {
            case .normal:
                configuration = navBarAppearance.standardConfiguration
            case .large:
                configuration = navBarAppearance.largeTitleConfiguration
            }
        }
        
        if let buttonColor = configuration.buttonColor.uikitUIColor(colorScheme: colorScheme, colorSchemeContrast: colorSchemeContrast) {
            navBar.tintColor = buttonColor
        } else {
            navBar.tintColor = .blue
        }
    }
    
    private func updateAppearance() {
        if let navBarAppearance = (screen.navBarAppearance ?? navBarAppearance) {
            self.navigationItem.standardAppearance = uiNavBarAppearance(configuration: navBarAppearance.standardConfiguration, isLarge: false)
            self.navigationItem.scrollEdgeAppearance = uiNavBarAppearance(configuration: navBarAppearance.largeTitleConfiguration, isLarge: true)
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    private func uiNavBarAppearance(configuration: NavBarAppearance.Configuration, isLarge: Bool) -> UINavigationBarAppearance {
        let colorScheme: ColorScheme = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        let colorSchemeContrast: ColorSchemeContrast = traitCollection.accessibilityContrast == .high ? .increased : .standard
        
        let appearance = UINavigationBarAppearance()

        appearance.backgroundColor = configuration.backgroundColor.uikitUIColor(colorScheme: colorScheme, colorSchemeContrast: colorSchemeContrast)

        appearance.backgroundEffect = configuration.backgroundBlur ? UIBlurEffect(style: .systemChromeMaterial) : nil
        
        appearance.shadowColor = configuration.shadowColor.uikitUIColor(colorScheme: colorScheme, colorSchemeContrast: colorSchemeContrast)
        
        // Title
        var titleFontAttributes: [NSAttributedString.Key: Any] = [:]
    
        titleFontAttributes[.font] = configuration.titleFont.uikitFont
        
        if let titleColor = configuration.titleColor.uikitUIColor(colorScheme: colorScheme, colorSchemeContrast: colorSchemeContrast) {
            titleFontAttributes[.foregroundColor] = titleColor
        }
        
        if !titleFontAttributes.isEmpty {
            if isLarge {
                appearance.largeTitleTextAttributes = titleFontAttributes
            } else {
                appearance.titleTextAttributes = titleFontAttributes
            }
        }
        
        // Buttons
        
        var buttonsFontAttributes: [NSAttributedString.Key: Any] = [:]
        
        if let buttonColor = configuration.buttonColor.uikitUIColor(colorScheme: colorScheme, colorSchemeContrast: colorSchemeContrast) {
            buttonsFontAttributes[.foregroundColor] = buttonColor
        }
        
        buttonsFontAttributes[.font] = configuration.buttonFont.uikitFont
        
        if !buttonsFontAttributes.isEmpty {
            appearance.buttonAppearance.normal.titleTextAttributes = buttonsFontAttributes
            appearance.doneButtonAppearance.normal.titleTextAttributes = buttonsFontAttributes
        }

        return appearance
    }

    private var currentStatusBarStyle: UIStatusBarStyle = .default {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        currentStatusBarStyle
    }
}

private class BarButtonItem: UIBarButtonItem {
    typealias ActionHandler = (UIBarButtonItem) -> Void
    
    private var actionHandler: ActionHandler?
    
    convenience init(image: UIImage?, style: UIBarButtonItem.Style, actionHandler: ActionHandler?) {
        self.init(image: image, style: style, target: nil, action: #selector(barButtonItemPressed(sender:)))
        target = self
        self.actionHandler = actionHandler
    }
    
    convenience init(title: String?, style: UIBarButtonItem.Style, actionHandler: ActionHandler?) {
        self.init(title: title, style: style, target: nil, action: #selector(barButtonItemPressed(sender:)))
        target = self
        self.actionHandler = actionHandler
    }
    
    convenience init(systemItem: UIBarButtonItem.SystemItem, style: UIBarButtonItem.Style, actionHandler: ActionHandler?) {
        self.init(barButtonSystemItem: systemItem, target: nil, action: #selector(barButtonItemPressed(sender:)))
        target = self
        self.actionHandler = actionHandler
    }
    
    @objc func barButtonItemPressed(sender: UIBarButtonItem) {
        actionHandler?(sender)
    }
}

@available(iOS 13.0, *)
private extension NavBarAppearance.Configuration.StatusBarStyle {
    func uiStatusBarStyle(displayInDarkMode: Bool) -> UIStatusBarStyle {
        switch self {
        case .default:
            return .default
        case .light:
            return .lightContent
        case .dark:
            return .darkContent
        case .inverted:
            if displayInDarkMode {
                return .darkContent
            } else {
                return .lightContent
            }
        }
    }
}

@available(iOS 13.0, *)
private extension SwiftUI.ColorSchemeContrast {
    init(increasedContrastEnabled: Bool) {
        self = increasedContrastEnabled ? .increased : .standard
    }
}

@available(iOS 13.0, *)
private extension SwiftUI.ColorScheme {
    init(_ userInterfaceStyle: UIUserInterfaceStyle) {
        self = userInterfaceStyle == .dark ? .dark : .light
    }
}

@available(iOS 13.0, *)
private extension Edge.Set {
    init(set: Set<Edge>) {
        self = Edge.Set(set.map { edge in
            Edge.Set.Element(edge)
        })
    }
}

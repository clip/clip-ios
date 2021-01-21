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

import Foundation

@available(iOS 13.0, *)
public struct NavBarAppearance: Decodable, Hashable {
    public init(standardConfiguration: NavBarAppearance.Configuration, largeTitleConfiguration: NavBarAppearance.Configuration) {
        self.standardConfiguration = standardConfiguration
        self.largeTitleConfiguration = largeTitleConfiguration
    }
    
    public var standardConfiguration: Configuration
    public var largeTitleConfiguration: Configuration
    
    public struct Configuration: Decodable, Hashable {
        public init(statusBarStyle: NavBarAppearance.Configuration.StatusBarStyle, titleColor: ColorVariants, titleFont: Font, buttonColor: ColorVariants, buttonFont: Font, backgroundColor: ColorVariants, backgroundBlur: Bool, shadowColor: ColorVariants) {
            self.statusBarStyle = statusBarStyle
            self.titleColor = titleColor
            self.titleFont = titleFont
            self.buttonColor = buttonColor
            self.buttonFont = buttonFont
            self.backgroundColor = backgroundColor
            self.backgroundBlur = backgroundBlur
            self.shadowColor = shadowColor
        }
        
        public var statusBarStyle: StatusBarStyle
        public var titleColor: ColorVariants
        public var titleFont: Font
        public var buttonColor: ColorVariants
        public var buttonFont: Font
        public var backgroundColor: ColorVariants
        public var backgroundBlur: Bool
        public var shadowColor: ColorVariants
        
        public enum StatusBarStyle: String, Decodable {
            case `default`
            case light
            case dark
            case inverted
        }
    }
}

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
public final class Action: Decodable {
    public enum ActionType: String, CaseIterable, Codable, CustomStringConvertible {
        case navigateToScreen = "NavigateToScreenAction"
        case presentScreen = "PresentScreenAction"
        case openURL = "OpenURLAction"
        case presentWebsite = "PresentWebsiteAction"
        case close = "CloseAction"
        
        public var description: String {
            switch self {
            case .navigateToScreen:
                return "Navigate To Screen"
            case .presentScreen:
                return "Present Screen"
            case .close:
                return "Close"
            case .openURL:
                return "Open URL"
            case .presentWebsite:
                return "Present Website"
            }
        }
    }
    
    public enum ModalTransitionStyle: String, Decodable {
        case systemDefault
        case fadeThrough
        case slideUp
    }
    
    public let actionType: ActionType
    public var screen: Screen?
    public let url: URL?
    public let modalTransitionStyle: ModalTransitionStyle?
    
    public init(actionType: ActionType, screen: Screen? = nil, url: URL? = nil, modalTransitionStyle: ModalTransitionStyle? = nil) {
        self.actionType = actionType
        self.screen = screen
        self.url = url
        self.modalTransitionStyle = modalTransitionStyle
    }
    
    // MARK: Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(actionType)
        hasher.combine(screen?.id)
        hasher.combine(url)
        hasher.combine(modalTransitionStyle)
    }
    
    public static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.actionType == rhs.actionType
            && lhs.screen?.id == rhs.screen?.id
            && lhs.url == rhs.url
            && lhs.modalTransitionStyle == rhs.modalTransitionStyle
    }
    
    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
        case __typeName
        case screenID
        case url
        case modalTransitionStyle
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        actionType = try container.decode(ActionType.self, forKey: .__typeName)

        modalTransitionStyle = try container.decodeIfPresent(ModalTransitionStyle.self, forKey: .modalTransitionStyle)
        url = try container.decodeIfPresent(URL.self, forKey: .url)

        if container.contains(.screenID) {
            let coordinator = decoder.userInfo[.decodingCoordinator] as! DecodingCoordinator
            let screenID = try container.decode(Node.ID.self, forKey: .screenID)
            coordinator.registerOneToOneRelationship(nodeID: screenID, to: self, keyPath: \.screen)
        }
    }
}

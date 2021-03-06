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
import os.log

@available(iOS 13.0, *)
internal struct DocumentKey: EnvironmentKey {
    static let defaultValue: Document? = nil
}

@available(iOS 13.0, *)
internal struct StringTableKey: EnvironmentKey {
    static let defaultValue: StringTable = StringTable()
}

@available(iOS 13.0, *)
internal struct PresentActionKey: EnvironmentKey {
    static let defaultValue: (UIViewController) -> Void = {
        _ in
        clip_log(.error, "Present action was ignored.")
    }
}

@available(iOS 13.0, *)
internal struct ShowActionKey: EnvironmentKey {
    static let defaultValue: (UIViewController) -> Void = {
        _ in
        clip_log(.error, "Show action was ignored.")
    }
}

@available(iOS 13.0, *)
internal struct DismissKey: EnvironmentKey {
    static let defaultValue: () -> Void = {
        clip_log(.error, "Dismiss action was ignored.")
    }
}

@available(iOS 13.0, *)
internal struct DataItemKey: EnvironmentKey {
    static let defaultValue: DataItem? = nil
}

@available(iOS 13.0, *)
internal extension EnvironmentValues {
    var document: Document? {
        get {
            self[DocumentKey.self]
        }
        
        set {
            self[DocumentKey.self] = newValue
        }
    }
    
    var stringTable: StringTable {
        get {
            self[StringTableKey.self]
        }
        
        set {
            self[StringTableKey.self] = newValue
        }
    }

    var presentAction: ((UIViewController) -> Void) {
        get {
            self[PresentActionKey.self]
        }
        
        set {
            self[PresentActionKey.self] = newValue
        }
    }

    var showAction: ((UIViewController) -> Void) {
        get {
            self[ShowActionKey.self]
        }
        
        set {
            self[ShowActionKey.self] = newValue
        }
    }

    var dismiss: (() -> Void) {
        get {
            self[DismissKey.self]
        }
        
        set {
            self[DismissKey.self] = newValue
        }
    }
    
    var dataItem: DataItem? {
        get {
            return self[DataItemKey.self]
        }
        
        set {
            self[DataItemKey.self] = newValue
        }
    }
}

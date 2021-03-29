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

@available(iOS 13.0, *)
struct CollectionView: View {
    @Environment(\.dataItem) private var dataItem
    
    let collection: Collection

    var body: some View {
        if let items = items {
            ForEach(Array(zip(items.indices, items)), id: \.0) { index, item in
                ForEach(collection.children.compactMap { $0 as? Layer }) {
                    LayerView(layer: $0)
                }
                .environment(\.dataItem, item)
                .contentShape(SwiftUI.Rectangle())
            }
        }
    }
    
    private var items: [DataItem]? {
        guard var result = dataItem?[collection.dataKey] as? [DataItem] else {
            return nil
        }
        
        collection.filters.forEach { filter in
            result = result.filter { dataItem in
                switch (filter.predicate, dataItem.rawValue[filter.dataKey], filter.value) {
                case (.equals, let a as String, let b as String):
                    return a == b
                case (.equals, let a as Double, let b as Double):
                    return a == b
                case (.doesNotEqual, let a as String, let b as String):
                    return a != b
                case (.doesNotEqual, let a as Double, let b as Double):
                    return a != b
                case (.isGreaterThan, let a as Double, let b as Double):
                    return a > b
                case (.isLessThan, let a as Double, let b as Double):
                    return a < b
                case (.isSet, .some, _):
                    return true
                case (.isSet, .none, _):
                    return false
                case (.isNotSet, .some, _):
                    return false
                case (.isNotSet, .none, _):
                    return true
                case (.isTrue, let value as Bool, _):
                    return value == true
                case (.isFalse, let value as Bool, _):
                    return value == false
                default:
                    return true
                }
            }
        }
        
        if !collection.sortDescriptors.isEmpty {
            result.sort { a, b in
                for descriptor in collection.sortDescriptors {
                    switch (a.rawValue[descriptor.dataKey], b.rawValue[descriptor.dataKey]) {
                    case (let a as String, let b as String) where a != b:
                        return descriptor.ascending ? a < b : a > b
                    case (let a as Double, let b as Double) where a != b:
                        return descriptor.ascending ? a < b : a > b
                    case (let a as Bool, let b as Bool) where a != b:
                        return descriptor.ascending ? a == false : a == true
                    case (let a as Date, let b as Date) where a != b:
                        return descriptor.ascending ? a < b : a > b
                    default:
                        break
                    }
                }
                
                return false
            }
        }
        
        if let index = collection.limit.map({ $0.startAt - 1 }) {
            if result.indices.contains(index) {
                result = Array(result.suffix(from: index))
            } else {
                result = []
            }
        }
        
        result = Array(result.prefix(collection.limit?.show ?? 100))
        
        return result
    }
}

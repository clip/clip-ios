import Foundation
import ClipModel

extension URLRequest {
    @available(iOS 13.0, *)
    init(dataSource: DataSource) {
        self.init(url: dataSource.url)
        self.httpMethod = dataSource.httpMethod.rawValue
        self.httpBody = dataSource.httpBody?.data(using: .utf8)
        
        dataSource.headers.forEach {
            self.addValue($0.value, forHTTPHeaderField: $0.key)
        }
    }
}

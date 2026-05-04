import Foundation
import SwiftData

@Model
final class StoredImage {
    @Attribute(.externalStorage) var data: Data
    var sortIndex: Int

    init(data: Data, sortIndex: Int) {
        self.data = data
        self.sortIndex = sortIndex
    }
}

import UIKit

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    func thumbnail(for data: Data, size: CGSize) -> UIImage? {
        let key = "\(data.hashValue)-\(Int(size.width))x\(Int(size.height))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let image = UIImage(data: data) else { return nil }

        let scale = min(size.width / image.size.width, size.height / image.size.height)
        guard scale < 1 else {
            cache.setObject(image, forKey: key, cost: data.count)
            return image
        }

        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        cache.setObject(thumbnail, forKey: key, cost: data.count)
        return thumbnail
    }
}

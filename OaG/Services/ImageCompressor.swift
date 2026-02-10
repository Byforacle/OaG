import UIKit

enum ImageCompressor: Sendable {
    static func compressForAPI(_ image: UIImage, maxDimension: CGFloat = 1568) -> (base64: String, mediaType: String)? {
        let resized = resize(image, maxDimension: maxDimension)
        if let jpegData = resized.jpegData(compressionQuality: 0.85) {
            return (jpegData.base64EncodedString(), "image/jpeg")
        }
        if let pngData = resized.pngData() {
            return (pngData.base64EncodedString(), "image/png")
        }
        return nil
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

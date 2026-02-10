import UIKit

enum ImageCompressor: Sendable {
    /// Maximum base64-encoded size per image in bytes (150 KB).
    private static let maxBase64Size = 150_000

    static func compressForAPI(
        _ image: UIImage,
        maxDimension: CGFloat = 1024
    ) -> (base64: String, mediaType: String)? {
        let resized = resize(image, maxDimension: maxDimension)

        // Progressive compression: start at 0.7, step down by 0.1, floor at 0.3
        var quality: CGFloat = 0.7
        while quality >= 0.3 {
            if let jpegData = resized.jpegData(compressionQuality: quality) {
                let base64 = jpegData.base64EncodedString()
                if base64.count <= maxBase64Size {
                    return (base64, "image/jpeg")
                }
            }
            quality -= 0.1
        }

        // Final attempt at lowest quality
        if let jpegData = resized.jpegData(compressionQuality: 0.3) {
            return (jpegData.base64EncodedString(), "image/jpeg")
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

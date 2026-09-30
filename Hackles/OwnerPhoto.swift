import PhotosUI
import SwiftUI
import UIKit

enum OwnerPhotoStore {
  private static var directory: URL {
    let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    let folder = root.appendingPathComponent("OwnerPhotos", isDirectory: true)
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder
  }

  static func fileKey(for email: String) -> String {
    let safe = email
      .lowercased()
      .replacingOccurrences(of: "@", with: "_at_")
      .replacingOccurrences(of: ".", with: "_")
      .filter { $0.isLetter || $0.isNumber || $0 == "_" }
    return "owners/\(safe).jpg"
  }

  static func isFileKey(_ key: String) -> Bool {
    key.hasPrefix("owners/")
  }

  static func load(_ key: String?) -> UIImage? {
    guard let key, !key.isEmpty else { return nil }
    if isFileKey(key) {
      let url = directory.appendingPathComponent(URL(fileURLWithPath: key).lastPathComponent)
      guard let data = try? Data(contentsOf: url) else { return nil }
      return UIImage(data: data)
    }
    return UIImage(named: key)
  }

  static func save(_ image: UIImage, for email: String) throws -> String {
    let key = fileKey(for: email)
    let url = directory.appendingPathComponent(URL(fileURLWithPath: key).lastPathComponent)
    let sized = squareCropped(image, side: 720)
    guard let data = sized.jpegData(compressionQuality: 0.86) else {
      throw OwnerPhotoError.encodeFailed
    }
    try data.write(to: url, options: .atomic)
    return key
  }

  static func delete(_ key: String?) {
    guard let key, isFileKey(key) else { return }
    let url = directory.appendingPathComponent(URL(fileURLWithPath: key).lastPathComponent)
    try? FileManager.default.removeItem(at: url)
  }

  private static func squareCropped(_ image: UIImage, side: CGFloat) -> UIImage {
    let length = min(image.size.width, image.size.height)
    guard length > 0 else { return image }
    let origin = CGPoint(
      x: (image.size.width - length) / 2,
      y: (image.size.height - length) / 2
    )
    let crop = CGRect(origin: origin, size: CGSize(width: length, height: length))
    guard let cg = image.cgImage?.cropping(to: crop.integralScaled(by: image.scale)) else {
      return image
    }
    let cropped = UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
    return renderer.image { _ in
      cropped.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
    }
  }
}

enum OwnerPhotoError: LocalizedError {
  case encodeFailed

  var errorDescription: String? {
    "Could not save that photo."
  }
}

private extension CGRect {
  func integralScaled(by scale: CGFloat) -> CGRect {
    CGRect(
      x: origin.x * scale,
      y: origin.y * scale,
      width: size.width * scale,
      height: size.height * scale
    ).integral
  }
}

struct OwnerPhoto: View {
  let name: String?
  var size: CGFloat = 96
  var initials: String = ""

  var body: some View {
    Group {
      if let image = OwnerPhotoStore.load(name) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        ZStack {
          Theme.mark
          if initials.isEmpty {
            Image(systemName: "person.fill")
              .font(.system(size: size * 0.38, weight: .semibold))
              .foregroundStyle(.white)
          } else {
            Text(initials)
              .font(.system(size: size * 0.34, weight: .semibold, design: .rounded))
              .foregroundStyle(.white)
          }
        }
      }
    }
    .frame(width: size, height: size)
    .clipShape(Circle())
    .overlay {
      Circle().stroke(Theme.line, lineWidth: 1)
    }
    .accessibilityHidden(true)
  }
}

enum OwnerInitials {
  static func from(name: String) -> String {
    let parts = name
      .split(whereSeparator: \.isWhitespace)
      .prefix(2)
      .compactMap { $0.first.map(String.init) }
    return parts.joined().uppercased()
  }
}

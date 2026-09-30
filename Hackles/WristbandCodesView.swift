import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

enum WristbandCodeImage {
  private static let context = CIContext()

  static func qr(_ value: String, dimension: CGFloat = 240) -> UIImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(value.utf8)
    filter.correctionLevel = "M"
    return render(filter.outputImage, width: dimension, height: dimension)
  }

  static func barcode(_ value: String, width: CGFloat = 320, height: CGFloat = 96) -> UIImage? {
    let filter = CIFilter.code128BarcodeGenerator()
    filter.message = Data(value.utf8)
    return render(filter.outputImage, width: width, height: height)
  }

  private static func render(_ image: CIImage?, width: CGFloat, height: CGFloat) -> UIImage? {
    guard let image else { return nil }
    let scaled = image.transformed(
      by: CGAffineTransform(
        scaleX: width / image.extent.width,
        y: height / image.extent.height
      )
    )
    guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
    return UIImage(cgImage: cgImage)
  }
}

struct WristbandCodesView: View {
  let value: String

  private var band: String {
    Directory.normalizeBand(value)
  }

  var body: some View {
    if !band.isEmpty {
      VStack(alignment: .leading, spacing: 14) {
        codeBlock(title: "Barcode") {
          if let image = WristbandCodeImage.barcode(band) {
            Image(uiImage: image)
              .resizable()
              .interpolation(.none)
              .scaledToFit()
              .frame(maxWidth: .infinity)
              .frame(height: 72)
              .padding(.horizontal, 8)
          } else {
            Text("Could not build barcode.")
              .font(.system(size: 13))
              .foregroundStyle(Theme.mute)
          }
        }

        codeBlock(title: "QR code") {
          if let image = WristbandCodeImage.qr(band) {
            Image(uiImage: image)
              .resizable()
              .interpolation(.none)
              .scaledToFit()
              .frame(width: 168, height: 168)
              .frame(maxWidth: .infinity)
          } else {
            Text("Could not build QR code.")
              .font(.system(size: 13))
              .foregroundStyle(Theme.mute)
          }
        }
      }
    }
  }

  private func codeBlock<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Theme.mute)
      content()
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Theme.line, lineWidth: 1)
        }
    }
  }
}

struct WristbandCodesSheet: View {
  let value: String
  @Environment(\.dismiss) private var dismiss

  private var band: String {
    Directory.normalizeBand(value)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text(band)
            .font(.system(size: 15, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Theme.orange)
            .frame(maxWidth: .infinity, alignment: .leading)

          WristbandCodesView(value: band)
        }
        .padding(24)
      }
      .background(Theme.paper)
      .navigationTitle("Wristband")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
            .fontWeight(.semibold)
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}

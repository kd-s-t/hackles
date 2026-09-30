import SwiftUI
import VisionKit

struct WristbandScannerView: UIViewControllerRepresentable {
  var onCode: (String) -> Void
  var onCancel: () -> Void

  func makeUIViewController(context: Context) -> UINavigationController {
    let scanner: UIViewController
    if DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
      let dataScanner = DataScannerViewController(
        recognizedDataTypes: [.barcode()],
        qualityLevel: .accurate,
        recognizesMultipleItems: false,
        isHighFrameRateTrackingEnabled: false,
        isHighlightingEnabled: true
      )
      dataScanner.delegate = context.coordinator
      dataScanner.title = "Scan wristband"
      scanner = dataScanner
      context.coordinator.dataScanner = dataScanner
    } else {
      scanner = UIHostingController(
        rootView: VStack(spacing: 16) {
          Text("Camera scanning is not available on this device.")
            .multilineTextAlignment(.center)
            .foregroundStyle(Theme.mute)
          Button("Close", action: onCancel)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.red)
        }
        .padding(24)
        .background(Theme.paper.ignoresSafeArea())
      )
    }

    let nav = UINavigationController(rootViewController: scanner)
    scanner.navigationItem.leftBarButtonItem = UIBarButtonItem(
      systemItem: .cancel,
      primaryAction: UIAction { _ in onCancel() }
    )
    return nav
  }

  func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    if let scanner = context.coordinator.dataScanner, !scanner.isScanning {
      try? scanner.startScanning()
    }
  }

  static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: Coordinator) {
    coordinator.dataScanner?.stopScanning()
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(onCode: onCode)
  }

  final class Coordinator: NSObject, DataScannerViewControllerDelegate {
    let onCode: (String) -> Void
    var dataScanner: DataScannerViewController?
    private var handled = false

    init(onCode: @escaping (String) -> Void) {
      self.onCode = onCode
    }

    func dataScanner(
      _ dataScanner: DataScannerViewController,
      didTapOn item: RecognizedItem
    ) {
      guard case .barcode(let barcode) = item, let value = barcode.payloadStringValue else { return }
      finish(value)
    }

    func dataScanner(
      _ dataScanner: DataScannerViewController,
      didAdd addedItems: [RecognizedItem],
      allItems: [RecognizedItem]
    ) {
      guard !handled else { return }
      for item in addedItems {
        if case .barcode(let barcode) = item, let value = barcode.payloadStringValue, !value.isEmpty {
          finish(value)
          return
        }
      }
    }

    private func finish(_ value: String) {
      guard !handled else { return }
      handled = true
      dataScanner?.stopScanning()
      onCode(value)
    }
  }
}

import Foundation
import SwiftData

enum RegisterMode: String, Hashable {
  case old
  case new
}

enum WristbandFactory {
  /// Globally unique by design (UUID). Also verified against the local store.
  /// Replace the worldwide step with a server lookup when a shared DB exists.
  @MainActor
  static func generateUnique(context: ModelContext) async throws -> String {
    for _ in 0..<12 {
      let candidate = makeId()
      if try await isAvailableWorldwide(candidate, context: context) {
        return candidate
      }
    }
    throw DirectoryError.duplicateWristband
  }

  @MainActor
  static func isAvailableWorldwide(_ wristband: String, context: ModelContext) async throws -> Bool {
    let band = Directory.normalizeBand(wristband)
    guard !band.isEmpty else { return false }
    if try Directory.hackle(wristband: band, context: context) != nil {
      return false
    }
    // Future: call the shared worldwide registry API here.
    // Local UUID ids are treated as free worldwide until that API exists.
    return true
  }

  private static func makeId() -> String {
    let raw = UUID().uuidString.replacingOccurrences(of: "-", with: "").uppercased()
    return "HK-" + String(raw.prefix(12))
  }
}

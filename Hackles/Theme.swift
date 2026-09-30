import SwiftUI

enum Theme {
  static let paper = Color(red: 1.0, green: 0.953, blue: 0.929)
  static let ink = Color(red: 0.227, green: 0.067, blue: 0.055)
  static let red = Color(red: 0.769, green: 0.118, blue: 0.086)
  static let orange = Color(red: 0.949, green: 0.420, blue: 0.067)
  static let card = Color.white
  static let line = Color(red: 0.945, green: 0.824, blue: 0.769)
  static let mute = Color(red: 0.478, green: 0.310, blue: 0.255)
  static let danger = Color(red: 0.620, green: 0.040, blue: 0.059)
  static let onFill = Color.white

  static let brand = LinearGradient(
    colors: [orange, red],
    startPoint: .leading,
    endPoint: .trailing
  )

  static let mark = LinearGradient(
    colors: [orange, red],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
}

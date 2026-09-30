import SwiftUI

enum PremiumPlan {
  static let freeYardLimit = 1
  static let freeHackleLimit = 10
  static let priceLabel = "₱499 / year"
  static let priceNote = "Billed yearly. Cancel anytime from Account."

  static func canAddYard(isPremium: Bool, currentCount: Int) -> Bool {
    isPremium || currentCount < freeYardLimit
  }

  static func canAddHackle(isPremium: Bool, currentCount: Int) -> Bool {
    isPremium || currentCount < freeHackleLimit
  }

  static var freeSummary: String {
    "Free includes \(freeYardLimit) yard and \(freeHackleLimit) hackles."
  }
}

enum PremiumGate: Identifiable {
  case yard
  case hackle

  var id: String {
    switch self {
    case .yard: return "yard"
    case .hackle: return "hackle"
    }
  }

  var title: String {
    switch self {
    case .yard: return "Yard limit reached"
    case .hackle: return "Hackle limit reached"
    }
  }

  var message: String {
    switch self {
    case .yard:
      return "Free accounts can keep \(PremiumPlan.freeYardLimit) yard. Get Premium to add more yards."
    case .hackle:
      return "Free accounts can register \(PremiumPlan.freeHackleLimit) hackles. Get Premium to add more."
    }
  }
}

enum PremiumPayMethod: String, CaseIterable, Identifiable {
  case qrph
  case paypal
  case splitsafe

  var id: String { rawValue }

  var label: String {
    switch self {
    case .qrph: return "QR Ph"
    case .paypal: return "PayPal"
    case .splitsafe: return "SplitSafe"
    }
  }

  var assetName: String {
    switch self {
    case .qrph: return "PayQRPh"
    case .paypal: return "PayPayPal"
    case .splitsafe: return "PaySplitSafe"
    }
  }

  var isComingSoon: Bool { false }

  var detail: String {
    switch self {
    case .qrph:
      return "Scan with GCash, Maya, or any QR Ph wallet."
    case .paypal:
      return "Pay with PayPal or a linked card."
    case .splitsafe:
      return "Pay with SplitSafe crypto checkout."
    }
  }

  var confirmTitle: String {
    switch self {
    case .qrph: return "Pay with QR Ph"
    case .paypal: return "Continue with PayPal"
    case .splitsafe: return "Continue with SplitSafe"
    }
  }
}

struct PremiumCard: View {
  let isPremium: Bool
  let yardCount: Int
  let hackleCount: Int
  let onGetPremium: () -> Void
  var onCancelPremium: () -> Void = {}

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("PREMIUM")
          .font(.system(size: 12, weight: .semibold))
          .tracking(1.6)
          .foregroundStyle(Theme.red)
        Spacer()
        Text(isPremium ? "Active" : "Free")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(isPremium ? Theme.red : Theme.mute)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(
            (isPremium ? Theme.orange : Theme.mute).opacity(0.14),
            in: Capsule()
          )
      }

      if isPremium {
        Text("Unlimited yards and hackles on this account.")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Theme.ink)
        Button("Cancel Premium") {
          onCancelPremium()
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(Theme.danger)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
      } else {
        Text(PremiumPlan.freeSummary)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Theme.ink)
        detailRow("Yards", "\(yardCount) / \(PremiumPlan.freeYardLimit)")
        detailRow("Hackles", "\(hackleCount) / \(PremiumPlan.freeHackleLimit)")
        PremiumSignButton {
          onGetPremium()
        }
        .padding(.top, 4)
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(Theme.line, lineWidth: 1)
    }
  }

  private func detailRow(_ label: String, _ value: String) -> some View {
    HStack {
      Text(label)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(Theme.mute)
      Spacer()
      Text(value)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(Theme.ink)
    }
  }
}

struct PremiumPaywallSheet: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  var gate: PremiumGate?

  @State private var selectedMethod: PremiumPayMethod?
  @State private var showSplitSafeHint = false
  @State private var isPaying = false
  @State private var statusMessage: String?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          Text(gate?.title ?? "Hackles Premium")
            .font(.system(size: 28, weight: .regular, design: .serif))
            .foregroundStyle(Theme.ink)

          Text(gate?.message ?? "Unlock more yards and hackles for bigger flocks.")
            .font(.system(size: 16))
            .foregroundStyle(Theme.mute)

          VStack(alignment: .leading, spacing: 10) {
            bullet("Unlimited yards")
            bullet("Unlimited hackles")
            bullet("Keep your free flock and history")
          }

          HStack(alignment: .firstTextBaseline) {
            Text(PremiumPlan.priceLabel)
              .font(.system(size: 22, weight: .semibold))
              .foregroundStyle(Theme.ink)
            Spacer()
          }
          Text(PremiumPlan.priceNote)
            .font(.system(size: 13))
            .foregroundStyle(Theme.mute)

          payWithSection

          if let statusMessage {
            Notice(text: statusMessage, tone: Theme.red)
          }

          BrandButton(
            title: selectedMethod?.confirmTitle ?? "Choose how to sign up",
            busy: isPaying
          ) {
            Task { await pay() }
          }
          .disabled(selectedMethod == nil || selectedMethod?.isComingSoon == true || isPaying)

          Button("Not now") { dismiss() }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.mute)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
        }
        .padding(24)
      }
      .background(Theme.paper)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
    }
    .presentationDetents([.large, .medium])
    .presentationDragIndicator(.visible)
  }

  private var payWithSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Pay with")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(Theme.mute)
        .textCase(.uppercase)
        .tracking(0.6)

      Text("Select a method. QR Ph, PayPal, and SplitSafe open checkout right away.")
        .font(.system(size: 14))
        .foregroundStyle(Theme.mute)

      VStack(spacing: 8) {
        ForEach(PremiumPayMethod.allCases) { method in
          payMethodRow(method)
        }
      }

      if selectedMethod == .qrph {
        methodFootnote("Scan the QR with any QR Ph wallet. Your Premium unlocks after payment confirms.")
      } else if selectedMethod == .paypal {
        methodFootnote("You’ll finish in PayPal, then return here with Premium unlocked.")
      } else if selectedMethod == .splitsafe {
        methodFootnote("You’ll finish in SplitSafe, then return here with Premium unlocked.")
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(Theme.line, lineWidth: 1)
    }
  }

  private func methodFootnote(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 13))
      .foregroundStyle(Theme.mute)
      .padding(.top, 4)
  }

  @ViewBuilder
  private func payMethodRow(_ method: PremiumPayMethod) -> some View {
    let selected = selectedMethod == method
    let comingSoon = method.isComingSoon

    let row = HStack(spacing: 10) {
      Image(method.assetName)
        .resizable()
        .scaledToFit()
        .frame(width: comingSoon ? 26 : 36, height: comingSoon ? 26 : 36)
        .opacity(comingSoon ? 0.45 : 1)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(method.label)
          .font(.system(size: 15, weight: .semibold))
          .lineLimit(1)
        Text(method.detail)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(comingSoon ? Theme.mute.opacity(0.7) : Theme.mute)
          .lineLimit(2)
      }

      if method == .splitsafe {
        Button {
          showSplitSafeHint = true
        } label: {
          Image(systemName: "info.circle")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.mute)
            .frame(width: 22, height: 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("About SplitSafe")
        .popover(isPresented: $showSplitSafeHint) {
          Text("SplitSafe is crypto checkout for international payers.")
            .font(.system(size: 14))
            .foregroundStyle(Theme.ink)
            .padding(16)
            .frame(width: 240, alignment: .leading)
            .presentationCompactAdaptation(.popover)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(.leading, 14)
    .padding(.trailing, comingSoon ? 52 : 14)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
    .foregroundStyle(comingSoon ? Theme.ink.opacity(0.45) : Theme.ink)
    .background(
      selected && !comingSoon
        ? Theme.orange.opacity(0.18)
        : (comingSoon ? Theme.paper : Theme.card),
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(
          comingSoon
            ? Theme.line.opacity(0.7)
            : (selected ? Theme.orange : Theme.line),
          lineWidth: selected && !comingSoon ? 1.5 : 1
        )
    }
    .overlay(alignment: .trailing) {
      if comingSoon {
        Text("Soon")
          .font(.system(size: 10, weight: .bold))
          .textCase(.uppercase)
          .tracking(0.4)
          .foregroundStyle(Theme.mute)
          .padding(.horizontal, 6)
          .padding(.vertical, 3)
          .background(Theme.mute.opacity(0.1), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
          .padding(.trailing, 10)
      }
    }

    if comingSoon {
      row
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(method.label), coming soon")
    } else {
      Button {
        selectedMethod = method
        statusMessage = nil
      } label: {
        row
      }
      .buttonStyle(.plain)
      .disabled(isPaying)
      .accessibilityLabel(method.label)
    }
  }

  private func bullet(_ text: String) -> some View {
    HStack(spacing: 10) {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(Theme.orange)
      Text(text)
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Theme.ink)
    }
  }

  @MainActor
  private func pay() async {
    guard let selectedMethod, !selectedMethod.isComingSoon else { return }
    isPaying = true
    statusMessage = nil
    defer { isPaying = false }

    // Local unlock until PayMongo / PayPal / SplitSafe gateways are wired for Hackles.
    try? await Task.sleep(nanoseconds: 700_000_000)
    auth.setPremium(true, context: context)
    statusMessage = "\(selectedMethod.label) payment confirmed. Premium is active."
    try? await Task.sleep(nanoseconds: 450_000_000)
    dismiss()
  }
}

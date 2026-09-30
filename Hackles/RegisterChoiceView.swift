import SwiftData
import SwiftUI

struct RegisterChoiceView: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  @Binding var path: [HomeRoute]
  @State private var flockCount = 0
  @State private var showPremium = false

  private var canAdd: Bool {
    PremiumPlan.canAddHackle(isPremium: auth.account?.isPremium == true, currentCount: flockCount)
  }

  var body: some View {
    ScreenColumn(
      kicker: "HACKLE",
      title: "Add hackle",
      subtitle: "Old hackles keep their wristband. New hackles get a generated id."
    ) {
      VStack(spacing: 14) {
        if !canAdd {
          Notice(text: PremiumGate.hackle.message, tone: Theme.danger)
          PremiumSignButton {
            showPremium = true
          }
        }

        choiceCard(
          title: "Old hackle",
          detail: "Scan the wristband already on the bird.",
          systemImage: "barcode.viewfinder",
          enabled: canAdd
        ) {
          path.append(.register(.old))
        }
        choiceCard(
          title: "New hackle",
          detail: "Generate a wristband id and check it is free.",
          systemImage: "plus.circle",
          enabled: canAdd
        ) {
          path.append(.register(.new))
        }

        if auth.account?.isPremium != true {
          Text("\(flockCount) / \(PremiumPlan.freeHackleLimit) free hackles used")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.mute)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("")
    .task { reload() }
    .onAppear { reload() }
    .sheet(isPresented: $showPremium, onDismiss: reload) {
      PremiumPaywallSheet(gate: .hackle)
    }
  }

  private func reload() {
    guard let email = auth.account?.email else {
      flockCount = 0
      return
    }
    flockCount = (try? Directory.owned(by: email, context: context).count) ?? 0
  }

  private func choiceCard(
    title: String,
    detail: String,
    systemImage: String,
    enabled: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button {
      if enabled {
        action()
      } else {
        showPremium = true
      }
    } label: {
      HStack(alignment: .top, spacing: 14) {
        Image(systemName: systemImage)
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(enabled ? Theme.orange : Theme.mute)
          .frame(width: 36)
        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Theme.ink)
          Text(detail)
            .font(.system(size: 14))
            .foregroundStyle(Theme.mute)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 0)
        Image(systemName: "chevron.right")
          .foregroundStyle(Theme.mute)
      }
      .padding(18)
      .opacity(enabled ? 1 : 0.55)
      .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(Theme.line, lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
  }
}

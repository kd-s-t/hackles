import SwiftData
import SwiftUI
import UIKit

struct MyHacklesView: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  @Binding var path: [HomeRoute]
  @State private var birds: [HackleRecord] = []
  @State private var yards: [OwnerYard] = []
  @State private var filters = HacklesListFilters()
  @State private var errorMessage: String?
  @State private var showPremium = false

  private var filteredBirds: [HackleRecord] {
    birds.filter(filters.matches)
  }

  private var yardNames: [String] {
    var names = yards.map(\.name)
    for bird in birds {
      let farm = (bird.farm ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      if !farm.isEmpty, !names.contains(farm) {
        names.append(farm)
      }
    }
    return names
  }

  private var yardSections: [HacklesYardSection] {
    HacklesYardSection.build(from: filteredBirds, preferredOrder: yardNames)
  }

  var body: some View {
    Group {
      if let errorMessage {
        Notice(text: errorMessage, tone: Theme.danger)
          .padding(24)
      } else if birds.isEmpty {
        ContentUnavailableView {
          Label("No hackles yet", systemImage: "bird")
        } description: {
          Text("Add an old hackle by scanning its wristband, or create a new one with a generated id.")
        } actions: {
          Button("Add hackle") {
            let premium = auth.account?.isPremium == true
            if PremiumPlan.canAddHackle(isPremium: premium, currentCount: birds.count) {
              path.append(.registerChoice)
            } else {
              showPremium = true
            }
          }
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Theme.red)
        }
      } else {
        VStack(spacing: 0) {
          HacklesFilterBar(filters: $filters, yards: yardNames, resultCount: filteredBirds.count)
          if filteredBirds.isEmpty {
            ContentUnavailableView(
              "No match",
              systemImage: "line.3.horizontal.decrease.circle",
              description: Text("No hackle matches these filters.")
            )
          } else {
            List {
              ForEach(yardSections) { section in
                Section {
                  ForEach(section.birds, id: \.wristband) { bird in
                    Button {
                      path.append(.detail(bird.wristband))
                    } label: {
                      HackleRow(bird: bird, compact: true)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.card)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                  }
                } header: {
                  HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                      .font(.system(size: 11, weight: .semibold))
                      .foregroundStyle(Theme.orange)
                    Text(section.title)
                      .font(.system(size: 13, weight: .semibold))
                      .foregroundStyle(Theme.mute)
                      .textCase(nil)
                    Text("\(section.birds.count)")
                      .font(.system(size: 12, weight: .semibold))
                      .foregroundStyle(Theme.mute.opacity(0.8))
                    Spacer()
                  }
                  .padding(.top, 4)
                }
              }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.paper)
    .navigationTitle("My hackles")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          let premium = auth.account?.isPremium == true
          if PremiumPlan.canAddHackle(isPremium: premium, currentCount: birds.count) {
            path.append(.registerChoice)
          } else {
            showPremium = true
          }
        } label: {
          Image(systemName: "plus")
        }
        .accessibilityLabel("Add hackle")
      }
    }
    .sheet(isPresented: $showPremium) {
      PremiumPaywallSheet(gate: .hackle)
    }
    .task { reload() }
    .onAppear { reload() }
  }

  private func reload() {
    guard let email = auth.account?.email else {
      birds = []
      yards = []
      return
    }
    do {
      birds = try Directory.owned(by: email, context: context)
      yards = try Directory.yards(ownedBy: email, context: context)
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

struct HacklePhoto: View {
  let name: String?
  var size: CGFloat = 56

  var body: some View {
    Group {
      if let name, !name.isEmpty, UIImage(named: name) != nil {
        Image(name)
          .resizable()
          .scaledToFill()
      } else {
        ZStack {
          Theme.mark
          Image(systemName: "bird.fill")
            .font(.system(size: size * 0.34, weight: .semibold))
            .foregroundStyle(.white)
        }
      }
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
        .stroke(Theme.line, lineWidth: 1)
    }
    .accessibilityHidden(true)
  }
}

struct HackleRow: View {
  @Environment(\.modelContext) private var context
  let bird: HackleRecord
  var compact = false

  var body: some View {
    HStack(spacing: compact ? 10 : 12) {
      HacklePhoto(name: bird.profilePicture, size: compact ? 44 : 56)
      VStack(alignment: .leading, spacing: compact ? 2 : 4) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(bird.name)
            .font(.system(size: compact ? 16 : 18, weight: .semibold))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
          Text(bird.wristband)
            .font(.system(size: compact ? 12 : 14, weight: .semibold))
            .foregroundStyle(Theme.orange)
            .lineLimit(1)
        }
        if let meta = rowMeta {
          Text(meta)
            .font(.system(size: compact ? 11 : 12, weight: .medium))
            .foregroundStyle(Theme.mute)
            .lineLimit(1)
        }
        if !compact, let pedigree = pedigreeLine {
          Text(pedigree)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.mute)
            .lineLimit(1)
        }
      }
      Spacer(minLength: 8)
      VStack(alignment: .trailing, spacing: 4) {
        VisibilityBadge(isPublic: bird.isPublic)
        if !compact, let status = bird.status, !status.isEmpty {
          StatusBadge(status: status)
        }
      }
    }
    .padding(.vertical, compact ? 2 : 6)
  }

  private var rowMeta: String? {
    var parts: [String] = []
    if let sex = bird.sex, !sex.isEmpty { parts.append(sex) }
    if let weight = bird.weightKg {
      parts.append(String(format: "%.2f kg", weight))
    }
    if let hatch = bird.hatchDate {
      if compact {
        if let age = HackleAge.description(from: hatch) {
          parts.append(age)
        }
      } else {
        parts.append(hatch.formatted(date: .abbreviated, time: .omitted))
        if let age = HackleAge.description(from: hatch) {
          parts.append(age)
        }
      }
    }
    if compact, let status = bird.status, !status.isEmpty, status != "Active" {
      parts.append(status)
    }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }

  private var pedigreeLine: String? {
    let sireName = bird.sireWristband.flatMap { try? Directory.hackle(wristband: $0, context: context)?.name }
    let damName = bird.damWristband.flatMap { try? Directory.hackle(wristband: $0, context: context)?.name }
    switch (sireName, damName) {
    case let (sire?, dam?):
      return "\(sire) x \(dam)"
    case let (sire?, nil):
      return "\(sire) x —"
    case let (nil, dam?):
      return "— x \(dam)"
    case (nil, nil):
      return nil
    }
  }
}

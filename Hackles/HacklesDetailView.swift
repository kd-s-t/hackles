import SwiftData
import SwiftUI

struct HacklesDetailView: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  let wristband: String
  var path: SearchPath
  @State private var bird: HackleRecord?
  @State private var sire: HackleRecord?
  @State private var dam: HackleRecord?
  @State private var missing = false
  @State private var blocked = false
  @State private var showCodes = false
  @State private var errorMessage: String?

  private var owns: Bool {
    bird?.ownerEmail == auth.account?.email
  }

  var body: some View {
    Group {
      if let errorMessage {
        Notice(text: errorMessage, tone: Theme.danger)
          .padding(24)
      } else if missing {
        ContentUnavailableView(
          "Hackle not found",
          systemImage: "bird",
          description: Text("No hackle is registered with wristband \(wristband).")
        )
      } else if blocked {
        ContentUnavailableView(
          "Private hackle",
          systemImage: "lock",
          description: Text("This hackle is not public.")
        )
      } else if let bird {
        detail(bird)
      } else {
        ProgressView()
          .tint(Theme.red)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.paper)
    .navigationTitle(bird?.name ?? wristband)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        HStack(spacing: 12) {
          if bird != nil {
            Button {
              showCodes = true
            } label: {
              Image(systemName: "barcode")
            }
            .accessibilityLabel("Wristband codes")
          }
          if owns, let bird {
            Button("Edit") {
              switch path {
              case .guest:
                break
              case .home(let home):
                home.wrappedValue.append(.edit(bird.wristband))
              }
            }
          }
        }
      }
    }
    .sheet(isPresented: $showCodes) {
      WristbandCodesSheet(value: wristband)
    }
    .task { load() }
    .onAppear { load() }
  }

  private func detail(_ bird: HackleRecord) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HacklePhoto(name: bird.profilePicture, size: 220)
          .frame(maxWidth: .infinity)

        VStack(alignment: .leading, spacing: 8) {
          Button {
            showCodes = true
          } label: {
            HStack(spacing: 6) {
              Text(bird.wristband)
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Theme.orange)
              Image(systemName: "barcode")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.orange)
            }
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Show wristband codes")

          Text(bird.name)
            .font(.system(size: 40, weight: .regular, design: .serif))
            .foregroundStyle(Theme.ink)
          if let pedigree = pedigreeLine {
            Text(pedigree)
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(Theme.mute)
          }
          VisibilityBadge(isPublic: bird.isPublic)
          if let status = bird.status, !status.isEmpty {
            StatusBadge(status: status)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Theme.line, lineWidth: 1)
        }

        biodataCard(bird)

        if let sire = visibleParent(sire) {
          parentCard(role: "Sire", bird: sire)
        }
        if let dam = visibleParent(dam) {
          parentCard(role: "Dam", bird: dam)
        }
      }
      .padding(24)
    }
  }

  private var pedigreeLine: String? {
    let sireName = visibleParent(sire)?.name
    let damName = visibleParent(dam)?.name
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

  private func biodataCard(_ bird: HackleRecord) -> some View {
    let rows = biodataRows(bird)
    return Group {
      if !rows.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          Text("BIODATA")
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.6)
            .foregroundStyle(Theme.red)
          ForEach(rows, id: \.label) { row in
            HStack(alignment: .top) {
              Text(row.label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.mute)
                .frame(width: 110, alignment: .leading)
              Text(row.value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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
    }
  }

  private func biodataRows(_ bird: HackleRecord) -> [(label: String, value: String)] {
    var rows: [(String, String)] = []
    if let sex = bird.sex, !sex.isEmpty { rows.append(("Sex", sex)) }
    if let weight = bird.weightKg {
      rows.append(("Weight", String(format: "%.2f kg", weight)))
    }
    if let hatch = bird.hatchDate {
      rows.append(("Hatch", hatch.formatted(date: .abbreviated, time: .omitted)))
      if let age = HackleAge.description(from: hatch) {
        rows.append(("Age", age))
      }
    }
    if let bloodline = bird.bloodline, !bloodline.isEmpty { rows.append(("Bloodline", bloodline)) }
    if let color = bird.color, !color.isEmpty { rows.append(("Color", color)) }
    if let comb = bird.combType, !comb.isEmpty { rows.append(("Comb", comb)) }
    if let spur = bird.spurLengthCm {
      rows.append(("Spur", String(format: "%.1f cm", spur)))
    }
    if let status = bird.status, !status.isEmpty {
      rows.append(("Status", status))
    }
    if let farm = bird.farm, !farm.isEmpty { rows.append(("Yard", farm)) }
    if let country = bird.country, !country.isEmpty { rows.append(("Country", country)) }
    if let notes = bird.notes, !notes.isEmpty { rows.append(("Notes", notes)) }
    return rows
  }

  private func parentCard(role: String, bird: HackleRecord) -> some View {
    Button {
      path.open(bird.wristband)
    } label: {
      HStack(spacing: 12) {
        HacklePhoto(name: bird.profilePicture, size: 52)
        VStack(alignment: .leading, spacing: 4) {
          Text(role)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.mute)
          Text(bird.name)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Theme.ink)
          Text(bird.wristband)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.orange)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundStyle(Theme.mute)
      }
      .padding(20)
      .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(Theme.line, lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
  }

  private func visibleParent(_ parent: HackleRecord?) -> HackleRecord? {
    guard let parent else { return nil }
    let viewerOwnsParent = parent.ownerEmail == auth.account?.email
    if parent.isPublic || owns || viewerOwnsParent {
      return parent
    }
    return nil
  }

  private func load() {
    do {
      guard let found = try Directory.hackle(wristband: wristband, context: context) else {
        bird = nil
        sire = nil
        dam = nil
        missing = true
        blocked = false
        return
      }
      let viewerOwns = found.ownerEmail == auth.account?.email
      if !found.isPublic && !viewerOwns {
        bird = nil
        sire = nil
        dam = nil
        missing = false
        blocked = true
        return
      }
      bird = found
      missing = false
      blocked = false
      if let sireBand = found.sireWristband {
        sire = try Directory.hackle(wristband: sireBand, context: context)
      } else {
        sire = nil
      }
      if let damBand = found.damWristband {
        dam = try Directory.hackle(wristband: damBand, context: context)
      } else {
        dam = nil
      }
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

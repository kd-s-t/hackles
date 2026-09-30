import SwiftData
import SwiftUI

struct HacklesFormView: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  let existingWristband: String?
  var mode: RegisterMode = .old

  @State private var wristband = ""
  @State private var name = ""
  @State private var sireWristband = ""
  @State private var damWristband = ""
  @State private var details = HackleBiodata()
  @State private var weightText = ""
  @State private var spurText = ""
  @State private var hasHatchDate = false
  @State private var isPublic = false
  @State private var errorMessage: String?
  @State private var infoMessage: String?
  @State private var loaded = false
  @State private var showScanner = false
  @State private var generating = false
  @State private var checking = false
  @State private var pickingParent: ParentPickRole?
  @State private var yards: [OwnerYard] = []

  private var isEditing: Bool { existingWristband != nil }

  var body: some View {
    ScreenColumn(
      kicker: "HACKLE",
      title: title,
      subtitle: subtitle
    ) {
      VStack(alignment: .leading, spacing: 14) {
        wristbandSection
        AuthField(title: "Name", text: $name, capitalization: .words, allowsAutocorrection: true)

        parentField(
          role: .sire,
          text: $sireWristband,
          note: parentNote(role: "Sire", band: sireWristband)
        )
        parentField(
          role: .dam,
          text: $damWristband,
          note: parentNote(role: "Dam", band: damWristband)
        )
        Text("Leave Sire or Dam blank when unknown. Search to pick from registered hackles.")
          .font(.system(size: 13))
          .foregroundStyle(Theme.mute)

        biodataSection

        Toggle(isOn: $isPublic) {
          VStack(alignment: .leading, spacing: 4) {
            Text(isPublic ? "Public" : "Private")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(Theme.ink)
            Text(isPublic ? "Anyone can search this hackle." : "Hidden from search.")
              .font(.system(size: 13))
              .foregroundStyle(Theme.mute)
          }
        }
        .tint(Theme.orange)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Theme.line, lineWidth: 1)
        }
        BrandButton(
          title: isEditing ? "Save" : "Register",
          busy: auth.isSubmitting || checking
        ) {
          Task { await save() }
        }
        .disabled(auth.isSubmitting || generating || checking)
        if isEditing {
          Button("Delete hackle") {
            remove()
          }
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Theme.danger)
          .frame(maxWidth: .infinity)
          .padding(.top, 4)
        }
        if let infoMessage {
          Notice(text: infoMessage)
        }
        if let errorMessage {
          Notice(text: errorMessage, tone: Theme.danger)
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("")
    .task { await prepare() }
    .sheet(isPresented: $showScanner) {
      WristbandScannerView(
        onCode: { code in
          wristband = Directory.normalizeBand(code)
          showScanner = false
          errorMessage = nil
          infoMessage = "Wristband scanned."
        },
        onCancel: { showScanner = false }
      )
      .ignoresSafeArea()
    }
    .sheet(item: $pickingParent) { role in
      HacklesPickerSheet(
        role: role,
        excludingWristband: wristband
      ) { bird in
        switch role {
        case .sire:
          sireWristband = bird.wristband
        case .dam:
          damWristband = bird.wristband
        }
      }
    }
  }

  private func parentField(
    role: ParentPickRole,
    text: Binding<String>,
    note: (text: String, found: Bool)?
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      AuthField(
        title: "\(role.title) wristband",
        text: text,
        capitalization: .characters
      )
      HStack(spacing: 10) {
        Button {
          pickingParent = role
        } label: {
          Label("Search & select", systemImage: "magnifyingglass")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.red)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.line, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)

        if !text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Button("Clear") {
            text.wrappedValue = ""
          }
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Theme.mute)
          .frame(height: 44)
          .padding(.horizontal, 14)
          .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .stroke(Theme.line, lineWidth: 1)
          }
          .buttonStyle(.plain)
        }
      }
      if let note {
        Text(note.text)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(note.found ? Theme.red : Theme.danger)
      }
    }
  }

  private var title: String {
    if isEditing { return "Edit hackle" }
    return mode == .old ? "Old hackle" : "New hackle"
  }

  private var subtitle: String {
    if isEditing { return "Update parents, weight, and biodata." }
    if mode == .old {
      return "Scan the wristband already attached to this hackle."
    }
    return "A new wristband id is generated and checked so it is not already used."
  }

  @ViewBuilder
  private var wristbandSection: some View {
    if isEditing {
      AuthField(title: "Wristband", text: $wristband, capitalization: .characters)
        .disabled(true)
        .opacity(0.6)
      WristbandCodesView(value: wristband)
    } else if mode == .old {
      AuthField(title: "Wristband", text: $wristband, capitalization: .characters)
      BrandButton(title: "Scan wristband") {
        showScanner = true
      }
      Text("Or type the wristband id if you cannot scan it.")
        .font(.system(size: 13))
        .foregroundStyle(Theme.mute)
      WristbandCodesView(value: wristband)
    } else {
      AuthField(title: "Wristband", text: $wristband, capitalization: .characters)
        .disabled(true)
        .opacity(0.85)
      LineButton(title: generating ? "Generating…" : "Generate new id", busy: generating) {
        Task { await generateWristband() }
      }
      .disabled(generating)
      Text("Checked against registered hackle ids.")
        .font(.system(size: 13))
        .foregroundStyle(Theme.mute)
      WristbandCodesView(value: wristband)
    }
  }

  private var biodataSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("BIODATA")
        .font(.system(size: 12, weight: .semibold))
        .tracking(1.6)
        .foregroundStyle(Theme.red)

      choiceRow(title: "Sex", options: HackleSex.allCases.map(\.rawValue), selection: $details.sex)
      AuthField(title: "Weight (kg)", text: $weightText, keyboard: .decimalPad)
      AuthField(title: "Bloodline", text: $details.bloodline, capitalization: .words, allowsAutocorrection: true)
      AuthField(title: "Color", text: $details.color, capitalization: .words, allowsAutocorrection: true)
      choiceRow(title: "Comb", options: HackleComb.allCases.map(\.rawValue), selection: $details.combType)
      AuthField(title: "Spur length (cm)", text: $spurText, keyboard: .decimalPad)
      statusPicker
      farmPicker
      AuthField(title: "Country", text: $details.country, capitalization: .words, allowsAutocorrection: true)

      Toggle(isOn: $hasHatchDate) {
        Text("Hatch date")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Theme.ink)
      }
      .tint(Theme.orange)
      if hasHatchDate {
        DatePicker(
          "Hatch date",
          selection: Binding(
            get: { details.hatchDate ?? .now },
            set: { details.hatchDate = $0 }
          ),
          displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .tint(Theme.orange)
        if let age = HackleAge.description(from: details.hatchDate ?? .now) {
          Text("Age: \(age)")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Theme.mute)
        }
      }

      AuthField(title: "Notes", text: $details.notes, capitalization: .sentences, allowsAutocorrection: true)
    }
  }

  private var statusPicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Status")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Theme.mute)
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
        ForEach(HackleStatus.allCases) { status in
          let selected = details.status == status.rawValue
          Button {
            details.status = status.rawValue
          } label: {
            Text(status.rawValue)
              .font(.system(size: 15, weight: .semibold))
              .foregroundStyle(selected ? Theme.onFill : Theme.ink)
              .frame(maxWidth: .infinity)
              .frame(height: 48)
              .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                  .fill(selected ? Theme.orange : Theme.card)
              }
              .overlay {
                if !selected {
                  RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
                }
              }
          }
          .buttonStyle(.plain)
        }
      }
      if !details.status.isEmpty {
        Button("Clear status") {
          details.status = ""
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(Theme.mute)
      }
    }
  }

  private var farmPicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Yard")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Theme.mute)
      if yards.isEmpty {
        AuthField(title: "Yard name", text: $details.farm, capitalization: .words, allowsAutocorrection: true)
        Text("Add yards on Account to pick from a list.")
          .font(.system(size: 12))
          .foregroundStyle(Theme.mute)
      } else {
        Menu {
          Button("None") { details.farm = "" }
          ForEach(yards, id: \.id) { yard in
            Button(yard.name) {
              details.farm = yard.name
              if details.country.isEmpty, let country = yard.country, !country.isEmpty {
                details.country = country
              }
            }
          }
        } label: {
          HStack {
            Text(details.farm.isEmpty ? "Select yard" : details.farm)
              .foregroundStyle(details.farm.isEmpty ? Theme.mute : Theme.ink)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(Theme.mute)
          }
          .padding(.horizontal, 14)
          .frame(height: 54)
          .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .stroke(Theme.line, lineWidth: 1)
          }
        }
      }
    }
  }

  private func choiceRow(title: String, options: [String], selection: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Theme.mute)
      Menu {
        Button("Clear") { selection.wrappedValue = "" }
        ForEach(options, id: \.self) { option in
          Button(option) { selection.wrappedValue = option }
        }
      } label: {
        HStack {
          Text(selection.wrappedValue.isEmpty ? "Select" : selection.wrappedValue)
            .foregroundStyle(selection.wrappedValue.isEmpty ? Theme.mute : Theme.ink)
          Spacer()
          Image(systemName: "chevron.up.chevron.down")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.mute)
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Theme.line, lineWidth: 1)
        }
      }
    }
  }

  private func parentNote(role: String, band raw: String) -> (text: String, found: Bool)? {
    let band = Directory.normalizeBand(raw)
    guard !band.isEmpty else { return nil }
    if band == Directory.normalizeBand(wristband), !wristband.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return ("A hackle cannot be its own \(role).", false)
    }
    do {
      if let parent = try Directory.hackle(wristband: band, context: context) {
        return ("\(role): \(parent.name)", true)
      }
      return ("No hackle is registered with that \(role.lowercased()) wristband.", false)
    } catch {
      return (error.localizedDescription, false)
    }
  }

  private func prepare() async {
    guard !loaded else { return }
    loaded = true
    if let email = auth.account?.email {
      yards = (try? Directory.yards(ownedBy: email, context: context)) ?? []
    }
    if let existingWristband {
      do {
        guard let bird = try Directory.hackle(wristband: existingWristband, context: context) else {
          errorMessage = "That hackle is not registered."
          return
        }
        wristband = bird.wristband
        name = bird.name
        sireWristband = bird.sireWristband ?? ""
        damWristband = bird.damWristband ?? ""
        details = .from(bird)
        weightText = bird.weightKg.map { String(format: "%g", $0) } ?? ""
        spurText = bird.spurLengthCm.map { String(format: "%g", $0) } ?? ""
        hasHatchDate = bird.hatchDate != nil
        isPublic = bird.isPublic
      } catch {
        errorMessage = error.localizedDescription
      }
      return
    }
    if mode == .new {
      await generateWristband()
    }
  }

  private func generateWristband() async {
    generating = true
    errorMessage = nil
    defer { generating = false }
    do {
      wristband = try await WristbandFactory.generateUnique(context: context)
      infoMessage = "Wristband id is free."
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func assembledDetails() -> HackleBiodata? {
    var next = details
    if !hasHatchDate {
      next.hatchDate = nil
    } else if next.hatchDate == nil {
      next.hatchDate = .now
    }
    let weight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
    if weight.isEmpty {
      next.weightKg = nil
    } else if let value = Double(weight.replacingOccurrences(of: ",", with: ".")), value > 0 {
      next.weightKg = value
    } else {
      errorMessage = "Weight must be a number in kg."
      return nil
    }
    let spur = spurText.trimmingCharacters(in: .whitespacesAndNewlines)
    if spur.isEmpty {
      next.spurLengthCm = nil
    } else if let value = Double(spur.replacingOccurrences(of: ",", with: ".")), value >= 0 {
      next.spurLengthCm = value
    } else {
      errorMessage = "Spur length must be a number in cm."
      return nil
    }
    return next
  }

  private func save() async {
    guard let email = auth.account?.email else { return }
    guard let biodata = assembledDetails() else { return }
    checking = true
    errorMessage = nil
    defer { checking = false }
    do {
      if let existingWristband {
        try Directory.updateHackle(
          wristband: existingWristband,
          name: name,
          sireWristband: sireWristband,
          damWristband: damWristband,
          isPublic: isPublic,
          ownerEmail: email,
          details: biodata,
          context: context
        )
      } else {
        let band = Directory.normalizeBand(wristband)
        guard !band.isEmpty else {
          errorMessage = DirectoryError.wristbandRequired.localizedDescription
          return
        }
        if mode == .new {
          let free = try await WristbandFactory.isAvailableWorldwide(band, context: context)
          guard free else {
            errorMessage = "That wristband id is already used. Generate another."
            return
          }
        } else if try Directory.hackle(wristband: band, context: context) != nil {
          errorMessage = DirectoryError.duplicateWristband.localizedDescription
          return
        }
        _ = try Directory.registerHackle(
          wristband: band,
          name: name,
          sireWristband: sireWristband,
          damWristband: damWristband,
          isPublic: isPublic,
          ownerEmail: email,
          details: biodata,
          context: context
        )
      }
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func remove() {
    guard let email = auth.account?.email, let existingWristband else { return }
    do {
      try Directory.deleteHackle(wristband: existingWristband, ownerEmail: email, context: context)
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

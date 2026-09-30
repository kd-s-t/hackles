import PhotosUI
import SwiftData
import SwiftUI

struct AccountView: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  @State private var confirmDelete = false
  @State private var confirmCancelPremium = false
  @State private var showEdit = false
  @State private var showYardEditor = false
  @State private var showPremium = false
  @State private var premiumGate: PremiumGate?
  @State private var editingYard: OwnerYard?
  @State private var flock: [HackleRecord] = []
  @State private var yards: [OwnerYard] = []

  var body: some View {
    if let account = auth.account {
      ZStack {
        Theme.paper.ignoresSafeArea()
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            Text("ACCOUNT")
              .font(.system(size: 12, weight: .semibold))
              .tracking(1.6)
              .foregroundStyle(Theme.red)

            OwnerPhoto(
              name: account.profilePicture,
              size: 112,
              initials: OwnerInitials.from(name: account.name)
            )
            .frame(maxWidth: .infinity)
            .padding(.top, 18)

            Text(account.name)
              .font(.system(size: 40, weight: .regular, design: .serif))
              .foregroundStyle(Theme.ink)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
              .padding(.top, 14)

            Text(account.email)
              .font(.system(size: 16))
              .foregroundStyle(Theme.mute)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
              .padding(.top, 8)

            VStack(alignment: .leading, spacing: 16) {
              profileCard(account)
              PremiumCard(
                isPremium: account.isPremium,
                yardCount: yards.count,
                hackleCount: flock.count,
                onGetPremium: {
                  premiumGate = nil
                  showPremium = true
                },
                onCancelPremium: {
                  confirmCancelPremium = true
                }
              )
              yardsCard(isPremium: account.isPremium)
              flockCard(isPremium: account.isPremium)
              LineButton(title: "Edit profile") {
                showEdit = true
              }
              BrandButton(title: "Sign out") {
                auth.logout()
              }
              Button("Delete account") {
                confirmDelete = true
              }
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(Theme.danger)
              .frame(maxWidth: .infinity)
              .padding(.top, 4)
              .disabled(auth.isSubmitting)
              if let errorMessage = auth.errorMessage {
                Notice(text: errorMessage, tone: Theme.danger)
              }
            }
            .padding(.top, 28)
          }
          .padding(.horizontal, 24)
          .padding(.top, 12)
          .padding(.bottom, 120)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle("Account")
      .task { reload(for: account.email) }
      .onAppear { reload(for: account.email) }
      .sheet(isPresented: $showEdit) {
        EditOwnerProfileSheet(account: account)
      }
      .sheet(isPresented: $showYardEditor, onDismiss: {
        editingYard = nil
        reload(for: account.email)
      }) {
        EditYardSheet(ownerEmail: account.email, yard: editingYard)
      }
      .sheet(isPresented: $showPremium, onDismiss: {
        premiumGate = nil
        reload(for: account.email)
      }) {
        PremiumPaywallSheet(gate: premiumGate)
      }
      .confirmationDialog(
        "Cancel Premium?",
        isPresented: $confirmCancelPremium,
        titleVisibility: .visible
      ) {
        Button("Cancel Premium", role: .destructive) {
          auth.setPremium(false, context: context)
          reload(for: account.email)
        }
        Button("Keep Premium", role: .cancel) {}
      } message: {
        Text("Returns this account to the free plan so you can test yard and hackle limits again.")
      }
      .confirmationDialog(
        "Delete this account?",
        isPresented: $confirmDelete,
        titleVisibility: .visible
      ) {
        Button("Delete account", role: .destructive) {
          auth.deleteAccount(context: context)
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("This removes your account, yards, and every hackle you own. This cannot be undone.")
      }
    }
  }

  private func profileCard(_ account: Account) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("OWNER")
        .font(.system(size: 12, weight: .semibold))
        .tracking(1.6)
        .foregroundStyle(Theme.red)

      detailRow("Name", account.name)
      detailRow("Email", account.email)
      if let country = account.country, !country.isEmpty {
        detailRow("Country", country)
      }
      if let phone = account.phone, !phone.isEmpty {
        detailRow("Phone", phone)
      }
      detailRow("Member since", account.createdAt.formatted(date: .abbreviated, time: .omitted))
      detailRow("Sign-in", account.signInLabel)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(Theme.line, lineWidth: 1)
    }
  }

  private func yardsCard(isPremium: Bool) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("YARDS")
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.6)
            .foregroundStyle(Theme.red)
          Text("Places where your hackles are raised.")
            .font(.system(size: 13))
            .foregroundStyle(Theme.mute)
        }
        Spacer()
        Button {
          if PremiumPlan.canAddYard(isPremium: isPremium, currentCount: yards.count) {
            editingYard = nil
            showYardEditor = true
          } else {
            premiumGate = .yard
            showPremium = true
          }
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.red)
            .frame(width: 32, height: 32)
            .background(Theme.orange.opacity(0.14), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add yard")
      }

      if !isPremium {
        Text("\(yards.count) / \(PremiumPlan.freeYardLimit) free yards used")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Theme.mute)
      }

      if yards.isEmpty {
        Text("No yards yet. Add your farm or conditioning pens.")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Theme.mute)
          .padding(.top, 4)
      } else {
        ForEach(yards, id: \.id) { yard in
          Button {
            editingYard = yard
            showYardEditor = true
          } label: {
            HStack(alignment: .top, spacing: 12) {
              Image(systemName: "leaf.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.orange)
                .frame(width: 28, height: 28)
                .background(Theme.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
              VStack(alignment: .leading, spacing: 3) {
                Text(yard.name)
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(Theme.ink)
                if !yard.subtitle.isEmpty {
                  Text(yard.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.mute)
                }
                if let notes = yard.notes, !notes.isEmpty {
                  Text(notes)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.mute)
                    .lineLimit(2)
                }
              }
              Spacer(minLength: 0)
              Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.mute)
            }
            .padding(.vertical, 4)
          }
          .buttonStyle(.plain)
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

  private func flockCard(isPremium: Bool) -> some View {
    let publicCount = flock.filter(\.isPublic).count
    let activeCount = flock.filter { ($0.status ?? "Active") == "Active" }.count
    let broodCount = flock.filter { $0.status == "Brood" }.count
    let deceasedCount = flock.filter { $0.status == "Deceased" }.count

    return VStack(alignment: .leading, spacing: 12) {
      Text("FLOCK")
        .font(.system(size: 12, weight: .semibold))
        .tracking(1.6)
        .foregroundStyle(Theme.red)

      if isPremium {
        detailRow("Hackles", "\(flock.count)")
        detailRow("Yards", "\(yards.count)")
      } else {
        detailRow("Hackles", "\(flock.count) / \(PremiumPlan.freeHackleLimit)")
        detailRow("Yards", "\(yards.count) / \(PremiumPlan.freeYardLimit)")
      }
      detailRow("Public", "\(publicCount)")
      detailRow("Active", "\(activeCount)")
      if broodCount > 0 {
        detailRow("Brood", "\(broodCount)")
      }
      if deceasedCount > 0 {
        detailRow("Deceased", "\(deceasedCount)")
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
    HStack(alignment: .top) {
      Text(label)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(Theme.mute)
        .frame(width: 110, alignment: .leading)
      Text(value)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func reload(for email: String) {
    flock = (try? Directory.owned(by: email, context: context)) ?? []
    yards = (try? Directory.yards(ownedBy: email, context: context)) ?? []
  }
}

private struct EditYardSheet: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  let ownerEmail: String
  let yard: OwnerYard?

  @State private var name: String
  @State private var location: String
  @State private var country: String
  @State private var notes: String
  @State private var errorMessage: String?
  @State private var confirmDelete = false
  @State private var saving = false

  init(ownerEmail: String, yard: OwnerYard?) {
    self.ownerEmail = ownerEmail
    self.yard = yard
    _name = State(initialValue: yard?.name ?? "")
    _location = State(initialValue: yard?.location ?? "")
    _country = State(initialValue: yard?.country ?? "")
    _notes = State(initialValue: yard?.notes ?? "")
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          Text("A yard is a farm or pen where you raise hackles.")
            .font(.system(size: 14))
            .foregroundStyle(Theme.mute)
          AuthField(title: "Yard name", text: $name, capitalization: .words, allowsAutocorrection: true)
          AuthField(title: "Location", text: $location, capitalization: .words, allowsAutocorrection: true)
          AuthField(title: "Country", text: $country, content: .countryName, capitalization: .words, allowsAutocorrection: true)
          AuthField(title: "Notes", text: $notes, capitalization: .sentences, allowsAutocorrection: true)
          BrandButton(title: yard == nil ? "Add yard" : "Save", busy: saving) {
            save()
          }
          if yard != nil {
            Button("Delete yard") {
              confirmDelete = true
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.danger)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
          }
          if let errorMessage {
            Notice(text: errorMessage, tone: Theme.danger)
          }
        }
        .padding(24)
      }
      .background(Theme.paper)
      .navigationTitle(yard == nil ? "Add yard" : "Edit yard")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .confirmationDialog(
        "Delete this yard?",
        isPresented: $confirmDelete,
        titleVisibility: .visible
      ) {
        Button("Delete yard", role: .destructive) {
          deleteYard()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Hackles stay registered. Only this yard listing is removed.")
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private func save() {
    saving = true
    errorMessage = nil
    defer { saving = false }
    do {
      _ = try Directory.upsertYard(
        id: yard?.id,
        ownerEmail: ownerEmail,
        name: name,
        location: location,
        country: country,
        notes: notes,
        context: context
      )
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func deleteYard() {
    guard let yard else { return }
    do {
      try Directory.deleteYard(id: yard.id, ownerEmail: ownerEmail, context: context)
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

private struct EditOwnerProfileSheet: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  let account: Account

  @State private var name: String
  @State private var email: String
  @State private var country: String
  @State private var phone: String
  @State private var photoKey: String?
  @State private var pickerItem: PhotosPickerItem?
  @State private var photoError: String?

  init(account: Account) {
    self.account = account
    _name = State(initialValue: account.name)
    _email = State(initialValue: account.email)
    _country = State(initialValue: account.country ?? "")
    _phone = State(initialValue: account.phone ?? "")
    _photoKey = State(initialValue: account.profilePicture)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          HStack(spacing: 16) {
            OwnerPhoto(
              name: photoKey,
              size: 84,
              initials: OwnerInitials.from(name: name.isEmpty ? account.name : name)
            )
            VStack(alignment: .leading, spacing: 8) {
              PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                Text("Choose photo")
                  .font(.system(size: 15, weight: .semibold))
                  .foregroundStyle(Theme.red)
              }
              if photoKey != nil {
                Button("Remove photo") {
                  if let key = photoKey, OwnerPhotoStore.isFileKey(key) {
                    OwnerPhotoStore.delete(key)
                  }
                  photoKey = nil
                  pickerItem = nil
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.mute)
              }
            }
            Spacer(minLength: 0)
          }
          .padding(.bottom, 4)

          if let photoError {
            Notice(text: photoError, tone: Theme.danger)
          }

          AuthField(title: "Name", text: $name, content: .name, capitalization: .words, allowsAutocorrection: true)
          AuthField(title: "Email", text: $email, content: .username, keyboard: .emailAddress)
          AuthField(title: "Country", text: $country, content: .countryName, capitalization: .words, allowsAutocorrection: true)
          AuthField(title: "Phone", text: $phone, content: .telephoneNumber, keyboard: .phonePad)
          BrandButton(title: "Save", busy: auth.isSubmitting) {
            if auth.updateProfile(
              name: name,
              email: email,
              farm: account.farm ?? "",
              country: country,
              phone: phone,
              profilePicture: photoKey,
              context: context
            ) {
              dismiss()
            }
          }
          if let errorMessage = auth.errorMessage {
            Notice(text: errorMessage, tone: Theme.danger)
          }
        }
        .padding(24)
      }
      .background(Theme.paper)
      .navigationTitle("Edit profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .onChange(of: pickerItem) { _, item in
        Task { await loadPhoto(item) }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .onAppear { auth.clearMessages() }
  }

  private func loadPhoto(_ item: PhotosPickerItem?) async {
    guard let item else { return }
    photoError = nil
    do {
      guard let data = try await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data) else {
        photoError = "Could not read that photo."
        return
      }
      let key = try OwnerPhotoStore.save(image, for: account.email)
      await MainActor.run {
        photoKey = key
      }
    } catch {
      await MainActor.run {
        photoError = error.localizedDescription
      }
    }
  }
}

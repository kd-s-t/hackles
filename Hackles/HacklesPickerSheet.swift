import SwiftData
import SwiftUI

enum ParentPickRole: String, Identifiable {
  case sire = "Sire"
  case dam = "Dam"
  var id: String { rawValue }
  var title: String { rawValue }
}

struct HacklesPickerSheet: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  let role: ParentPickRole
  let excludingWristband: String?
  let onSelect: (HackleRecord) -> Void

  @State private var query = ""
  @State private var birds: [HackleRecord] = []
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        AuthField(title: "Search \(role.title)", text: $query, capitalization: .characters)
          .padding(.horizontal, 24)
          .padding(.top, 12)
          .padding(.bottom, 8)
          .onChange(of: query) { _, _ in
            reload()
          }

        Group {
          if let errorMessage {
            Notice(text: errorMessage, tone: Theme.danger)
              .padding(24)
          } else if birds.isEmpty {
            ContentUnavailableView(
              query.isEmpty ? "No hackles yet" : "No match",
              systemImage: "magnifyingglass",
              description: Text(
                query.isEmpty
                  ? "Register a hackle first, then pick one as \(role.title)."
                  : "No hackle matches that wristband or name."
              )
            )
          } else {
            List(birds, id: \.wristband) { bird in
              Button {
                onSelect(bird)
                dismiss()
              } label: {
                HackleRow(bird: bird)
              }
              .buttonStyle(.plain)
              .listRowBackground(Theme.card)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Theme.paper)
      .navigationTitle("Select \(role.title)")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .task { reload() }
    }
  }

  private func reload() {
    do {
      birds = try Directory.searchableHackles(
        matching: query,
        excluding: excludingWristband,
        context: context
      )
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

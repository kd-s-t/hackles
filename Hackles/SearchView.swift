import SwiftData
import SwiftUI

enum SearchPath {
  case guest(Binding<[GuestRoute]>)
  case home(Binding<[HomeRoute]>)

  func open(_ wristband: String) {
    switch self {
    case .guest(let path):
      path.wrappedValue.append(.detail(wristband))
    case .home(let path):
      path.wrappedValue.append(.detail(wristband))
    }
  }
}

struct SearchView: View {
  @Environment(\.modelContext) private var context
  var path: SearchPath
  @State private var query = ""
  @State private var birds: [HackleRecord] = []
  @State private var filters = HacklesListFilters()
  @State private var errorMessage: String?

  private var filteredBirds: [HackleRecord] {
    birds.filter(filters.matches)
  }

  private var yardNames: [String] {
    Array(
      Set(
        birds.compactMap { bird -> String? in
          let farm = (bird.farm ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
          return farm.isEmpty ? nil : farm
        }
      )
    ).sorted()
  }

  private var yardSections: [HacklesYardSection] {
    HacklesYardSection.build(from: filteredBirds, preferredOrder: yardNames)
  }

  var body: some View {
    VStack(spacing: 0) {
      if !birds.isEmpty || filters.isActive {
        HacklesFilterBar(filters: $filters, yards: yardNames, resultCount: filteredBirds.count)
      }

      Group {
        if let errorMessage {
          Notice(text: errorMessage, tone: Theme.danger)
            .padding(16)
        } else if birds.isEmpty {
          ContentUnavailableView(
            queryTrimmed.isEmpty ? "No public hackles" : "No match",
            systemImage: "magnifyingglass",
            description: Text(
              queryTrimmed.isEmpty
                ? "Public hackles show up here."
                : "No match for that wristband or name."
            )
          )
        } else if filteredBirds.isEmpty {
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
                    path.open(bird.wristband)
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
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.paper)
    .navigationTitle("Search")
    .navigationBarTitleDisplayMode(.inline)
    .searchable(
      text: $query,
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: "Name or wristband"
    )
    .textInputAutocapitalization(.characters)
    .onChange(of: query) { _, _ in
      reload()
    }
    .task { reload() }
    .onAppear { reload() }
  }

  private var queryTrimmed: String {
    query.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func reload() {
    do {
      birds = try Directory.publicHackles(matching: query, context: context)
      errorMessage = nil
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

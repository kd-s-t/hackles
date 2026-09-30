import SwiftUI

struct HacklesListFilters {
  var sex = ""
  var yard = ""
  var hatchFrom: Date?
  var hatchTo: Date?

  var isActive: Bool {
    !sex.isEmpty || !yard.isEmpty || hatchFrom != nil || hatchTo != nil
  }

  func matches(_ bird: HackleRecord) -> Bool {
    if !sex.isEmpty, (bird.sex ?? "") != sex {
      return false
    }
    if !yard.isEmpty {
      let farm = (bird.farm ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      if yard == HacklesListFilters.noYardKey {
        if !farm.isEmpty { return false }
      } else if farm != yard {
        return false
      }
    }
    if let from = hatchFrom {
      guard let hatch = bird.hatchDate, hatch >= Self.dayStart(from) else { return false }
    }
    if let to = hatchTo {
      guard let hatch = bird.hatchDate, hatch <= Self.dayEnd(to) else { return false }
    }
    return true
  }

  mutating func clear() {
    sex = ""
    yard = ""
    hatchFrom = nil
    hatchTo = nil
  }

  static let noYardKey = "__none__"

  private static func dayStart(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
  }

  private static func dayEnd(_ date: Date) -> Date {
    let start = Calendar.current.startOfDay(for: date)
    return Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
  }
}

struct HacklesYardSection: Identifiable {
  let id: String
  let title: String
  let birds: [HackleRecord]

  static func build(
    from birds: [HackleRecord],
    preferredOrder: [String] = []
  ) -> [HacklesYardSection] {
    let grouped = Dictionary(grouping: birds) { bird -> String in
      let farm = (bird.farm ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      return farm.isEmpty ? HacklesListFilters.noYardKey : farm
    }

    var order: [String] = []
    for name in preferredOrder where grouped[name] != nil {
      order.append(name)
    }
    let extras = grouped.keys
      .filter { $0 != HacklesListFilters.noYardKey && !order.contains($0) }
      .sorted()
    order.append(contentsOf: extras)
    if grouped[HacklesListFilters.noYardKey] != nil {
      order.append(HacklesListFilters.noYardKey)
    }

    return order.compactMap { key in
      guard let rows = grouped[key], !rows.isEmpty else { return nil }
      let title = key == HacklesListFilters.noYardKey ? "No yard" : key
      return HacklesYardSection(id: key, title: title, birds: rows)
    }
  }
}

struct HacklesFilterBar: View {
  @Binding var filters: HacklesListFilters
  var yards: [String] = []
  let resultCount: Int
  @State private var showBirthFilter = false

  private var allSelected: Bool {
    filters.sex.isEmpty && filters.yard.isEmpty && !hasBirthFilter
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          chip(title: "All", selected: allSelected) {
            filters.clear()
          }
          ForEach(HackleSex.allCases) { sex in
            chip(title: sex.rawValue, selected: filters.sex == sex.rawValue) {
              filters.sex = sex.rawValue
            }
          }
          chip(title: birthTitle, selected: hasBirthFilter, systemImage: "calendar") {
            showBirthFilter = true
          }
          if filters.isActive {
            chip(title: "Clear", selected: false) {
              filters.clear()
            }
          }
          Text("\(resultCount)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.mute)
            .padding(.leading, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, yards.isEmpty ? 8 : 4)
      }

      if !yards.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            Text("Yard")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(Theme.mute)
            chip(title: "All yards", selected: filters.yard.isEmpty) {
              filters.yard = ""
            }
            ForEach(yards, id: \.self) { yard in
              chip(title: yard, selected: filters.yard == yard) {
                filters.yard = yard
              }
            }
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 8)
        }
      }
    }
    .background(Theme.paper)
    .sheet(isPresented: $showBirthFilter) {
      birthSheet
    }
  }

  private var hasBirthFilter: Bool {
    filters.hatchFrom != nil || filters.hatchTo != nil
  }

  private var birthTitle: String {
    switch (filters.hatchFrom, filters.hatchTo) {
    case let (from?, to?):
      return "\(short(from))–\(short(to))"
    case let (from?, nil):
      return "From \(short(from))"
    case let (nil, to?):
      return "To \(short(to))"
    case (nil, nil):
      return "DOB"
    }
  }

  private var birthSheet: some View {
    NavigationStack {
      Form {
        Section("Date of birth") {
          Toggle("From date", isOn: Binding(
            get: { filters.hatchFrom != nil },
            set: { on in
              filters.hatchFrom = on
                ? (filters.hatchFrom ?? Calendar.current.date(byAdding: .year, value: -3, to: .now))
                : nil
            }
          ))
          if filters.hatchFrom != nil {
            DatePicker(
              "From",
              selection: Binding(
                get: { filters.hatchFrom ?? .now },
                set: { filters.hatchFrom = $0 }
              ),
              displayedComponents: .date
            )
          }

          Toggle("To date", isOn: Binding(
            get: { filters.hatchTo != nil },
            set: { on in
              filters.hatchTo = on ? (filters.hatchTo ?? .now) : nil
            }
          ))
          if filters.hatchTo != nil {
            DatePicker(
              "To",
              selection: Binding(
                get: { filters.hatchTo ?? .now },
                set: { filters.hatchTo = $0 }
              ),
              displayedComponents: .date
            )
          }
        }
        Section {
          Button("Clear birth filter", role: .destructive) {
            filters.hatchFrom = nil
            filters.hatchTo = nil
          }
        }
      }
      .scrollContentBackground(.hidden)
      .background(Theme.paper)
      .navigationTitle("Date of birth")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { showBirthFilter = false }
        }
      }
    }
    .presentationDetents([.medium])
  }

  private func chip(
    title: String,
    selected: Bool,
    systemImage: String? = nil,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 5) {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.system(size: 12, weight: .semibold))
        }
        Text(title)
          .font(.system(size: 13, weight: .semibold))
      }
      .foregroundStyle(selected ? Theme.onFill : Theme.ink)
      .padding(.horizontal, 10)
      .frame(height: 32)
      .background(selected ? Theme.orange : Theme.card, in: Capsule())
      .overlay {
        if !selected {
          Capsule().stroke(Theme.line, lineWidth: 1)
        }
      }
    }
    .buttonStyle(.plain)
  }

  private func short(_ date: Date) -> String {
    date.formatted(date: .abbreviated, time: .omitted)
  }
}

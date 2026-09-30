import SwiftData
import SwiftUI

@main
struct HacklesApp: App {
  @State private var auth = AuthStore()
  private let container: ModelContainer

  init() {
    let schema = Schema([Account.self, HackleRecord.self, OwnerYard.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      container = try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      // Schema changed (for example Apple sign-in fields). Start clean on this phone.
      let url = configuration.url
      try? FileManager.default.removeItem(at: url)
      do {
        container = try ModelContainer(for: schema, configurations: [configuration])
      } catch {
        fatalError("Could not open the Hackles store. \(error.localizedDescription)")
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(auth)
    }
    .modelContainer(container)
  }
}

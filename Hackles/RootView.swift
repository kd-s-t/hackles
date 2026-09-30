import SwiftData
import SwiftUI

enum HomeRoute: Hashable {
  case registerChoice
  case register(RegisterMode)
  case detail(String)
  case edit(String)
}

private enum ShellTab: Hashable {
  case mine
  case search
  case account
}

struct RootView: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  @State private var guestPath: [GuestRoute] = []
  @State private var minePath: [HomeRoute] = []
  @State private var searchPath: [HomeRoute] = []
  @State private var tab: ShellTab = .mine

  var body: some View {
    Group {
      if auth.isBootstrapping {
        Theme.paper.ignoresSafeArea()
      } else if auth.isSignedIn {
        signedIn
      } else {
        signedOut
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.paper.ignoresSafeArea())
    .tint(Theme.red)
    .preferredColorScheme(.light)
    .task {
      auth.bootstrap(context: context)
    }
    .onChange(of: auth.isSignedIn) { _, signedIn in
      guestPath = []
      minePath = []
      searchPath = []
      tab = .mine
      if !signedIn {
        auth.clearMessages()
      }
    }
  }

  private var signedOut: some View {
    NavigationStack(path: $guestPath) {
      LoginView(path: $guestPath)
        .navigationDestination(for: GuestRoute.self) { route in
          switch route {
          case .signUp:
            SignUpView()
          case .forgot:
            ForgotPasswordView()
          case .search:
            SearchView(path: .guest($guestPath))
          case .detail(let wristband):
            HacklesDetailView(wristband: wristband, path: .guest($guestPath))
          }
        }
    }
  }

  private var signedIn: some View {
    TabView(selection: $tab) {
      Tab(value: ShellTab.mine) {
        NavigationStack(path: $minePath) {
          MyHacklesView(path: $minePath)
            .navigationDestination(for: HomeRoute.self) { route in
              homeDestination(route, path: $minePath)
            }
        }
      } label: {
        Label("My hackles", image: "HacklesTab")
      }
      Tab("Search", systemImage: "magnifyingglass", value: ShellTab.search) {
        NavigationStack(path: $searchPath) {
          SearchView(path: .home($searchPath))
            .navigationDestination(for: HomeRoute.self) { route in
              homeDestination(route, path: $searchPath)
            }
        }
      }
      Tab("Account", systemImage: "person", value: ShellTab.account) {
        AccountView()
      }
    }
  }

  @ViewBuilder
  private func homeDestination(_ route: HomeRoute, path: Binding<[HomeRoute]>) -> some View {
    switch route {
    case .registerChoice:
      RegisterChoiceView(path: path)
    case .register(let mode):
      HacklesFormView(existingWristband: nil, mode: mode)
    case .detail(let wristband):
      HacklesDetailView(wristband: wristband, path: .home(path))
    case .edit(let wristband):
      HacklesFormView(existingWristband: wristband)
    }
  }
}

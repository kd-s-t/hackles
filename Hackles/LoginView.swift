import SwiftData
import SwiftUI

enum GuestRoute: Hashable {
  case signUp
  case forgot
  case search
  case detail(String)
}

struct LoginView: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  @Binding var path: [GuestRoute]
  @State private var email = SampleLogin.email
  @State private var password = SampleLogin.password
  @State private var emailBusy = false
  @State private var apple = AppleSignInPresenter()
  @State private var appleBusy = false

  var body: some View {
    ScreenColumn(
      kicker: "",
      title: "Hackles",
      subtitle: "",
      showsMark: true
    ) {
      VStack(alignment: .leading, spacing: 14) {
        AuthField(title: "Email", text: $email, content: .username, keyboard: .emailAddress)
        AuthField(title: "Password", text: $password, secure: true, content: .password)
        HStack {
          Spacer()
          Button("Forgot password") {
            path.append(.forgot)
          }
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Theme.orange)
        }
        BrandButton(title: "Sign in", busy: emailBusy) {
          Task { await signIn() }
        }
        .disabled(emailBusy || appleBusy)
        Text("Sample login is filled in. Tap Sign in.")
          .font(.system(size: 13))
          .foregroundStyle(Theme.mute)
        if let infoMessage = auth.infoMessage {
          Notice(text: infoMessage)
        }
        if let errorMessage = auth.errorMessage {
          Notice(text: errorMessage, tone: Theme.danger)
        }
        appleButton
        LineButton(title: "Create account") {
          path.append(.signUp)
        }
        .disabled(emailBusy || appleBusy)
        Button("Search public hackles") {
          path.append(.search)
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Theme.red)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("")
    .task {
      auth.errorMessage = nil
    }
  }

  private var appleButton: some View {
    Button {
      guard !emailBusy, !appleBusy else { return }
      appleBusy = true
      apple.onFinish = { result in
        Task { @MainActor in
          auth.handleAppleCompletion(result, context: context)
          appleBusy = false
        }
      }
      apple.start { request in
        auth.prepareAppleRequest(request)
      }
    } label: {
      ZStack {
        HStack(spacing: 10) {
          Image(systemName: "apple.logo")
          Text("Sign in with Apple")
        }
        .opacity(appleBusy ? 0 : 1)
        if appleBusy {
          ProgressView()
            .tint(.white)
        }
      }
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 54)
      .background(Color.black, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(emailBusy || appleBusy)
    .padding(.top, 4)
  }

  private func signIn() async {
    emailBusy = true
    defer { emailBusy = false }
    auth.login(email: email, password: password, context: context)
  }
}

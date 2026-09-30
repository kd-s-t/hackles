import SwiftData
import SwiftUI

struct SignUpView: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  @State private var name = ""
  @State private var email = ""
  @State private var password = ""

  var body: some View {
    ScreenColumn(
      kicker: "ACCOUNT",
      title: "Create account",
      subtitle: "Sign in after this to register a hackle with its wristband."
    ) {
      VStack(alignment: .leading, spacing: 14) {
        AuthField(title: "Name", text: $name, content: .name, capitalization: .words, allowsAutocorrection: true)
        AuthField(title: "Email", text: $email, content: .username, keyboard: .emailAddress)
        AuthField(title: "Password", text: $password, secure: true, content: .newPassword)
        Text("At least 8 characters.")
          .font(.system(size: 13))
          .foregroundStyle(Theme.mute)
        BrandButton(title: "Create account", busy: auth.isSubmitting) {
          _ = auth.register(name: name, email: email, password: password, context: context)
        }
        .disabled(auth.isSubmitting)
        if let errorMessage = auth.errorMessage {
          Notice(text: errorMessage, tone: Theme.danger)
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("")
    .task { auth.clearMessages() }
  }
}

import SwiftData
import SwiftUI

struct ForgotPasswordView: View {
  @Environment(AuthStore.self) private var auth
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @State private var email = ""
  @State private var password = ""

  var body: some View {
    ScreenColumn(
      kicker: "ACCOUNT",
      title: "Reset password",
      subtitle: "Set a new password for this Hackles account."
    ) {
      VStack(alignment: .leading, spacing: 14) {
        AuthField(title: "Email", text: $email, content: .username, keyboard: .emailAddress)
        AuthField(title: "New password", text: $password, secure: true, content: .newPassword)
        Text("At least 8 characters.")
          .font(.system(size: 13))
          .foregroundStyle(Theme.mute)
        BrandButton(title: "Update password", busy: auth.isSubmitting) {
          if auth.forgotPassword(email: email, password: password, context: context) {
            dismiss()
          }
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

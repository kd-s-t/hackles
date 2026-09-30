import AuthenticationServices
import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class AuthStore {
  private(set) var account: Account?
  private(set) var isBootstrapping = true
  private(set) var isSubmitting = false
  var errorMessage: String?
  var infoMessage: String?

  private var appleRawNonce: String?

  var isSignedIn: Bool { account != nil }

  func bootstrap(context: ModelContext) {
    isBootstrapping = true
    defer { isBootstrapping = false }
    SampleLogin.seedIfNeeded(context: context)
    guard let email = UserDefaults.standard.string(forKey: SessionKey.email) else {
      account = nil
      return
    }
    do {
      if let found = try Directory.account(email: email, context: context) {
        account = found
      } else {
        UserDefaults.standard.removeObject(forKey: SessionKey.email)
        account = nil
      }
    } catch {
      account = nil
      errorMessage = error.localizedDescription
    }
  }

  func login(email: String, password: String, context: ModelContext) {
    let trimmed = Directory.normalizeEmail(email)
    guard !trimmed.isEmpty, !password.isEmpty else {
      errorMessage = DirectoryError.passwordRequired.localizedDescription
      return
    }
    isSubmitting = true
    errorMessage = nil
    infoMessage = nil
    defer { isSubmitting = false }
    do {
      guard let found = try Directory.account(email: trimmed, context: context) else {
        errorMessage = "Email or password is incorrect."
        return
      }
      guard !found.passwordHash.isEmpty else {
        errorMessage = "This account signs in with Apple."
        return
      }
      guard Password.hash(password: password, salt: found.salt) == found.passwordHash else {
        errorMessage = "Email or password is incorrect."
        return
      }
      adopt(found)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
    let raw = AppleSignInCrypto.randomNonce()
    appleRawNonce = raw
    request.requestedScopes = [.fullName, .email]
    request.nonce = AppleSignInCrypto.sha256Hex(raw)
  }

  func handleAppleCompletion(_ result: Result<ASAuthorization, Error>, context: ModelContext) {
    errorMessage = nil
    infoMessage = nil
    defer { appleRawNonce = nil }

    switch result {
    case .failure(let error):
      let ns = error as NSError
      if ns.domain == ASAuthorizationError.errorDomain,
         ns.code == ASAuthorizationError.canceled.rawValue {
        return
      }
      errorMessage = error.localizedDescription
    case .success(let authorization):
      do {
        let apple = try AppleSignInCrypto.credential(from: authorization)
        let signedIn = try Directory.loginOrRegisterApple(
          userId: apple.userId,
          email: apple.email,
          name: apple.fullName,
          context: context
        )
        adopt(signedIn)
      } catch {
        errorMessage = error.localizedDescription
      }
    }
  }

  func register(name: String, email: String, password: String, context: ModelContext) -> Bool {
    isSubmitting = true
    errorMessage = nil
    infoMessage = nil
    defer { isSubmitting = false }
    do {
      let created = try Directory.registerAccount(
        name: name,
        email: email,
        password: password,
        context: context
      )
      adopt(created)
      return true
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }

  func forgotPassword(email: String, password: String, context: ModelContext) -> Bool {
    isSubmitting = true
    errorMessage = nil
    infoMessage = nil
    defer { isSubmitting = false }
    do {
      try Directory.resetPassword(email: email, password: password, context: context)
      infoMessage = "Password updated. Sign in with the new password."
      return true
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }

  func logout() {
    UserDefaults.standard.removeObject(forKey: SessionKey.email)
    account = nil
    errorMessage = nil
    infoMessage = nil
  }

  func setPremium(_ enabled: Bool, context: ModelContext) {
    guard let email = account?.email else { return }
    do {
      guard let found = try Directory.account(email: email, context: context) else { return }
      found.isPremium = enabled
      try context.save()
      account = found
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func updateProfile(
    name: String,
    email: String,
    farm: String,
    country: String,
    phone: String,
    profilePicture: String?,
    context: ModelContext
  ) -> Bool {
    guard let currentEmail = account?.email else { return false }
    isSubmitting = true
    errorMessage = nil
    infoMessage = nil
    defer { isSubmitting = false }
    do {
      let updated = try Directory.updateAccountProfile(
        email: currentEmail,
        newEmail: email,
        name: name,
        farm: farm,
        country: country,
        phone: phone,
        profilePicture: profilePicture,
        context: context
      )
      adopt(updated)
      return true
    } catch {
      errorMessage = error.localizedDescription
      return false
    }
  }

  func deleteAccount(context: ModelContext) {
    guard let email = account?.email else { return }
    isSubmitting = true
    errorMessage = nil
    infoMessage = nil
    defer { isSubmitting = false }
    do {
      try Directory.deleteAccount(email: email, context: context)
      logout()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func clearMessages() {
    errorMessage = nil
    infoMessage = nil
  }

  private func adopt(_ account: Account) {
    self.account = account
    UserDefaults.standard.set(account.email, forKey: SessionKey.email)
  }
}

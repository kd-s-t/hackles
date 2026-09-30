import SwiftUI

struct BrandButton: View {
  let title: String
  var busy = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        Text(title)
          .opacity(busy ? 0 : 1)
        if busy {
          ProgressView()
            .tint(Theme.onFill)
        }
      }
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(Theme.onFill)
      .frame(maxWidth: .infinity)
      .frame(height: 54)
      .background(Theme.brand, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(busy)
  }
}

/// Membership sign-up CTA — distinct from BrandButton / Sign out.
struct PremiumSignButton: View {
  var title = "Sign up for Premium"
  var busy = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        HStack(spacing: 10) {
          Image(systemName: "signature")
            .font(.system(size: 18, weight: .semibold))
          Text(title)
            .font(.system(size: 16, weight: .semibold))
        }
        .opacity(busy ? 0 : 1)

        if busy {
          ProgressView()
            .tint(Theme.onFill)
        }
      }
      .foregroundStyle(Theme.onFill)
      .frame(maxWidth: .infinity)
      .frame(height: 54)
      .background(Theme.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(Theme.orange.opacity(0.55), lineWidth: 1.5)
      }
    }
    .buttonStyle(.plain)
    .disabled(busy)
    .accessibilityLabel(title)
  }
}

struct LineButton: View {
  let title: String
  var busy = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        Text(title)
          .opacity(busy ? 0 : 1)
        if busy {
          ProgressView()
            .tint(Theme.ink)
        }
      }
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(Theme.ink)
      .frame(maxWidth: .infinity)
      .frame(height: 54)
      .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(Theme.line, lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
    .disabled(busy)
  }
}

struct AuthField: View {
  let title: String
  @Binding var text: String
  var secure = false
  var content: UITextContentType?
  var keyboard: UIKeyboardType = .default
  var capitalization: TextInputAutocapitalization = .never
  var allowsAutocorrection = false
  @State private var revealed = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Theme.mute)
      HStack(spacing: 8) {
        field
        if secure {
          Button {
            revealed.toggle()
          } label: {
            Image(systemName: revealed ? "eye.slash" : "eye")
              .foregroundStyle(Theme.mute)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 14)
      .frame(height: 54)
      .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(Theme.line, lineWidth: 1)
      }
    }
  }

  @ViewBuilder
  private var field: some View {
    if secure && !revealed {
      SecureField("", text: $text)
        .textContentType(content)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    } else {
      TextField("", text: $text)
        .textContentType(content)
        .keyboardType(keyboard)
        .textInputAutocapitalization(capitalization)
        .autocorrectionDisabled(!allowsAutocorrection)
    }
  }
}

struct Notice: View {
  let text: String
  var tone: Color = Theme.red

  var body: some View {
    Text(text)
      .font(.system(size: 14))
      .foregroundStyle(tone)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
      .background(tone.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}

struct HacklesMark: View {
  var side: CGFloat = 112

  var body: some View {
    Image("HacklesLogo")
      .resizable()
      .scaledToFit()
      .frame(width: side, height: side)
      .frame(maxWidth: .infinity)
      .accessibilityLabel("Hackles")
  }
}

struct ScreenColumn<Content: View>: View {
  let kicker: String
  let title: String
  let subtitle: String
  var showsMark = false
  @ViewBuilder var content: () -> Content

  var body: some View {
    ZStack {
      Theme.paper.ignoresSafeArea()
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          if showsMark {
            HacklesMark()
              .padding(.bottom, 8)
          }
          if !kicker.isEmpty {
            Text(kicker)
              .font(.system(size: 12, weight: .semibold))
              .tracking(1.6)
              .foregroundStyle(Theme.red)
          }
          Text(title)
            .font(.system(size: 40, weight: .regular, design: .serif))
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(showsMark ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: showsMark ? .center : .leading)
            .padding(.top, 10)
          if !subtitle.isEmpty {
            Text(subtitle)
              .font(.system(size: 16))
              .foregroundStyle(Theme.mute)
              .padding(.top, 8)
              .fixedSize(horizontal: false, vertical: true)
          }
          content()
            .padding(.top, 28)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 120)
      }
      .scrollDismissesKeyboard(.interactively)
    }
  }
}

struct VisibilityBadge: View {
  let isPublic: Bool

  var body: some View {
    Text(isPublic ? "Public" : "Private")
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(isPublic ? Theme.red : Theme.mute)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(
        (isPublic ? Theme.orange : Theme.mute).opacity(0.14),
        in: Capsule()
      )
  }
}

struct StatusBadge: View {
  let status: String

  private var isDeceased: Bool {
    status.localizedCaseInsensitiveCompare("Deceased") == .orderedSame
  }

  var body: some View {
    Text(status)
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(isDeceased ? Theme.danger : Theme.ink)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(
        (isDeceased ? Theme.danger : Theme.mute).opacity(0.14),
        in: Capsule()
      )
  }
}

import CryptoKit
import Foundation
import SwiftData

@Model
final class Account {
  var name: String
  var email: String
  var salt: String
  var passwordHash: String
  var appleUserId: String?
  var farm: String?
  var country: String?
  var phone: String?
  var profilePicture: String?
  var isPremium: Bool = false
  var createdAt: Date

  init(
    name: String,
    email: String,
    salt: String,
    passwordHash: String,
    appleUserId: String? = nil,
    farm: String? = nil,
    country: String? = nil,
    phone: String? = nil,
    profilePicture: String? = nil,
    isPremium: Bool = false,
    createdAt: Date
  ) {
    self.name = name
    self.email = email
    self.salt = salt
    self.passwordHash = passwordHash
    self.appleUserId = appleUserId
    self.farm = farm
    self.country = country
    self.phone = phone
    self.profilePicture = profilePicture
    self.isPremium = isPremium
    self.createdAt = createdAt
  }

  var usesAppleSignIn: Bool {
    appleUserId != nil && !appleUserId!.isEmpty
  }

  var signInLabel: String {
    if usesAppleSignIn {
      return passwordHash.isEmpty ? "Sign in with Apple" : "Apple and password"
    }
    return "Email and password"
  }
}

@Model
final class OwnerYard {
  var id: UUID
  var ownerEmail: String
  var name: String
  var location: String?
  var country: String?
  var notes: String?
  var createdAt: Date

  init(
    id: UUID = UUID(),
    ownerEmail: String,
    name: String,
    location: String? = nil,
    country: String? = nil,
    notes: String? = nil,
    createdAt: Date = .now
  ) {
    self.id = id
    self.ownerEmail = ownerEmail
    self.name = name
    self.location = location
    self.country = country
    self.notes = notes
    self.createdAt = createdAt
  }

  var subtitle: String {
    [location, country]
      .compactMap { value in
        guard let value, !value.isEmpty else { return nil }
        return value
      }
      .joined(separator: " · ")
  }
}

@Model
final class HackleRecord {
  var wristband: String
  var name: String
  var sireWristband: String?
  var damWristband: String?
  var isPublic: Bool
  var ownerEmail: String
  var profilePicture: String?
  var sex: String?
  var weightKg: Double?
  var hatchDate: Date?
  var bloodline: String?
  var color: String?
  var combType: String?
  var spurLengthCm: Double?
  var farm: String?
  var country: String?
  var status: String?
  var notes: String?
  var createdAt: Date

  init(
    wristband: String,
    name: String,
    sireWristband: String?,
    damWristband: String?,
    isPublic: Bool,
    ownerEmail: String,
    profilePicture: String? = nil,
    sex: String? = nil,
    weightKg: Double? = nil,
    hatchDate: Date? = nil,
    bloodline: String? = nil,
    color: String? = nil,
    combType: String? = nil,
    spurLengthCm: Double? = nil,
    farm: String? = nil,
    country: String? = nil,
    status: String? = nil,
    notes: String? = nil,
    createdAt: Date
  ) {
    self.wristband = wristband
    self.name = name
    self.sireWristband = sireWristband
    self.damWristband = damWristband
    self.isPublic = isPublic
    self.ownerEmail = ownerEmail
    self.profilePicture = profilePicture
    self.sex = sex
    self.weightKg = weightKg
    self.hatchDate = hatchDate
    self.bloodline = bloodline
    self.color = color
    self.combType = combType
    self.spurLengthCm = spurLengthCm
    self.farm = farm
    self.country = country
    self.status = status
    self.notes = notes
    self.createdAt = createdAt
  }

  func apply(_ details: HackleBiodata) {
    sex = details.cleaned(details.sex)
    weightKg = details.weightKg
    hatchDate = details.hatchDate
    bloodline = details.cleaned(details.bloodline)
    color = details.cleaned(details.color)
    combType = details.cleaned(details.combType)
    spurLengthCm = details.spurLengthCm
    farm = details.cleaned(details.farm)
    country = details.cleaned(details.country)
    status = details.cleaned(details.status)
    notes = details.cleaned(details.notes)
  }
}

struct HackleBiodata: Equatable {
  var sex = ""
  var weightKg: Double?
  var hatchDate: Date?
  var bloodline = ""
  var color = ""
  var combType = ""
  var spurLengthCm: Double?
  var farm = ""
  var country = ""
  var status = ""
  var notes = ""

  func cleaned(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  static func from(_ bird: HackleRecord) -> HackleBiodata {
    HackleBiodata(
      sex: bird.sex ?? "",
      weightKg: bird.weightKg,
      hatchDate: bird.hatchDate,
      bloodline: bird.bloodline ?? "",
      color: bird.color ?? "",
      combType: bird.combType ?? "",
      spurLengthCm: bird.spurLengthCm,
      farm: bird.farm ?? "",
      country: bird.country ?? "",
      status: bird.status ?? "",
      notes: bird.notes ?? ""
    )
  }
}

enum HackleSex: String, CaseIterable, Identifiable {
  case cock = "Cock"
  case hen = "Hen"
  case stag = "Stag"
  case pullet = "Pullet"
  var id: String { rawValue }
}

enum HackleStatus: String, CaseIterable, Identifiable {
  case active = "Active"
  case brood = "Brood"
  case retired = "Retired"
  case deceased = "Deceased"
  var id: String { rawValue }
}

enum HackleComb: String, CaseIterable, Identifiable {
  case single = "Single"
  case pea = "Pea"
  case rose = "Rose"
  case walnut = "Walnut"
  case other = "Other"
  var id: String { rawValue }
}

enum HackleAge {
  static func description(from hatchDate: Date, asOf: Date = .now) -> String? {
    let calendar = Calendar.current
    guard hatchDate <= asOf else { return nil }
    let comps = calendar.dateComponents([.year, .month, .day], from: hatchDate, to: asOf)
    let years = comps.year ?? 0
    let months = comps.month ?? 0
    let days = comps.day ?? 0
    if years > 0 {
      if months > 0 { return "\(years)y \(months)m" }
      return years == 1 ? "1 year" : "\(years) years"
    }
    if months > 0 {
      return months == 1 ? "1 month" : "\(months) months"
    }
    if days > 0 {
      return days == 1 ? "1 day" : "\(days) days"
    }
    return "New hatch"
  }
}

enum SessionKey {
  static let email = "hackles.session.email"
}

enum SampleLogin {
  static let name = "Demo Owner"
  static let email = "demo@hackles.app"
  static let password = "hackles1234"
  static let farm = "Hackles Yard"
  static let farmLocation = "Lipa, Batangas"
  static let country = "Philippines"
  static let phone = "+63 917 000 1001"
  static let profilePicture = "OwnerDemo"

  private static let publicHackles: [(
    wristband: String,
    name: String,
    sire: String,
    dam: String,
    photo: String,
    details: HackleBiodata
  )] = {
    let calendar = Calendar.current
    func daysAgo(_ days: Int) -> Date {
      calendar.date(byAdding: .day, value: -days, to: .now) ?? .now
    }
    return [
      (
        "WB-1001", "Red Lightning", "", "", "HacklesProfile1",
        HackleBiodata(
          sex: "Cock", weightKg: 2.35, hatchDate: daysAgo(520),
          bloodline: "Hatch", color: "Red brown", combType: "Single",
          spurLengthCm: 3.2, farm: "Hackles Yard", country: "Philippines",
          status: "Brood", notes: "Foundation broodcock."
        )
      ),
      (
        "WB-1003", "Crimson Spur", "", "", "HacklesProfile3",
        HackleBiodata(
          sex: "Cock", weightKg: 2.48, hatchDate: daysAgo(480),
          bloodline: "Kelso", color: "White", combType: "Pea",
          spurLengthCm: 3.5, farm: "Hackles Yard", country: "Philippines",
          status: "Active", notes: "Strong station."
        )
      ),
      (
        "WB-1007", "Buff Queen", "", "", "HacklesProfile7",
        HackleBiodata(
          sex: "Hen", weightKg: 1.82, hatchDate: daysAgo(610),
          bloodline: "Buff", color: "Golden buff", combType: "Single",
          spurLengthCm: nil, farm: "Hackles Yard", country: "Philippines",
          status: "Brood", notes: "Primary brood hen."
        )
      ),
      (
        "WB-1002", "Sunrise Blade", "WB-1001", "WB-1007", "HacklesProfile2",
        HackleBiodata(
          sex: "Cock", weightKg: 2.28, hatchDate: daysAgo(300),
          bloodline: "Hatch x Buff", color: "Orange red", combType: "Single",
          spurLengthCm: 2.8, farm: "Hackles Yard", country: "Philippines",
          status: "Active", notes: "Out of Red Lightning."
        )
      ),
      (
        "WB-1004", "Golden Comb", "WB-1003", "WB-1007", "HacklesProfile4",
        HackleBiodata(
          sex: "Cock", weightKg: 2.41, hatchDate: daysAgo(340),
          bloodline: "Kelso x Buff", color: "Gold black", combType: "Single",
          spurLengthCm: 3.0, farm: "Hackles Yard", country: "Philippines",
          status: "Active", notes: "Deep body."
        )
      ),
      (
        "WB-1005", "Hackles Fire", "WB-1002", "WB-1004", "HacklesProfile5",
        HackleBiodata(
          sex: "Stag", weightKg: 1.95, hatchDate: daysAgo(210),
          bloodline: "Yard line", color: "Copper", combType: "Single",
          spurLengthCm: 1.6, farm: "Hackles Yard", country: "Philippines",
          status: "Active", notes: "Growing well."
        )
      ),
      (
        "WB-1006", "Copper Crown", "WB-1004", "WB-1007", "HacklesProfile6",
        HackleBiodata(
          sex: "Cock", weightKg: 2.22, hatchDate: daysAgo(365),
          bloodline: "Kelso x Buff", color: "Copper black", combType: "Rose",
          spurLengthCm: 2.9, farm: "Hackles Yard", country: "Philippines",
          status: "Active", notes: "Long hackles."
        )
      ),
    ]
  }()

  @MainActor
  static func seedIfNeeded(context: ModelContext) {
    do {
      if try Directory.account(email: email, context: context) == nil {
        _ = try Directory.registerAccount(
          name: name,
          email: email,
          password: password,
          farm: farm,
          country: country,
          phone: phone,
          profilePicture: profilePicture,
          context: context
        )
      } else if let demo = try Directory.account(email: email, context: context) {
        demo.name = name
        demo.farm = farm
        demo.country = country
        demo.phone = phone
        try context.save()
      }
      if try Directory.yards(ownedBy: email, context: context).isEmpty {
        _ = try Directory.upsertYard(
          id: nil,
          ownerEmail: email,
          name: farm,
          location: farmLocation,
          country: country,
          notes: "Main brood and conditioning yard.",
          context: context
        )
      }
      for bird in publicHackles {
        if let existing = try Directory.hackle(wristband: bird.wristband, context: context) {
          existing.name = bird.name
          existing.sireWristband = bird.sire.isEmpty ? nil : bird.sire
          existing.damWristband = bird.dam.isEmpty ? nil : bird.dam
          existing.isPublic = true
          existing.ownerEmail = Directory.normalizeEmail(email)
          existing.profilePicture = bird.photo
          existing.apply(bird.details)
          try context.save()
        } else {
          _ = try Directory.registerHackle(
            wristband: bird.wristband,
            name: bird.name,
            sireWristband: bird.sire,
            damWristband: bird.dam,
            isPublic: true,
            ownerEmail: email,
            profilePicture: bird.photo,
            details: bird.details,
            context: context
          )
        }
      }
    } catch {
      // Keep launch going if the sample seed fails.
    }
  }
}

enum Password {
  static func makeSalt() -> String {
    SymmetricKey(size: .bits128).withUnsafeBytes { Data($0).base64EncodedString() }
  }

  static func hash(password: String, salt: String) -> String {
    let digest = SHA256.hash(data: Data("\(salt):\(password)".utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }
}

enum DirectoryError: LocalizedError {
  case nameRequired
  case emailRequired
  case passwordRequired
  case passwordShort
  case duplicateEmail
  case unknownAccount
  case wristbandRequired
  case duplicateWristband
  case nameMissing
  case missingParent
  case parentCycle
  case notOwner
  case hasChildren
  case missingHackle
  case yardNameRequired
  case missingYard
  case yardLimitReached
  case hackleLimitReached

  var errorDescription: String? {
    switch self {
    case .nameRequired:
      return "Name, email, and password are required."
    case .emailRequired:
      return "Email is required."
    case .passwordRequired:
      return "Email and password are required."
    case .passwordShort:
      return "Password must be at least 8 characters."
    case .duplicateEmail:
      return "An account with that email already exists."
    case .unknownAccount:
      return "No account uses that email."
    case .wristbandRequired:
      return "Wristband is required."
    case .duplicateWristband:
      return "That wristband is already registered."
    case .nameMissing:
      return "Name is required."
    case .missingParent:
      return "No hackle is registered with that parent wristband."
    case .parentCycle:
      return "A hackle cannot be its own ancestor."
    case .notOwner:
      return "Only the owner can change this hackle."
    case .hasChildren:
      return "Remove this hackle as a sire or dam before deleting it."
    case .missingHackle:
      return "That hackle is not registered."
    case .yardNameRequired:
      return "Yard name is required."
    case .missingYard:
      return "That yard is not registered."
    case .yardLimitReached:
      return PremiumGate.yard.message
    case .hackleLimitReached:
      return PremiumGate.hackle.message
    }
  }
}

@MainActor
enum Directory {
  static func normalizeBand(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
  }

  static func normalizeEmail(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  static func account(email: String, context: ModelContext) throws -> Account? {
    let key = normalizeEmail(email)
    let descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.email == key })
    return try context.fetch(descriptor).first
  }

  static func account(appleUserId: String, context: ModelContext) throws -> Account? {
    let key = appleUserId
    let descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.appleUserId == key })
    return try context.fetch(descriptor).first
  }

  static func loginOrRegisterApple(
    userId: String,
    email: String?,
    name: String?,
    context: ModelContext
  ) throws -> Account {
    if let existing = try account(appleUserId: userId, context: context) {
      if let name, !name.isEmpty, existing.name != name {
        existing.name = name
        try context.save()
      }
      return existing
    }

    let resolvedEmail = normalizeEmail(email ?? "apple.\(userId)@privaterelay.appleid.com")
    if let byEmail = try account(email: resolvedEmail, context: context) {
      byEmail.appleUserId = userId
      if let name, !name.isEmpty {
        byEmail.name = name
      }
      try context.save()
      return byEmail
    }

    let displayName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
    let created = Account(
      name: (displayName?.isEmpty == false) ? displayName! : "Apple user",
      email: resolvedEmail,
      salt: "",
      passwordHash: "",
      appleUserId: userId,
      createdAt: .now
    )
    context.insert(created)
    try context.save()
    return created
  }

  static func hackle(wristband: String, context: ModelContext) throws -> HackleRecord? {
    let key = normalizeBand(wristband)
    let descriptor = FetchDescriptor<HackleRecord>(predicate: #Predicate { $0.wristband == key })
    return try context.fetch(descriptor).first
  }

  static func owned(by email: String, context: ModelContext) throws -> [HackleRecord] {
    let key = normalizeEmail(email)
    let descriptor = FetchDescriptor<HackleRecord>(
      predicate: #Predicate { $0.ownerEmail == key },
      sortBy: [SortDescriptor(\HackleRecord.createdAt, order: .reverse)]
    )
    return try context.fetch(descriptor)
  }

  static func yards(ownedBy email: String, context: ModelContext) throws -> [OwnerYard] {
    let key = normalizeEmail(email)
    let descriptor = FetchDescriptor<OwnerYard>(
      predicate: #Predicate { $0.ownerEmail == key },
      sortBy: [SortDescriptor(\OwnerYard.name)]
    )
    return try context.fetch(descriptor)
  }

  static func yard(id: UUID, context: ModelContext) throws -> OwnerYard? {
    let descriptor = FetchDescriptor<OwnerYard>(predicate: #Predicate { $0.id == id })
    return try context.fetch(descriptor).first
  }

  static func upsertYard(
    id: UUID?,
    ownerEmail: String,
    name: String,
    location: String,
    country: String,
    notes: String,
    context: ModelContext
  ) throws -> OwnerYard {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { throw DirectoryError.yardNameRequired }
    let key = normalizeEmail(ownerEmail)
    if let id {
      guard let existing = try yard(id: id, context: context) else {
        throw DirectoryError.missingYard
      }
      guard existing.ownerEmail == key else { throw DirectoryError.notOwner }
      existing.name = trimmedName
      existing.location = cleanedOptional(location)
      existing.country = cleanedOptional(country)
      existing.notes = cleanedOptional(notes)
      try context.save()
      return existing
    }
    let owner = try account(email: key, context: context)
    let currentYards = try yards(ownedBy: key, context: context).count
    guard PremiumPlan.canAddYard(isPremium: owner?.isPremium == true, currentCount: currentYards) else {
      throw DirectoryError.yardLimitReached
    }
    let created = OwnerYard(
      ownerEmail: key,
      name: trimmedName,
      location: cleanedOptional(location),
      country: cleanedOptional(country),
      notes: cleanedOptional(notes)
    )
    context.insert(created)
    try context.save()
    return created
  }

  static func deleteYard(id: UUID, ownerEmail: String, context: ModelContext) throws {
    let key = normalizeEmail(ownerEmail)
    guard let existing = try yard(id: id, context: context) else {
      throw DirectoryError.missingYard
    }
    guard existing.ownerEmail == key else { throw DirectoryError.notOwner }
    context.delete(existing)
    try context.save()
  }

  static func publicHackles(matching query: String, context: ModelContext) throws -> [HackleRecord] {
    let needle = normalizeBand(query)
    let descriptor = FetchDescriptor<HackleRecord>(
      predicate: #Predicate { $0.isPublic },
      sortBy: [SortDescriptor(\HackleRecord.name)]
    )
    let rows = try context.fetch(descriptor)
    guard !needle.isEmpty else { return rows }
    return rows.filter {
      $0.wristband.contains(needle) || $0.name.uppercased().contains(needle)
    }
  }

  static func searchableHackles(
    matching query: String,
    excluding wristband: String?,
    context: ModelContext
  ) throws -> [HackleRecord] {
    let needle = normalizeBand(query)
    let excluded = normalizeBand(wristband ?? "")
    let descriptor = FetchDescriptor<HackleRecord>(
      sortBy: [SortDescriptor(\HackleRecord.name)]
    )
    let rows = try context.fetch(descriptor).filter { bird in
      if !excluded.isEmpty, bird.wristband == excluded { return false }
      return true
    }
    guard !needle.isEmpty else { return rows }
    return rows.filter {
      $0.wristband.contains(needle)
        || $0.name.uppercased().contains(needle)
        || ($0.bloodline?.uppercased().contains(needle) ?? false)
    }
  }

  static func registerAccount(
    name: String,
    email: String,
    password: String,
    farm: String? = nil,
    country: String? = nil,
    phone: String? = nil,
    profilePicture: String? = nil,
    context: ModelContext
  ) throws -> Account {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedEmail = normalizeEmail(email)
    guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty else {
      throw DirectoryError.nameRequired
    }
    guard password.count >= 8 else { throw DirectoryError.passwordShort }
    if try account(email: trimmedEmail, context: context) != nil {
      throw DirectoryError.duplicateEmail
    }
    let salt = Password.makeSalt()
    let created = Account(
      name: trimmedName,
      email: trimmedEmail,
      salt: salt,
      passwordHash: Password.hash(password: password, salt: salt),
      farm: cleanedOptional(farm),
      country: cleanedOptional(country),
      phone: cleanedOptional(phone),
      profilePicture: cleanedOptional(profilePicture),
      createdAt: .now
    )
    context.insert(created)
    try context.save()
    return created
  }

  static func updateAccountProfile(
    email: String,
    newEmail: String,
    name: String,
    farm: String,
    country: String,
    phone: String,
    profilePicture: String?,
    context: ModelContext
  ) throws -> Account {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let currentEmail = normalizeEmail(email)
    let nextEmail = normalizeEmail(newEmail)
    guard !trimmedName.isEmpty else { throw DirectoryError.nameMissing }
    guard !nextEmail.isEmpty else { throw DirectoryError.emailRequired }
    guard let found = try account(email: currentEmail, context: context) else {
      throw DirectoryError.unknownAccount
    }
    if nextEmail != currentEmail {
      if try account(email: nextEmail, context: context) != nil {
        throw DirectoryError.duplicateEmail
      }
      for bird in try owned(by: currentEmail, context: context) {
        bird.ownerEmail = nextEmail
      }
      for yard in try yards(ownedBy: currentEmail, context: context) {
        yard.ownerEmail = nextEmail
      }
      found.email = nextEmail
    }
    found.name = trimmedName
    found.farm = cleanedOptional(farm)
    found.country = cleanedOptional(country)
    found.phone = cleanedOptional(phone)
    found.profilePicture = cleanedOptional(profilePicture)
    try context.save()
    return found
  }

  static func cleanedOptional(_ value: String?) -> String? {
    let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  static func resetPassword(email: String, password: String, context: ModelContext) throws {
    let trimmedEmail = normalizeEmail(email)
    guard !trimmedEmail.isEmpty else { throw DirectoryError.emailRequired }
    guard password.count >= 8 else { throw DirectoryError.passwordShort }
    guard let found = try account(email: trimmedEmail, context: context) else {
      throw DirectoryError.unknownAccount
    }
    let salt = Password.makeSalt()
    found.salt = salt
    found.passwordHash = Password.hash(password: password, salt: salt)
    try context.save()
  }

  static func registerHackle(
    wristband: String,
    name: String,
    sireWristband: String,
    damWristband: String,
    isPublic: Bool,
    ownerEmail: String,
    profilePicture: String? = nil,
    details: HackleBiodata = HackleBiodata(),
    context: ModelContext
  ) throws -> HackleRecord {
    let band = normalizeBand(wristband)
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !band.isEmpty else { throw DirectoryError.wristbandRequired }
    guard !trimmedName.isEmpty else { throw DirectoryError.nameMissing }
    if try hackle(wristband: band, context: context) != nil {
      throw DirectoryError.duplicateWristband
    }
    let ownerKey = normalizeEmail(ownerEmail)
    let owner = try account(email: ownerKey, context: context)
    let flockCount = try owned(by: ownerKey, context: context).count
    guard PremiumPlan.canAddHackle(isPremium: owner?.isPremium == true, currentCount: flockCount) else {
      throw DirectoryError.hackleLimitReached
    }
    let sire = try resolvedParent(sireWristband, child: band, context: context)
    let dam = try resolvedParent(damWristband, child: band, context: context)
    let photo = profilePicture?.trimmingCharacters(in: .whitespacesAndNewlines)
    let created = HackleRecord(
      wristband: band,
      name: trimmedName,
      sireWristband: sire,
      damWristband: dam,
      isPublic: isPublic,
      ownerEmail: normalizeEmail(ownerEmail),
      profilePicture: (photo?.isEmpty == false) ? photo : nil,
      createdAt: .now
    )
    created.apply(details)
    context.insert(created)
    try context.save()
    return created
  }

  static func updateHackle(
    wristband: String,
    name: String,
    sireWristband: String,
    damWristband: String,
    isPublic: Bool,
    ownerEmail: String,
    profilePicture: String? = nil,
    details: HackleBiodata = HackleBiodata(),
    context: ModelContext
  ) throws {
    let band = normalizeBand(wristband)
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { throw DirectoryError.nameMissing }
    guard let record = try hackle(wristband: band, context: context) else {
      throw DirectoryError.missingHackle
    }
    guard record.ownerEmail == normalizeEmail(ownerEmail) else { throw DirectoryError.notOwner }
    record.name = trimmedName
    record.sireWristband = try resolvedParent(sireWristband, child: band, context: context)
    record.damWristband = try resolvedParent(damWristband, child: band, context: context)
    record.isPublic = isPublic
    record.apply(details)
    if let profilePicture {
      let photo = profilePicture.trimmingCharacters(in: .whitespacesAndNewlines)
      record.profilePicture = photo.isEmpty ? nil : photo
    }
    try context.save()
  }

  static func deleteHackle(wristband: String, ownerEmail: String, context: ModelContext) throws {
    let band = normalizeBand(wristband)
    guard let record = try hackle(wristband: band, context: context) else {
      throw DirectoryError.missingHackle
    }
    guard record.ownerEmail == normalizeEmail(ownerEmail) else { throw DirectoryError.notOwner }
    let descriptor = FetchDescriptor<HackleRecord>(
      predicate: #Predicate { $0.sireWristband == band || $0.damWristband == band }
    )
    if try !context.fetch(descriptor).isEmpty {
      throw DirectoryError.hasChildren
    }
    context.delete(record)
    try context.save()
  }

  static func deleteAccount(email: String, context: ModelContext) throws {
    let key = normalizeEmail(email)
    guard let account = try account(email: key, context: context) else {
      throw DirectoryError.unknownAccount
    }
    let ownedBirds = try owned(by: key, context: context)
    let ownedBands = Set(ownedBirds.map(\.wristband))
    if !ownedBands.isEmpty {
      let all = try context.fetch(FetchDescriptor<HackleRecord>())
      for bird in all {
        if let sire = bird.sireWristband, ownedBands.contains(sire) {
          bird.sireWristband = nil
        }
        if let dam = bird.damWristband, ownedBands.contains(dam) {
          bird.damWristband = nil
        }
      }
      for bird in ownedBirds {
        context.delete(bird)
      }
    }
    for yard in try yards(ownedBy: key, context: context) {
      context.delete(yard)
    }
    context.delete(account)
    try context.save()
  }

  private static func resolvedParent(
    _ raw: String,
    child: String,
    context: ModelContext
  ) throws -> String? {
    let band = normalizeBand(raw)
    if band.isEmpty { return nil }
    if band == child { throw DirectoryError.parentCycle }
    guard try hackle(wristband: band, context: context) != nil else {
      throw DirectoryError.missingParent
    }
    var queue = [band]
    var seen = Set<String>()
    while let current = queue.first {
      queue.removeFirst()
      if current == child || !seen.insert(current).inserted {
        throw DirectoryError.parentCycle
      }
      guard let ancestor = try hackle(wristband: current, context: context) else { continue }
      if let sire = ancestor.sireWristband { queue.append(sire) }
      if let dam = ancestor.damWristband { queue.append(dam) }
    }
    return band
  }
}

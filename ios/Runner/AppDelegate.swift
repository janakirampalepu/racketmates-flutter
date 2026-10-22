import Flutter
import StoreKit
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    if let payload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      PushChannel.launchMessage = PushChannel.message(from: payload, id: nil)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    PushChannel.didRegister(deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // A notification arriving while the app is open: Flutter shows it in the app.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    PushChannel.emit("onMessage", PushChannel.message(from: notification))
    completionHandler([])
  }

  // The user tapped a notification.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    PushChannel.emit("onOpened", PushChannel.message(from: response.notification))
    completionHandler()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RacketmatesPlatformChannels") {
      DeviceIntegrityChannel.register(with: registrar.messenger())
      NativeSessionChannel.register(with: registrar.messenger())
      PushChannel.register(with: registrar.messenger())
      BillingChannel.register(with: registrar.messenger())
    }
  }
}

// MARK: - Jailbreak detection

/// `io.appsmaker.racketmates/device_integrity`: `isCompromised` -> Bool.
/// A port of the native app's `LSJailBreakChecker` (known jailbreak files, the
/// Cydia URL scheme, symbolic links in system folders, a write outside the
/// sandbox). The simulator counts as compromised unless `allowSimulator` is set
/// (development builds).
enum DeviceIntegrityChannel {
  static let name = "io.appsmaker.racketmates/device_integrity"

  static func register(with messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: name, binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "isCompromised" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let args = call.arguments as? [String: Any]
        let allowSimulator = args?["allowSimulator"] as? Bool ?? false
        result(isCompromised(allowSimulator: allowSimulator))
      }
  }

  private static let breakerFiles = [
    "/Applications/Cydia.app", "/var/cache/apt", "/var/lib/apt/", "/var/lib/cydia",
    "/var/log/syslog", "/var/tmp/cydia.log", "/usr/libexec/ssh-keysign",
    "/etc/ssh/sshd_config", "/jb", "/private/var/tmp/cydia.log", "/private/var/lib/cydia",
    "/Library/MobileSubstrate/DynamicLibraries", "/private/var/mobile/Library/SBSettings/",
    "/Applications/blackra1n.app", "/Applications/FakeCarrier.app", "/Applications/Icy.app",
    "/Applications/IntelliScreen.app", "/Applications/MxTube.app", "/Applications/RockApp.app",
    "/Applications/SBSettings.app", "/Applications/WinterBoard.app",
    "/Library/MobileSubstrate/MobileSubstrate.dylib",
    "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
    "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
    "/private/var/mobile/Library/SBSettings/Themes", "/private/var/stash",
    "/private/var/lib/apt/", "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
    "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist", "/bin/bash", "/bin/sh",
    "/usr/sbin/sshd", "/usr/bin/sshd", "/usr/libexec/sftp-server", "/etc/apt",
    // Extra paths the native app adds.
    "/pangueaxe", "/System/Library/LaunchDaemons/io.pangu.axe.untether.plist",
  ]

  private static let breakerLinks = [
    "/Library/Ringtones", "/Library/Wallpaper", "/usr/arm-apple-darwin9", "/usr/include",
    "/usr/libexec", "/usr/share", "/Applications",
  ]

  static func isCompromised(allowSimulator: Bool) -> Bool {
    #if targetEnvironment(simulator)
      return !allowSimulator
    #else
      let fm = FileManager.default
      if breakerFiles.contains(where: { fm.fileExists(atPath: $0) }) { return true }
      if let cydia = URL(string: "cydia://package/com.example.package"),
        UIApplication.shared.canOpenURL(cydia)
      {
        return true
      }
      for path in breakerLinks {
        if let type = try? fm.attributesOfItem(atPath: path)[.type] as? FileAttributeType,
          type == .typeSymbolicLink
        {
          return true
        }
      }
      // A sandboxed app cannot write here; a jailbroken device lets it.
      let testFile = "/private/JailbreakTest.txt"
      do {
        try "Jailbreak Available".write(toFile: testFile, atomically: true, encoding: .utf8)
        try? fm.removeItem(atPath: testFile)
        return true
      } catch {
        return false
      }
    #endif
  }
}

// MARK: - Session left by the native app

/// `io.appsmaker.racketmates/native_session`: `read` / `clear` the session the
/// native iOS app keeps in the Keychain through SwiftKeychainWrapper (service =
/// bundle identifier, account and generic attribute = the key
/// `session_response`, the value the JSON-encoded `SessionResponse`). This app
/// has the same bundle identifier and team, so the item is in its access group.
enum NativeSessionChannel {
  static let name = "io.appsmaker.racketmates/native_session"
  private static let key = "session_response"

  static func register(with messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: name, binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "read":
          result(read())
        case "clear":
          clear()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private static func query() -> [String: Any] {
    let account = Data(key.utf8)
    return [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Bundle.main.bundleIdentifier ?? "SwiftKeychainWrapper",
      kSecAttrAccount as String: account,
      kSecAttrGeneric as String: account,
    ]
  }

  private static func read() -> String? {
    var q = query()
    q[kSecReturnData as String] = true
    q[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess,
      let data = item as? Data
    else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private static func clear() {
    SecItemDelete(query() as CFDictionary)
  }
}

// MARK: - Push notifications

/// `io.appsmaker.racketmates/push`: APNs. The backend expects the raw device
/// token as a hex string on iOS (not an FCM token), so no Firebase is involved.
/// Methods: initialize, permissionStatus, requestPermission, token,
/// launchMessage, openSettings. Calls to Dart: onToken, onMessage, onOpened.
enum PushChannel {
  static let name = "io.appsmaker.racketmates/push"
  private static var channel: FlutterMethodChannel?
  private static var apnsToken: String?
  static var launchMessage: [String: Any]?

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    self.channel = channel
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "initialize":
        // APNs needs no configuration; registration only works once allowed.
        registerWithApnsIfAllowed()
        result(true)
      case "permissionStatus":
        status { result($0) }
      case "requestPermission":
        UNUserNotificationCenter.current()
          .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            registerWithApnsIfAllowed()
            status { result($0) }
          }
      case "token":
        result(apnsToken)
      case "launchMessage":
        result(launchMessage)
        launchMessage = nil
      case "openSettings":
        DispatchQueue.main.async {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func status(_ done: @escaping (String) -> Void) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let value: String
      switch settings.authorizationStatus {
      case .authorized, .provisional, .ephemeral: value = "granted"
      case .denied: value = "denied"
      default: value = "notDetermined"
      }
      DispatchQueue.main.async { done(value) }
    }
  }

  static func registerWithApnsIfAllowed() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      guard settings.authorizationStatus == .authorized
        || settings.authorizationStatus == .provisional
      else { return }
      DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
    }
  }

  static func didRegister(_ deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    apnsToken = token
    emit("onToken", token)
  }

  static func emit(_ method: String, _ argument: Any?) {
    DispatchQueue.main.async { channel?.invokeMethod(method, arguments: argument) }
  }

  static func message(from notification: UNNotification) -> [String: Any] {
    message(
      from: notification.request.content.userInfo,
      id: notification.request.identifier,
      title: notification.request.content.title,
      body: notification.request.content.body)
  }

  static func message(
    from userInfo: [AnyHashable: Any], id: String?, title: String? = nil, body: String? = nil
  ) -> [String: Any] {
    var data: [String: String] = [:]
    for (key, value) in userInfo {
      guard let key = key as? String, key != "aps" else { continue }
      if let text = value as? String {
        data[key] = text
      } else if JSONSerialization.isValidJSONObject(value),
        let json = try? JSONSerialization.data(withJSONObject: value),
        let text = String(data: json, encoding: .utf8)
      {
        data[key] = text
      } else {
        data[key] = "\(value)"
      }
    }
    var message: [String: Any] = ["data": data]
    if let id = id { message["id"] = id }
    if let title = title, !title.isEmpty { message["title"] = title }
    if let body = body, !body.isEmpty { message["body"] = body }
    return message
  }
}

// MARK: - Subscriptions (StoreKit 2)

/// `io.appsmaker.racketmates/billing`: the App Store subscription, as the
/// native `PurchaseManager`: products by id, purchase with the user's uuid as
/// `appAccountToken`, transaction updates, restore through `AppStore.sync()`,
/// and the transaction's own JSON (`jsonRepresentation`), which is what the
/// backend's `link_appstore_subscription` expects.
/// Methods: isAvailable, queryProducts{ids}, purchase{id, accountId},
/// activePurchases, restore, complete{id}, redeemCode. Call to Dart:
/// onPurchase{status, purchase?, message?}.
enum BillingChannel {
  static let name = "io.appsmaker.racketmates/billing"
  private static var channel: FlutterMethodChannel?
  private static var products: [String: Product] = [:]
  /// Transactions the app has been told about and has not finished yet.
  private static var open: [String: Transaction] = [:]
  private static var updatesTask: Task<Void, Never>?

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    self.channel = channel
    startListeningForUpdates()
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any]
      switch call.method {
      case "isAvailable":
        result(AppStore.canMakePayments)
      case "queryProducts":
        let ids = args?["ids"] as? [String] ?? []
        Task { result(await queryProducts(ids)) }
      case "purchase":
        let id = args?["id"] as? String ?? ""
        let account = args?["accountId"] as? String ?? ""
        Task { await purchase(id: id, accountId: account, result: result) }
      case "activePurchases":
        Task { result(await activePurchases()) }
      case "restore":
        Task {
          try? await AppStore.sync()
          result(await activePurchases())
        }
      case "complete":
        let id = args?["id"] as? String ?? ""
        Task {
          if let transaction = open[id] {
            await transaction.finish()
            open[id] = nil
          }
          result(true)
        }
      case "redeemCode":
        DispatchQueue.main.async {
          SKPaymentQueue.default().presentCodeRedemptionSheet()
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func queryProducts(_ ids: [String]) async -> [[String: Any]] {
    guard let found = try? await Product.products(for: ids) else { return [] }
    var list: [[String: Any]] = []
    for product in found {
      products[product.id] = product
      let micros = NSDecimalNumber(decimal: product.price * 1_000_000).intValue
      let unit = product.subscription?.subscriptionPeriod.unit
      list.append([
        "id": product.id,
        "title": product.displayName,
        "price": product.displayPrice,
        "priceMicros": micros,
        "currency": product.priceFormatStyle.currencyCode,
        "period": unit == .year ? "year" : "month",
      ])
    }
    return list
  }

  private static func purchase(id: String, accountId: String, result: @escaping FlutterResult) async {
    guard let product = products[id] else {
      result(FlutterError(code: "unknown_product", message: "Product \(id) is not loaded", details: nil))
      return
    }
    var options: Set<Product.PurchaseOption> = []
    if let token = UUID(uuidString: accountId) {
      options.insert(.appAccountToken(token))
    }
    do {
      switch try await product.purchase(options: options) {
      case .success(.verified(let transaction)):
        open[String(transaction.id)] = transaction
        emit("purchased", record(transaction))
      case .success(.unverified):
        emit("failed", nil, "The purchase could not be verified")
      case .pending:
        emit("pending", nil)
      case .userCancelled:
        emit("cancelled", nil)
      @unknown default:
        emit("failed", nil)
      }
      result(nil)
    } catch {
      emit("failed", nil, error.localizedDescription)
      result(nil)
    }
  }

  /// Valid means not expired, revoked or replaced by an upgrade (native
  /// `updatePurchasedProducts`).
  private static func isActive(_ transaction: Transaction) -> Bool {
    if transaction.revocationDate != nil || transaction.isUpgraded { return false }
    if let expiry = transaction.expirationDate, expiry < Date() { return false }
    return true
  }

  /// Oldest expiry first, so the last one is the latest subscription.
  private static func activePurchases() async -> [[String: Any]] {
    var active: [Transaction] = []
    for await entitlement in Transaction.currentEntitlements {
      if case .verified(let transaction) = entitlement, isActive(transaction) {
        active.append(transaction)
      }
    }
    active.sort { ($0.expirationDate ?? .distantPast) < ($1.expirationDate ?? .distantPast) }
    for transaction in active { open[String(transaction.id)] = transaction }
    return active.map(record)
  }

  private static func startListeningForUpdates() {
    updatesTask?.cancel()
    updatesTask = Task(priority: .background) {
      for await update in Transaction.updates {
        guard case .verified(let transaction) = update, isActive(transaction) else { continue }
        open[String(transaction.id)] = transaction
        emit("purchased", record(transaction))
      }
    }
  }

  private static func record(_ transaction: Transaction) -> [String: Any] {
    [
      "platform": "ios",
      "productId": transaction.productID,
      "originalTransactionId": String(transaction.originalID),
      "transactionId": String(transaction.id),
      "json": String(data: transaction.jsonRepresentation, encoding: .utf8) ?? "",
    ]
  }

  private static func emit(_ status: String, _ purchase: [String: Any]?, _ message: String? = nil) {
    var args: [String: Any] = ["status": status]
    if let purchase = purchase { args["purchase"] = purchase }
    if let message = message { args["message"] = message }
    DispatchQueue.main.async { channel?.invokeMethod("onPurchase", arguments: args) }
  }
}

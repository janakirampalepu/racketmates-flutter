import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RacketmatesPlatformChannels") {
      DeviceIntegrityChannel.register(with: registrar.messenger())
      NativeSessionChannel.register(with: registrar.messenger())
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

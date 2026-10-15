import Flutter
import GameKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var native: ShahDozdNative?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ShahDozdNative") {
      native = ShahDozdNative(messenger: registrar.messenger())
    }
  }
}

/// Game Center and iCloud key-value storage for lib/app/native.dart
/// (channel "shahdozd/native"). Adapted from the Mafia app's native plugin.
final class ShahDozdNative: NSObject, GKGameCenterControllerDelegate {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "shahdozd/native", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result)
    }
    NotificationCenter.default.addObserver(
      forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
      object: NSUbiquitousKeyValueStore.default, queue: .main
    ) { _ in }
    NSUbiquitousKeyValueStore.default.synchronize()
  }

  private var topController: UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    var vc = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }?.rootViewController
    while let presented = vc?.presentedViewController { vc = presented }
    return vc
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "gcAuthenticate":
      authenticate(result)
    case "gcReport":
      report(args, result)
    case "gcShowDashboard":
      DispatchQueue.main.async {
        let controller = GKGameCenterViewController(state: .dashboard)
        controller.gameCenterDelegate = self
        self.topController?.present(controller, animated: true)
        result(nil)
      }
    case "kvGet":
      let store = NSUbiquitousKeyValueStore.default
      store.synchronize()
      result(store.string(forKey: args["key"] as? String ?? ""))
    case "kvSet":
      guard let key = args["key"] as? String, let value = args["value"] as? String else {
        result(false)
        return
      }
      let store = NSUbiquitousKeyValueStore.default
      store.set(value, forKey: key)
      result(store.synchronize())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func authenticate(_ result: @escaping FlutterResult) {
    let player = GKLocalPlayer.local
    if player.isAuthenticated {
      result(["authenticated": true])
      return
    }
    var answered = false
    DispatchQueue.main.async {
      player.authenticateHandler = { [weak self] viewController, _ in
        if let viewController = viewController {
          self?.topController?.present(viewController, animated: true)
          return
        }
        if answered { return }
        answered = true
        result(["authenticated": GKLocalPlayer.local.isAuthenticated])
      }
    }
  }

  private func report(_ args: [String: Any], _ result: @escaping FlutterResult) {
    guard GKLocalPlayer.local.isAuthenticated else {
      result(nil)
      return
    }
    let group = DispatchGroup()
    if let board = args["leaderboard"] as? String, let score = args["score"] as? Int {
      group.enter()
      GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [board]) { _ in group.leave() }
    }
    let ids = args["achievements"] as? [String] ?? []
    if !ids.isEmpty {
      let achievements = ids.map { id -> GKAchievement in
        let a = GKAchievement(identifier: id)
        a.percentComplete = 100
        a.showsCompletionBanner = true
        return a
      }
      group.enter()
      GKAchievement.report(achievements) { _ in group.leave() }
    }
    group.notify(queue: .main) { result(nil) }
  }

  func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    gameCenterViewController.dismiss(animated: true)
  }
}

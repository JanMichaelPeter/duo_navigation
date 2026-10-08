import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Registered here rather than in FlutterImplicitEngineDelegate (Flutter
    // 3.38+), so the example builds on Flutter 3.35 too. With scenes the
    // plugins go to the launch engine that the first scene's view uses.
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

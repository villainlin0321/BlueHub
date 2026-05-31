import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "bluehub/app_icon"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(nil)
          return
        }
        self.handleMethodCall(call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 处理 Flutter 侧的图标切换请求：中文语言使用 AppIconZh，否则恢复默认主图标。
  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setIcon":
      let args = call.arguments as? [String: Any]
      let isChinese = (args?["isChinese"] as? Bool) ?? false
      setAppIcon(isChinese: isChinese, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// 切换 iOS Alternate Icon（需要在 Info.plist 的 CFBundleAlternateIcons 中声明）。
  private func setAppIcon(isChinese: Bool, result: @escaping FlutterResult) {
    guard UIApplication.shared.supportsAlternateIcons else {
      result(nil)
      return
    }

    let targetName: String? = isChinese ? "AppIconZh" : nil
    if UIApplication.shared.alternateIconName == targetName {
      result(nil)
      return
    }

    DispatchQueue.main.async {
      UIApplication.shared.setAlternateIconName(targetName) { error in
        if let error {
          result(
            FlutterError(
              code: "ICON_CHANGE_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }
        result(nil)
      }
    }
  }
}

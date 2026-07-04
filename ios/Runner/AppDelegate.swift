import Flutter
import Foundation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "bluehub/app_icon"
  private let nativeProbeUrl = "http://39.101.190.245:8090"

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
    case "probeHttp":
      let args = call.arguments as? [String: Any]
      let targetUrl = (args?["url"] as? String) ?? nativeProbeUrl
      probeHttp(urlString: targetUrl, result: result)
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

  /// 通过 iOS 原生 URLSession 请求目标地址，并把成功/失败信息回传给 Flutter 侧日志系统。
  private func probeHttp(urlString: String, result: @escaping FlutterResult) {
    guard let url = URL(string: urlString) else {
      result([
        "ok": false,
        "stage": "invalid-url",
        "target": urlString
      ])
      return
    }
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 15
    configuration.timeoutIntervalForResource = 15
    let session = URLSession(configuration: configuration)

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    // #region debug-point B:native-probe
    let task = session.dataTask(with: request) { data, response, error in
      if let error {
        result([
          "ok": false,
          "stage": "request-error",
          "target": url.absoluteString,
          "errorDomain": (error as NSError).domain,
          "errorCode": (error as NSError).code,
          "errorText": error.localizedDescription
        ])
        return
      }

      let httpResponse = response as? HTTPURLResponse
      result([
        "ok": true,
        "stage": "success",
        "target": url.absoluteString,
        "statusCode": httpResponse?.statusCode as Any,
        "mimeType": httpResponse?.mimeType as Any,
        "bodyLength": data?.count as Any
      ])
    }
    // #endregion
    task.resume()
  }
}

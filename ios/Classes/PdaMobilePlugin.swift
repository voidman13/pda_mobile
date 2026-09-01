import Flutter
import UIKit

public final class PdaMobilePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let scannerMethodChannel = "pda_mobile/bld_scanner"
  private static let scannerEventChannel = "pda_mobile/bld_scanner/events"
  private static let keyboardChannel = "pda_mobile/keyboard_guard"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = PdaMobilePlugin()

    let scannerMethods = FlutterMethodChannel(
      name: scannerMethodChannel,
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: scannerMethods)

    let scannerEvents = FlutterEventChannel(
      name: scannerEventChannel,
      binaryMessenger: registrar.messenger()
    )
    scannerEvents.setStreamHandler(instance)

    let keyboardMethods = FlutterMethodChannel(
      name: keyboardChannel,
      binaryMessenger: registrar.messenger()
    )
    keyboardMethods.setMethodCallHandler { call, result in
      if call.method == "setImeEnabled" {
        // iOS owns software-keyboard visibility through UIResponder focus.
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startScan", "stopScan":
      result(FlutterError(
        code: "scanner_unavailable",
        message: "The built-in BLD N60 scanner is only available on Android hardware.",
        details: nil
      ))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    nil
  }
}

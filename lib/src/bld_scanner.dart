import 'package:flutter/services.dart';

/// Controls the built-in barcode scanner on a BLD N60 device.
class BldScanner {
  BldScanner._();

  static final BldScanner instance = BldScanner._();

  static const _methods = MethodChannel('pda_mobile/bld_scanner');
  static const _events = EventChannel('pda_mobile/bld_scanner/events');

  static final Stream<String> _results = _events
      .receiveBroadcastStream()
      .where((event) => event is String)
      .cast<String>()
      .asBroadcastStream();

  /// Values received from both software and physical scan buttons.
  Stream<String> get results => _results;

  Future<void> start() => _methods.invokeMethod<void>('startScan');

  Future<void> stop() => _methods.invokeMethod<void>('stopScan');
}

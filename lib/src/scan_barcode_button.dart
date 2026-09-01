import 'dart:async';

import 'package:flutter/material.dart';

import 'bld_scanner.dart';

/// A scan trigger that reports barcode values through [onScanned].
///
/// Pass any widget to [child] to replace the default Material scan button.
class ScanBarcodeButton extends StatefulWidget {
  const ScanBarcodeButton({
    required this.onScanned,
    this.child,
    this.onError,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  });

  final ValueChanged<String> onScanned;
  final Widget? child;
  final ValueChanged<Object>? onError;
  final HitTestBehavior behavior;

  @override
  State<ScanBarcodeButton> createState() => _ScanBarcodeButtonState();
}

class _ScanBarcodeButtonState extends State<ScanBarcodeButton> {
  final BldScanner _scanner = BldScanner.instance;
  StreamSubscription<String>? _subscription;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _subscription = _scanner.results.listen(
      (barcode) {
        if (mounted) setState(() => _isScanning = false);
        widget.onScanned(barcode);
      },
      onError: (Object error) {
        if (mounted) setState(() => _isScanning = false);
        widget.onError?.call(error);
      },
    );
  }

  Future<void> _toggleScan() async {
    final shouldStart = !_isScanning;
    try {
      if (shouldStart) {
        await _scanner.start();
      } else {
        await _scanner.stop();
      }
      if (mounted) setState(() => _isScanning = shouldStart);
    } catch (error) {
      if (mounted) setState(() => _isScanning = false);
      widget.onError?.call(error);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child case final child?) {
      return Stack(
        key: const Key('scan-barcode-custom-trigger'),
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned.fill(
            child: GestureDetector(
              behavior: widget.behavior,
              onTap: _toggleScan,
            ),
          ),
        ],
      );
    }

    return FilledButton.icon(
      key: const Key('scan-barcode-button'),
      onPressed: _toggleScan,
      icon: Icon(_isScanning ? Icons.stop : Icons.document_scanner),
      label: Text(_isScanning ? 'STOP' : 'SCAN BARCODE'),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
    );
  }
}

# pda_mobile

Flutter plugin for the built-in barcode scanner on the BLD N60 Android PDA.

## Usage

The default trigger renders a `SCAN BARCODE` button:

```dart
ScanBarcodeButton(
  onScanned: (barcode) => print(barcode),
  onError: (error) => print(error),
)
```

Pass any widget as `child` to use a custom trigger:

```dart
ScanBarcodeButton(
  onScanned: (barcode) => setState(() => value = barcode),
  child: Container(
    padding: const EdgeInsets.all(12),
    child: const Row(
      children: [
        Icon(Icons.qr_code_scanner),
        Text('Бараа уншуулах'),
      ],
    ),
  ),
)
```

For direct control without a widget:

```dart
final scanner = BldScanner.instance;
final subscription = scanner.results.listen((barcode) {});

await scanner.start();
await scanner.stop();
```

This plugin currently supports Android and expects the BLD scanner broadcast
actions available on the N60 device.

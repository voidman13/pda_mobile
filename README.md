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

## Physical keypad with TextFields

Make the app activity extend the package activity so N60 keypad events can be
captured before Android opens the software keyboard:

```kotlin
package com.example.my_app

import com.example.pda_mobile.PdaFlutterActivity

class MainActivity : PdaFlutterActivity()
```

Create one controller for a group of text fields:

```dart
final keyboard = PdaKeyboardController(fieldCount: 3);

TextField(
  controller: keyboard.textControllerAt(index),
  focusNode: keyboard.focusNodeAt(index),
  textInputAction: TextInputAction.done,
  onSubmitted: (_) => keyboard.finishEditing(index),
)
```

The focused field is selected automatically. After `Done`, physical keypad
characters and Backspace continue editing the selected field without opening
the IME. To stop routing physical keys to a field:

```dart
keyboard.unselect();
```

Select a field without focusing it or opening the IME:

```dart
keyboard.select(index);
```

Listen to the controller to rebuild selection indicators based on
`keyboard.selectedIndex`, and dispose it with the owning widget.

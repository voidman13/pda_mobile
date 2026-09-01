import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pda_mobile/pda_mobile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('pda_mobile/bld_scanner');
  const eventChannel = MethodChannel('pda_mobile/bld_scanner/events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(eventChannel, (_) async => null);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockMethodCallHandler(eventChannel, null);
  });

  testWidgets('shows the default scan button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ScanBarcodeButton(onScanned: (_) {})),
      ),
    );

    expect(find.text('SCAN BARCODE'), findsOneWidget);
    expect(find.byKey(const Key('scan-barcode-button')), findsOneWidget);
  });

  testWidgets('accepts any custom widget and starts scanning on tap', (
    tester,
  ) async {
    var startCalls = 0;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      if (call.method == 'startScan') startCalls++;
      return null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanBarcodeButton(
            onScanned: (_) {},
            child: const Card(child: Text('My custom scanner')),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('scan-barcode-custom-trigger')));
    await tester.pump();

    expect(startCalls, 1);
    expect(find.text('My custom scanner'), findsOneWidget);
    expect(find.text('SCAN BARCODE'), findsNothing);
  });
}

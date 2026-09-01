import 'package:flutter_test/flutter_test.dart';
import 'package:pda_mobile/main.dart';

void main() {
  testWidgets('scanner home shows BLD scan action', (tester) async {
    await tester.pumpWidget(const PdaScannerApp());

    expect(find.text('BLD N60 Scanner Test'), findsOneWidget);
    expect(find.text('Barcode уншуулаагүй байна'), findsOneWidget);
    expect(find.text('SCAN BARCODE'), findsOneWidget);
  });
}

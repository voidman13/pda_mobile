import 'package:flutter/material.dart';
import 'package:pda_mobile/pda_mobile.dart';

void main() {
  runApp(const MaterialApp(home: ScannerTestPage()));
}

class ScannerTestPage extends StatefulWidget {
  const ScannerTestPage({super.key});

  @override
  State<ScannerTestPage> createState() => _ScannerTestPageState();
}

class _ScannerTestPageState extends State<ScannerTestPage> {
  String barcode = 'Barcode уншуулаагүй';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(barcode),
            const Spacer(),
            ScanBarcodeButton(
              onScanned: (value) {
                setState(() => barcode = value);
              },
              onError: (error) {
                setState(() => barcode = 'Алдаа: $error');
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const PdaScannerApp());

class BldScanner {
  static const _methods = MethodChannel('pda_mobile/bld_scanner');
  static const _events = EventChannel('pda_mobile/bld_scanner/events');

  Stream<String> get results => _events
      .receiveBroadcastStream()
      .where((event) => event is String)
      .cast<String>();

  Future<void> start() => _methods.invokeMethod<void>('startScan');

  Future<void> stop() => _methods.invokeMethod<void>('stopScan');
}

class PdaScannerApp extends StatelessWidget {
  const PdaScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLD N60 Scanner Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ScannerHomePage(),
    );
  }
}

class ScannerHomePage extends StatefulWidget {
  const ScannerHomePage({super.key});

  @override
  State<ScannerHomePage> createState() => _ScannerHomePageState();
}

class _ScannerHomePageState extends State<ScannerHomePage> {
  final _scanner = BldScanner();
  StreamSubscription<String>? _subscription;
  String? _barcode;
  String _status = 'SCAN товчийг дарна уу';
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _subscription = _scanner.results.listen(
      (barcode) {
        if (!mounted) return;
        setState(() {
          _barcode = barcode;
          _status = 'Амжилттай уншлаа';
          _scanning = false;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _status = 'Scanner алдаа: $error';
          _scanning = false;
        });
      },
    );
  }

  Future<void> _startScan() async {
    setState(() {
      _status = 'Barcode руу чиглүүлнэ үү...';
      _scanning = true;
    });

    try {
      await _scanner.start();
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'Scanner ассангүй: ${error.message ?? error.code}';
        _scanning = false;
      });
    }
  }

  Future<void> _stopScan() async {
    await _scanner.stop();
    if (!mounted) return;
    setState(() {
      _status = 'Scan зогслоо';
      _scanning = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('BLD N60 Scanner Test')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Icon(
                        _scanning
                            ? Icons.document_scanner
                            : Icons.qr_code_scanner,
                        size: 72,
                        color: _scanning ? colors.tertiary : colors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _status,
                        key: const Key('scan-status'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              _barcode ?? 'Barcode уншуулаагүй байна',
                              key: const Key('barcode-result'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FilledButton.icon(
                key: const Key('scan-button'),
                onPressed: _scanning ? _stopScan : _startScan,
                icon: Icon(_scanning ? Icons.stop : Icons.document_scanner),
                label: Text(_scanning ? 'STOP' : 'SCAN BARCODE'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Хажуугийн физик scan товч мөн ажиллана.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

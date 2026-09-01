import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pda_mobile/pda_mobile.dart';

void main() => runApp(const ScannerExampleApp());

class ScannerExampleApp extends StatelessWidget {
  const ScannerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PDA Scanner Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ScanButtonScreen(),
          PhysicalButtonScreen(),
          TextFieldScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan button',
          ),
          NavigationDestination(
            icon: Icon(Icons.touch_app),
            label: 'Device button',
          ),
          NavigationDestination(
            icon: Icon(Icons.text_fields),
            label: 'TextField',
          ),
        ],
      ),
    );
  }
}

class ScanButtonScreen extends StatefulWidget {
  const ScanButtonScreen({super.key});

  @override
  State<ScanButtonScreen> createState() => _ScanButtonScreenState();
}

class _ScanButtonScreenState extends State<ScanButtonScreen> {
  String? _barcode;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return _ResultLayout(
      title: 'Дэлгэцийн товчоор уншуулах',
      description: 'SCAN BARCODE товчийг дараад barcode руу чиглүүлнэ үү.',
      barcode: _barcode,
      error: _error,
      action: ScanBarcodeButton(
        onScanned: (barcode) {
          setState(() {
            _barcode = barcode;
            _error = null;
          });
        },
        onError: (error) {
          setState(() => _error = error.toString());
        },
      ),
    );
  }
}

class PhysicalButtonScreen extends StatefulWidget {
  const PhysicalButtonScreen({super.key});

  @override
  State<PhysicalButtonScreen> createState() => _PhysicalButtonScreenState();
}

class _PhysicalButtonScreenState extends State<PhysicalButtonScreen> {
  StreamSubscription<String>? _subscription;
  String? _barcode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = BldScanner.instance.results.listen(
      (barcode) {
        if (!mounted) return;
        setState(() {
          _barcode = barcode;
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _error = error.toString());
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ResultLayout(
      title: 'Device-ийн товчоор уншуулах',
      description:
          'Энэ дэлгэц scan товчгүй. PDA device-ийн хажуугийн physical scan товчийг дарна уу.',
      barcode: _barcode,
      error: _error,
    );
  }
}

class _ResultLayout extends StatelessWidget {
  const _ResultLayout({
    required this.title,
    required this.description,
    required this.barcode,
    required this.error,
    this.action,
  });

  final String title;
  final String description;
  final String? barcode;
  final String? error;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(description, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Уншсан barcode',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              barcode ?? 'Barcode уншуулаагүй байна',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Алдаа: $error',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (action case final action?) ...[
              const SizedBox(height: 8),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class TextFieldScreen extends StatefulWidget {
  const TextFieldScreen({super.key});

  @override
  State<TextFieldScreen> createState() => _TextFieldScreenState();
}

class _TextFieldScreenState extends State<TextFieldScreen> {
  final _keyboard = PdaKeyboardController(fieldCount: 3);

  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _keyboard.addListener(_onKeyboardChanged);
    _subscription = BldScanner.instance.results.listen((barcode) {
      if (!mounted) return;
      if (_keyboard.selectedIndex != null) {
        _keyboard.textControllerAt(_keyboard.selectedIndex ?? 0).text = barcode;
      }
    });
  }

  void _onKeyboardChanged() => setState(() {});

  @override
  void dispose() {
    _keyboard.removeListener(_onKeyboardChanged);
    _keyboard.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdaKeyboardRegion(
      controller: _keyboard,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Сонгосон field: ${_keyboard.selectedIndex == null ? '-' : _keyboard.selectedIndex! + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _keyboard.selectedIndex == null
                      ? null
                      : _keyboard.unselect,
                  icon: const Icon(Icons.deselect),
                  label: const Text('Unselect'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < _keyboard.fieldCount; index++) ...[
              Row(
                children: [
                  selectTextFieldWidget(index),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: _keyboard.selectedIndex == index ? 2 : 0.5,
                          color: _keyboard.selectedIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        controller: _keyboard.textControllerAt(index),
                        focusNode: _keyboard.focusNodeAt(index),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _keyboard.finishEditing(index),
                        decoration: InputDecoration.collapsed(
                          hintText: 'TextField ${index + 1}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget selectTextFieldWidget(int index) {
    final isSelected = _keyboard.selectedIndex == index;

    return Semantics(
      selected: isSelected,
      button: true,
      label: 'TextField ${index + 1}-ийг сонгох',
      child: InkWell(
        onTap: () => _keyboard.select(index),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              border: Border.all(
                width: 2,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

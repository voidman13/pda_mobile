import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          FocusManager.instance.primaryFocus?.unfocus();
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
  static const _keyboardGuard = MethodChannel('pda_mobile/keyboard_guard');
  static const _backspaceKeyCode = 67;

  final _controllers = List.generate(3, (_) => TextEditingController());
  final _focusNodes = List.generate(3, (_) => FocusNode());
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    for (var index = 0; index < _focusNodes.length; index++) {
      _focusNodes[index].addListener(() => _onFocusChanged(index));
    }
    _keyboardGuard.setMethodCallHandler(_onNativeMethodCall);
  }

  Future<void> _setImeEnabled(bool enabled) {
    return _keyboardGuard.invokeMethod<void>('setImeEnabled', {
      'enabled': enabled,
    });
  }

  void _onFocusChanged(int index) {
    if (_focusNodes[index].hasFocus) {
      if (_selectedIndex != index) {
        setState(() => _selectedIndex = index);
      }
      _setImeEnabled(true);
      return;
    }

    if (!_focusNodes.any((node) => node.hasFocus)) {
      _setImeEnabled(false);
    }
  }

  Future<void> _onNativeMethodCall(MethodCall call) async {
    if (call.method != 'onPhysicalKey' || _selectedIndex == null) return;
    final arguments = Map<Object?, Object?>.from(call.arguments as Map);
    final keyCode = arguments['keyCode'] as int;
    final unicodeChar = arguments['unicodeChar'] as int;

    if (keyCode == _backspaceKeyCode) {
      _deleteFromSelectedField();
    } else if (unicodeChar >= 0x20) {
      _insertIntoSelectedField(String.fromCharCode(unicodeChar));
    }
  }

  TextEditingController get _selectedController =>
      _controllers[_selectedIndex!];

  void _insertIntoSelectedField(String character) {
    final controller = _selectedController;
    final value = controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final updatedText = value.text.replaceRange(
      selection.start,
      selection.end,
      character,
    );
    controller.value = value.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(
        offset: selection.start + character.length,
      ),
      composing: TextRange.empty,
    );
  }

  void _deleteFromSelectedField() {
    final controller = _selectedController;
    final value = controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);

    if (!selection.isCollapsed) {
      controller.value = value.copyWith(
        text: value.text.replaceRange(selection.start, selection.end, ''),
        selection: TextSelection.collapsed(offset: selection.start),
        composing: TextRange.empty,
      );
    } else if (selection.start > 0) {
      controller.value = value.copyWith(
        text: value.text.replaceRange(selection.start - 1, selection.start, ''),
        selection: TextSelection.collapsed(offset: selection.start - 1),
        composing: TextRange.empty,
      );
    }
  }

  void _unselectField() {
    FocusManager.instance.primaryFocus?.unfocus();
    _setImeEnabled(false);
    setState(() => _selectedIndex = null);
  }

  @override
  void dispose() {
    _keyboardGuard.setMethodCallHandler(null);
    _setImeEnabled(false);
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Сонгосон field: ${_selectedIndex == null ? '-' : _selectedIndex! + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _selectedIndex == null ? null : _unselectField,
                icon: const Icon(Icons.deselect),
                label: const Text('Unselect'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _controllers.length; index++) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  width: _selectedIndex == index ? 2 : 0.5,
                  color: _selectedIndex == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textInputAction: TextInputAction.done,
                onTap: () {
                  if (_selectedIndex != index) {
                    setState(() => _selectedIndex = index);
                  }
                },
                onSubmitted: (_) => _focusNodes[index].unfocus(),
                decoration: InputDecoration.collapsed(
                  hintText: 'TextField ${index + 1}',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

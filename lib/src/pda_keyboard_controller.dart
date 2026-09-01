import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Manages text fields for the BLD N60 physical keypad.
///
/// A focused field becomes selected automatically. When focus is removed, the
/// selection remains, allowing physical keypad input without opening the IME.
class PdaKeyboardController extends ChangeNotifier {
  PdaKeyboardController({required int fieldCount})
    : assert(fieldCount > 0),
      _textControllers = List.generate(
        fieldCount,
        (_) => TextEditingController(),
      ),
      _focusNodes = List.generate(fieldCount, (_) => FocusNode()) {
    for (var index = 0; index < fieldCount; index++) {
      _focusNodes[index].addListener(() => _onFocusChanged(index));
    }
    _channel.setMethodCallHandler(_onNativeMethodCall);
  }

  static const MethodChannel _channel = MethodChannel(
    'pda_mobile/keyboard_guard',
  );
  static const int _backspaceKeyCode = 67;

  final List<TextEditingController> _textControllers;
  final List<FocusNode> _focusNodes;
  int? _selectedIndex;

  int get fieldCount => _textControllers.length;
  int? get selectedIndex => _selectedIndex;

  TextEditingController textControllerAt(int index) => _textControllers[index];

  FocusNode focusNodeAt(int index) => _focusNodes[index];

  /// Removes focus but keeps [selectedIndex] for physical keypad input.
  void finishEditing(int index) => _focusNodes[index].unfocus();

  /// Selects a field for physical input without focusing its TextField.
  void select(int index) {
    RangeError.checkValidIndex(index, _textControllers, 'index');
    for (final focusNode in _focusNodes) {
      focusNode.unfocus();
    }
    _setImeEnabled(false);
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  /// Clears focus and selection. Physical keys are ignored afterwards.
  void unselect() {
    for (final focusNode in _focusNodes) {
      focusNode.unfocus();
    }
    _setImeEnabled(false);
    if (_selectedIndex == null) return;
    _selectedIndex = null;
    notifyListeners();
  }

  void _onFocusChanged(int index) {
    if (_focusNodes[index].hasFocus) {
      _setImeEnabled(true);
      if (_selectedIndex != index) {
        _selectedIndex = index;
        notifyListeners();
      }
      return;
    }
    if (!_focusNodes.any((node) => node.hasFocus)) {
      _setImeEnabled(false);
    }
  }

  Future<void> _setImeEnabled(bool enabled) {
    return _channel.invokeMethod<void>('setImeEnabled', {'enabled': enabled});
  }

  Future<void> _onNativeMethodCall(MethodCall call) async {
    if (call.method != 'onPhysicalKey' || _selectedIndex == null) return;
    final arguments = Map<Object?, Object?>.from(call.arguments as Map);
    final keyCode = arguments['keyCode'] as int;
    final unicodeChar = arguments['unicodeChar'] as int;

    if (keyCode == _backspaceKeyCode) {
      _deleteBackward();
    } else if (unicodeChar >= 0x20) {
      _insert(String.fromCharCode(unicodeChar));
    }
  }

  TextEditingController get _selectedController =>
      _textControllers[_selectedIndex!];

  void _insert(String character) {
    final controller = _selectedController;
    final value = controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    controller.value = value.copyWith(
      text: value.text.replaceRange(selection.start, selection.end, character),
      selection: TextSelection.collapsed(
        offset: selection.start + character.length,
      ),
      composing: TextRange.empty,
    );
  }

  void _deleteBackward() {
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

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    _setImeEnabled(false);
    for (final controller in _textControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}

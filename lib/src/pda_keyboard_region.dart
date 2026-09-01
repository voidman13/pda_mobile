import 'package:flutter/widgets.dart';

import 'pda_keyboard_controller.dart';

/// Limits a [PdaKeyboardController] to the screen or widget that owns it.
///
/// Tapping outside this region, disposing it, or backgrounding the app clears
/// the selected field automatically.
class PdaKeyboardRegion extends StatefulWidget {
  const PdaKeyboardRegion({
    required this.controller,
    required this.child,
    super.key,
  });

  final PdaKeyboardController controller;
  final Widget child;

  @override
  State<PdaKeyboardRegion> createState() => _PdaKeyboardRegionState();
}

class _PdaKeyboardRegionState extends State<PdaKeyboardRegion>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(PdaKeyboardRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.unselect();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      widget.controller.unselect();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.unselect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: widget.controller,
      onTapOutside: (_) => widget.controller.unselect(),
      child: widget.child,
    );
  }
}

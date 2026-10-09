import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Arranges a side column: the rail at the bottom, the actions above it.
///
/// The rail is laid out first and gets as much height as it needs, up to the
/// whole column (it scrolls beyond that); the actions get the rest. So when
/// space is short (a phone in landscape, large text, the keyboard), the tabs
/// stay reachable and the action stack scrolls. Use it in custom
/// `sideColumn` builders; the Material default does.
class DuoSideColumnLayout extends StatelessWidget {
  /// Places [actions] above [rail], [gap] apart.
  const DuoSideColumnLayout({
    super.key,
    required this.actions,
    this.rail,
    this.gap = 12,
  });

  /// The action stack (the `actions` the builder gets).
  final Widget actions;

  /// The rail (the `tabs` the builder gets), or null in a modal frame.
  final Widget? rail;

  /// The space between actions and rail, when both are there.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rail = this.rail;
    return CustomMultiChildLayout(
      delegate: _RailFirst(gap: rail == null ? 0 : gap),
      children: [
        LayoutId(id: _Slot.actions, child: actions),
        if (rail != null) LayoutId(id: _Slot.rail, child: rail),
      ],
    );
  }
}

enum _Slot { actions, rail }

class _RailFirst extends MultiChildLayoutDelegate {
  _RailFirst({required this.gap});

  final double gap;

  @override
  void performLayout(Size size) {
    var railHeight = 0.0;
    if (hasChild(_Slot.rail)) {
      final rail = layoutChild(
        _Slot.rail,
        BoxConstraints(maxWidth: size.width, maxHeight: size.height),
      );
      railHeight = rail.height;
      positionChild(
        _Slot.rail,
        Offset((size.width - rail.width) / 2, size.height - railHeight),
      );
    }
    final actionsHeight = math.max(0.0, size.height - railHeight - gap);
    layoutChild(
      _Slot.actions,
      BoxConstraints.tightFor(width: size.width, height: actionsHeight),
    );
    positionChild(_Slot.actions, Offset.zero);
  }

  @override
  bool shouldRelayout(_RailFirst oldDelegate) => gap != oldDelegate.gap;
}

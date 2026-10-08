import 'package:flutter/widgets.dart';

import '../a11y/focus.dart';
import '../a11y/semantics.dart';
import '../builders/builders.dart';
import '../models/action.dart';

/// Wraps a built action with what the package owns, in the title bar and in
/// the column: its semantics (button, label, enabled, badge, tap), its focus
/// identity across layout switches, and `DockAction.key`.
class DockActionItem extends StatelessWidget {
  /// Wraps [child], the action as the builder drew it.
  const DockActionItem({super.key, required this.action, required this.child});

  /// The action, with its guarded callback.
  final DockAction<Object?> action;

  /// The built action.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appKey = action.key;
    final label =
        action.semanticLabel ??
        action.tooltip ??
        action.label ??
        DockBuilders.of<Object?, Object?, Object?>(
          context,
        ).actionLabel?.call(context, action);
    return DockFocusMarker(
      id: ('action', action.id),
      child: DockSemantics.action(
        label: label,
        value: action.badge?.label,
        onTap: action.onPressed,
        child: appKey == null ? child : KeyedSubtree(key: appKey, child: child),
      ),
    );
  }
}

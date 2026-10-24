import 'package:flutter/widgets.dart';

import '../a11y/focus.dart';
import '../a11y/semantics.dart';
import '../builders/builders.dart';
import '../models/action.dart';

/// Wraps a built action with what the package owns, in the title bar and in
/// the column: its semantics (button, label, enabled, badge, tap), its focus
/// identity across layout switches, and `DuoAction.key`.
class DuoActionItem extends StatelessWidget {
  /// Wraps [child], the action as the builder drew it.
  const DuoActionItem({super.key, required this.action, required this.child});

  /// The action, with its guarded callback.
  final DuoAction<Object?> action;

  /// The built action.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appKey = action.key;
    final label =
        action.semanticLabel ??
        action.tooltip ??
        action.label ??
        DuoBuilders.of<Object?, Object?, Object?>(
          context,
        ).actionLabel?.call(context, action);
    assert(() {
      if (label == null) _debugReportUnlabeled(action);
      return true;
    }());
    return DuoFocusMarker(
      id: ('action', action.id),
      child: DuoSemantics.action(
        label: label,
        value: action.badge?.label,
        onTap: action.onPressed,
        child: appKey == null ? child : KeyedSubtree(key: appKey, child: child),
      ),
    );
  }

  // The ids of the unlabeled actions already reported, so each is named once.
  static final Set<Object> _debugReportedUnlabeled = {};

  static void _debugReportUnlabeled(DuoAction<Object?> action) {
    if (!_debugReportedUnlabeled.add(action.id)) return;
    debugPrint(
      'duo_navigation: action ${action.id} has no label, so assistive '
      'technology reads it only as "button". Give it a semanticLabel, tooltip '
      'or label, or set DuoBuilders.actionLabel (DuoMaterial.actionLabel names '
      'back and close).',
    );
  }
}

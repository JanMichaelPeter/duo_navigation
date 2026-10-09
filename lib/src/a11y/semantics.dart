import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The semantics duo_navigation gives tabs and actions, for builders that draw items
/// outside the package's wrappers (a custom bar that does not use
/// `DuoBarData.buildAction`, a custom rail).
///
/// Each helper makes one node with the role, state, label and tap action, and
/// excludes the child's own semantics, so the item reads the same whatever is
/// drawn. Unlike `Semantics(excludeSemantics: true, ...)` on its own, it keeps
/// the tap action, so assistive technology can activate the item.
abstract final class DuoSemantics {
  /// A tab: the tab role, [selected], [label], the badge as [value], the
  /// position as [hint] ("Tab 2 of 3") and the tap action.
  static Widget tab({
    required bool selected,
    required String? label,
    String? value,
    String? hint,
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return Semantics.fromProperties(
      container: true,
      properties: tabProperties(
        selected: selected,
        label: label,
        value: value,
        hint: hint,
        onTap: onTap,
      ),
      child: ExcludeSemantics(child: child),
    );
  }

  /// The semantics of [tab] as a value, for a tab bar that builds its item
  /// widgets itself and takes per-item semantics (such as a design system's
  /// `additionalSemantics` field). For one tab of a shell,
  /// `DuoTabsData.itemData(i).semanticsOf(context)` fills them in. Pass a null
  /// [onTap] when the item has a tap target of its own; a second tap action
  /// would split it into two nodes.
  static SemanticsProperties tabProperties({
    required bool selected,
    required String? label,
    String? value,
    String? hint,
    required VoidCallback? onTap,
  }) => SemanticsProperties(
    role: SemanticsRole.tab,
    selected: selected,
    label: label,
    value: value,
    hint: hint,
    onTap: onTap,
  );

  /// An action: a button with [label], the badge as [value], enabled while
  /// [onTap] is set, and the tap action.
  static Widget action({
    required String? label,
    String? value,
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: label,
      value: value,
      onTap: onTap,
      child: ExcludeSemantics(child: child),
    );
  }
}

import 'package:flutter/foundation.dart';

import 'dock_badge.dart';
import 'dock_icon.dart';

/// Marks a `copyWith` argument that was not passed.
const Object _unset = Object();

/// A top-level destination.
///
/// [T] is the type of [payload]: app data for custom builders, such as a
/// design system's tab item. Builders get it typed, without a cast.
@immutable
class DuoTab<T> {
  /// A destination identified by [id], with an [icon] and usually a [label].
  const DuoTab({
    required this.id,
    required this.icon,
    this.selectedIcon,
    this.label,
    this.badge,
    this.tooltip,
    this.semanticLabel,
    this.key,
    this.payload,
  });

  /// Identifies the tab: `DuoKeys.tab(id)` finds it, and focus follows it
  /// across layout changes.
  final Object id;

  /// The icon when not selected, and when selected without [selectedIcon].
  final DuoIcon icon;

  /// The icon when selected.
  final DuoIcon? selectedIcon;

  /// The label: under the icon in the tab bar, the tooltip in the rail.
  final String? label;

  /// A badge, drawn by the builders and read by assistive technology.
  final DuoBadge? badge;

  /// The tooltip; defaults to [label].
  final String? tooltip;

  /// What assistive technology reads for the tab; defaults to [label], then
  /// [tooltip].
  final String? semanticLabel;

  /// A key of the app's own (for example for UI tests), placed around the
  /// tab's item in the bar and in the rail, inside `DuoKeys.tab(id)`.
  final Key? key;

  /// App data for custom builders.
  final T? payload;

  /// The icon for the [selected] state.
  DuoIcon iconFor({required bool selected}) =>
      selected ? (selectedIcon ?? icon) : icon;

  /// A copy with the given fields replaced. Pass null for a nullable field to
  /// clear it.
  DuoTab<T> copyWith({
    Object? id,
    DuoIcon? icon,
    Object? selectedIcon = _unset,
    Object? label = _unset,
    Object? badge = _unset,
    Object? tooltip = _unset,
    Object? semanticLabel = _unset,
    Object? key = _unset,
    Object? payload = _unset,
  }) {
    return DuoTab<T>(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      selectedIcon: identical(selectedIcon, _unset)
          ? this.selectedIcon
          : selectedIcon as DuoIcon?,
      label: identical(label, _unset) ? this.label : label as String?,
      badge: identical(badge, _unset) ? this.badge : badge as DuoBadge?,
      tooltip: identical(tooltip, _unset) ? this.tooltip : tooltip as String?,
      semanticLabel: identical(semanticLabel, _unset)
          ? this.semanticLabel
          : semanticLabel as String?,
      key: identical(key, _unset) ? this.key : key as Key?,
      payload: identical(payload, _unset) ? this.payload : payload as T?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DuoTab<T> &&
      other.id == id &&
      other.icon == icon &&
      other.selectedIcon == selectedIcon &&
      other.label == label &&
      other.badge == badge &&
      other.tooltip == tooltip &&
      other.semanticLabel == semanticLabel &&
      other.key == key &&
      other.payload == payload;

  @override
  int get hashCode => Object.hash(
    id,
    icon,
    selectedIcon,
    label,
    badge,
    tooltip,
    semanticLabel,
    key,
    payload,
  );
}

import 'package:flutter/widgets.dart';

/// A top-level destination.
@immutable
class DockTab {
  /// A destination with an [icon] and usually a [label].
  const DockTab({
    required this.icon,
    this.selectedIcon,
    this.label,
    this.tooltip,
    this.data,
  });

  /// Icon when not selected (and when selected, without [selectedIcon]).
  final Widget icon;

  /// Icon when selected.
  final Widget? selectedIcon;

  /// Label in the tab bar; tooltip in the rail.
  final String? label;

  /// Tooltip; defaults to [label].
  final String? tooltip;

  /// Free slot for your own builders (badge count, ...).
  final Object? data;
}

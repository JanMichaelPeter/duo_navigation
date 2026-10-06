import 'package:flutter/material.dart';

/// A navigation action (back, close, share, "Done", ...).
///
/// Identity rules for the side column:
/// * Actions with [shared] = true are matched by [id] across pages. Their
///   widget State survives navigation, so they never flicker (the back button
///   uses this).
/// * All other actions belong to the page that declared them. When the page
///   changes they animate out and the new page's actions animate in, even if
///   two pages use the same id.
@immutable
class DockAction {
  /// An action with an [icon], a [label], or both. Icon actions move to the
  /// side column in wide mode; label-only actions stay in the title bar.
  const DockAction({
    required this.id,
    this.icon,
    this.label,
    this.tooltip,
    this.onPressed,
    this.shared = false,
    this.pinToBar = false,
    this.data,
  }) : assert(
         icon != null || label != null,
         'An DockAction needs an icon or a label.',
       );

  /// The back/close action. Shared across pages so it stays put while you
  /// navigate; if [onPressed] is null the page pops its own route.
  const DockAction.back({
    this.icon = const BackButtonIcon(),
    this.tooltip,
    this.onPressed,
    this.data,
  }) : id = backId,
       label = null,
       shared = true,
       pinToBar = false;

  /// The [id] of every [DockAction.back].
  static const Object backId = #nav_dock_back;

  /// Identifies the action within its page (or across pages if [shared]).
  final Object id;

  /// Icon for the title bar and the side-column chip.
  final Widget? icon;

  /// Text for label-only actions; also the default tooltip.
  final String? label;

  /// Tooltip and semantics label; defaults to [label].
  final String? tooltip;

  /// Called on tap; null disables the action. Taps are guarded: see
  /// [DockActionRegistration.guard].
  final VoidCallback? onPressed;

  /// Match this action across pages by [id] (see class docs).
  final bool shared;

  /// Keep this action in the title bar even in wide mode.
  /// Label-only actions always stay in the bar.
  final bool pinToBar;

  /// Free slot for your own builders (badge count, semantic role, ...).
  final Object? data;

  /// Whether this is the back/close action.
  bool get isBack => id == backId;

  /// Whether this action moves to the side column in wide mode.
  bool get canHoist => icon != null && !pinToBar;

  /// A copy with the given fields replaced; [id] stays the same.
  DockAction copyWith({
    Widget? icon,
    String? label,
    String? tooltip,
    VoidCallback? onPressed,
    bool? shared,
    bool? pinToBar,
    Object? data,
  }) {
    return DockAction(
      id: id,
      icon: icon ?? this.icon,
      label: label ?? this.label,
      tooltip: tooltip ?? this.tooltip,
      onPressed: onPressed ?? this.onPressed,
      shared: shared ?? this.shared,
      pinToBar: pinToBar ?? this.pinToBar,
      data: data ?? this.data,
    );
  }
}

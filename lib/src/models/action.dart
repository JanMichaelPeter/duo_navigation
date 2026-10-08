import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'dock_badge.dart';
import 'dock_icon.dart';

/// Marks a `copyWith` argument that was not passed.
const Object _unset = Object();

/// What an action is for. The role gives builders a styling hook and gives
/// the leading slot its meaning.
enum DockActionRole {
  /// Goes back one step. The leading action of pushed pages.
  back,

  /// Closes a flow or a full-screen dialog. The leading action of dialogs.
  close,

  /// The main action of the page ("Done", "Send").
  primary,

  /// Any other action. The default.
  secondary,

  /// An action that deletes or discards.
  destructive,

  /// Opens more actions (a menu).
  overflow,
}

/// Whether an action may move into the side column in wide mode.
enum DockHoist {
  /// Moves into the column when it has an icon (and hoisting is on).
  auto,

  /// Stays in the title bar in every mode.
  never,
}

/// Which leading action a page gets when it declares none
/// (`DockPageScope.impliedLeading`, `DockModalScope.impliedLeading`).
enum DockImpliedLeading {
  /// [DockAction.back].
  back,

  /// [DockAction.close], for modals that are dismissed rather than left.
  close,
}

/// Whether actions move into the side column in wide mode at all. Set on
/// `DockNavigationData`, overridden by `DockShell`, `DockModalScope` and
/// `DockPageScope`.
enum DockHoisting {
  /// Icon actions move into the column (unless they say
  /// `hoist: DockHoist.never`). The default.
  iconActions,

  /// Nothing moves: every page keeps all its actions, leading included, in
  /// its title bar, and the column holds only the rail. The bar data is the
  /// same in compact and wide mode.
  none,
}

/// A navigation action: back, close, share, "Done", …
///
/// [A] is the type of [payload]: app data for custom builders. Builders get it
/// typed, without a cast.
///
/// Identity rules for the side column:
/// * Actions with [shared] = true are matched by [id] across pages. Their
///   widget State survives navigation, so they never flicker (back and close
///   use this, and morph into each other).
/// * All other actions belong to the page that declared them. When the page
///   changes they animate out and the new page's actions animate in, even if
///   two pages use the same id.
@immutable
class DockAction<A> {
  /// An action with an [icon], a [label], or both. Icon actions move to the
  /// side column in wide mode; label-only actions stay in the title bar.
  const DockAction({
    required this.id,
    this.role = DockActionRole.secondary,
    this.icon,
    this.label,
    this.onPressed,
    this.enabled = true,
    this.badge,
    this.tooltip,
    this.semanticLabel,
    this.key,
    this.order = 0,
    this.hoist = DockHoist.auto,
    this.shared = false,
    this.guarded = true,
    this.cooldown,
    this.payload,
  }) : assert(
         icon != null || label != null,
         'A DockAction needs an icon or a label.',
       );

  /// Goes back. Shared across pages, so it stays in place while you navigate
  /// and morphs into [DockAction.close]. If [onPressed] is null, `DockPage`
  /// pops its route.
  ///
  /// A [label] such as "Cancel" is allowed; without an [icon] the action is
  /// text-only and stays in the title bar in every mode.
  const DockAction.back({
    this.icon = DockIcon.back,
    this.label,
    this.onPressed,
    this.enabled = true,
    this.tooltip,
    this.semanticLabel,
    this.key,
    this.hoist = DockHoist.auto,
    this.guarded = true,
    this.cooldown,
    this.payload,
  }) : id = backId,
       role = DockActionRole.back,
       badge = null,
       order = 0,
       shared = true,
       assert(
         icon != null || label != null,
         'A DockAction needs an icon or a label.',
       );

  /// Closes a flow or a full-screen dialog. The same identity as
  /// [DockAction.back], so the two morph into each other.
  const DockAction.close({
    this.icon = DockIcon.close,
    this.label,
    this.onPressed,
    this.enabled = true,
    this.tooltip,
    this.semanticLabel,
    this.key,
    this.hoist = DockHoist.auto,
    this.guarded = true,
    this.cooldown,
    this.payload,
  }) : id = backId,
       role = DockActionRole.close,
       badge = null,
       order = 0,
       shared = true,
       assert(
         icon != null || label != null,
         'A DockAction needs an icon or a label.',
       );

  /// The [id] of every [DockAction.back] and [DockAction.close].
  static const Object backId = #nav_dock_back;

  /// Identifies the action within its page (or across pages if [shared]).
  /// `DockKeys.action(id)` finds it.
  final Object id;

  /// What the action is for.
  final DockActionRole role;

  /// The icon, in the title bar and as a chip in the column.
  final DockIcon? icon;

  /// The text of text-only actions; also the default tooltip and semantic
  /// label.
  final String? label;

  /// Called on tap; null disables the action. Taps are guarded (see
  /// [guarded]).
  final VoidCallback? onPressed;

  /// Whether the action can be used. False: builders get a null
  /// `onPressed` and show it disabled.
  final bool enabled;

  /// A badge, drawn by the builders.
  final DockBadge? badge;

  /// The tooltip; defaults to [label].
  final String? tooltip;

  /// What assistive technology reads; defaults to [tooltip], then [label].
  final String? semanticLabel;

  /// A key of the app's own (for example for UI tests), placed around the
  /// action inside `DockKeys.action(id)`.
  final Key? key;

  /// Position among the page's actions in the column: lower values sit lower,
  /// closer to the rail. Equal values keep the declaration order. The leading
  /// action is always the lowest.
  final int order;

  /// Whether the action may move into the side column in wide mode.
  final DockHoist hoist;

  /// Match this action across pages by [id] (see the class docs).
  final bool shared;

  /// Whether taps go through the tap guard (only the page shown, not during a
  /// transition, not twice within the cooldown). False: every tap fires.
  final bool guarded;

  /// The cooldown between two taps on this action. Null: the tap guard's.
  final Duration? cooldown;

  /// App data for custom builders.
  final A? payload;

  /// Whether this is the back or close action.
  bool get isBack => id == backId;

  /// Whether this action moves to the side column in wide mode.
  bool get canHoist => icon != null && hoist == DockHoist.auto;

  /// The callback builders should use: null while disabled.
  VoidCallback? get effectiveOnPressed => enabled ? onPressed : null;

  /// A copy with the given fields replaced; [id] and [shared] stay the same.
  /// Pass null for a nullable field to clear it.
  DockAction<A> copyWith({
    DockActionRole? role,
    Object? icon = _unset,
    Object? label = _unset,
    Object? onPressed = _unset,
    bool? enabled,
    Object? badge = _unset,
    Object? tooltip = _unset,
    Object? semanticLabel = _unset,
    Object? key = _unset,
    int? order,
    DockHoist? hoist,
    bool? guarded,
    Object? cooldown = _unset,
    Object? payload = _unset,
  }) {
    return DockAction<A>(
      id: id,
      role: role ?? this.role,
      icon: identical(icon, _unset) ? this.icon : icon as DockIcon?,
      label: identical(label, _unset) ? this.label : label as String?,
      onPressed: identical(onPressed, _unset)
          ? this.onPressed
          : onPressed as VoidCallback?,
      enabled: enabled ?? this.enabled,
      badge: identical(badge, _unset) ? this.badge : badge as DockBadge?,
      tooltip: identical(tooltip, _unset) ? this.tooltip : tooltip as String?,
      semanticLabel: identical(semanticLabel, _unset)
          ? this.semanticLabel
          : semanticLabel as String?,
      key: identical(key, _unset) ? this.key : key as Key?,
      order: order ?? this.order,
      hoist: hoist ?? this.hoist,
      shared: shared,
      guarded: guarded ?? this.guarded,
      cooldown: identical(cooldown, _unset)
          ? this.cooldown
          : cooldown as Duration?,
      payload: identical(payload, _unset) ? this.payload : payload as A?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DockAction<A> &&
      other.id == id &&
      other.role == role &&
      other.icon == icon &&
      other.label == label &&
      other.onPressed == onPressed &&
      other.enabled == enabled &&
      other.badge == badge &&
      other.tooltip == tooltip &&
      other.semanticLabel == semanticLabel &&
      other.key == key &&
      other.order == order &&
      other.hoist == hoist &&
      other.shared == shared &&
      other.guarded == guarded &&
      other.cooldown == cooldown &&
      other.payload == payload;

  @override
  int get hashCode => Object.hash(
    id,
    role,
    icon,
    label,
    onPressed,
    enabled,
    badge,
    tooltip,
    semanticLabel,
    key,
    order,
    hoist,
    shared,
    guarded,
    cooldown,
    payload,
  );
}

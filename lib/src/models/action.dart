import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'dock_badge.dart';
import 'dock_icon.dart';

/// Marks a `copyWith` argument that was not passed.
const Object _unset = Object();

/// What an action is for. The role gives builders a styling hook and gives
/// the leading slot its meaning.
enum DuoActionRole {
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
enum DuoHoist {
  /// Moves into the column when it has an icon (and hoisting is on).
  auto,

  /// Stays in the title bar in every mode.
  never,
}

/// Which leading action a page gets when it declares none
/// (`DuoPageScope.impliedLeading`, `DuoModalScope.impliedLeading`).
enum DuoImpliedLeading {
  /// [DuoAction.back].
  back,

  /// [DuoAction.close], for modals that are dismissed rather than left.
  close,
}

/// The leading action of a modal's first page, app-wide
/// (`DuoNavigationData.modalLeading`).
///
/// It applies to modal starts: the first page of a `DuoModalScope` (also
/// the first page of a `Navigator` inside it), and a page presented as a
/// full-screen dialog or in a modal route that isn't a page (a sheet, a
/// dialog). A plain page pushed on the root navigator, such as a follow-up
/// page of a modal, is not a modal start and keeps back. The modal scope's
/// and the page's own settings win.
@immutable
class DuoModalLeading {
  /// Defaults for every modal's first page.
  const DuoModalLeading({this.implied, this.atEnd = false});

  /// The leading action implied when the page declares none. Null: close for
  /// a full-screen dialog, back otherwise.
  final DuoImpliedLeading? implied;

  /// Whether the leading action, implied or declared, sits at the end of the
  /// title bar (`DuoPageScope.leadingAtEnd`).
  final bool atEnd;

  @override
  bool operator ==(Object other) =>
      other is DuoModalLeading &&
      other.implied == implied &&
      other.atEnd == atEnd;

  @override
  int get hashCode => Object.hash(implied, atEnd);
}

/// Whether actions move into the side column in wide mode at all. Set on
/// `DuoNavigationData`, overridden by `DuoShell`, `DuoModalScope` and
/// `DuoPageScope`.
enum DuoHoisting {
  /// Icon actions move into the column (unless they say
  /// `hoist: DuoHoist.never`). The default.
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
class DuoAction<A> {
  /// An action with an [icon], a [label], or both. Icon actions move to the
  /// side column in wide mode; label-only actions stay in the title bar.
  const DuoAction({
    required this.id,
    this.role = DuoActionRole.secondary,
    this.icon,
    this.label,
    this.onPressed,
    this.enabled = true,
    this.badge,
    this.tooltip,
    this.semanticLabel,
    this.key,
    this.order = 0,
    this.hoist = DuoHoist.auto,
    this.shared = false,
    this.guarded = true,
    this.cooldown,
    this.payload,
  }) : assert(
         icon != null || label != null,
         'A DuoAction needs an icon or a label.',
       );

  /// Goes back. Shared across pages, so it stays in place while you navigate
  /// and morphs into [DuoAction.close]. If [onPressed] is null, `DuoPage`
  /// pops its route.
  ///
  /// A [label] such as "Cancel" is allowed; without an [icon] the action is
  /// text-only and stays in the title bar in every mode.
  const DuoAction.back({
    this.icon = DuoIcon.back,
    this.label,
    this.onPressed,
    this.enabled = true,
    this.tooltip,
    this.semanticLabel,
    this.key,
    this.hoist = DuoHoist.auto,
    this.guarded = true,
    this.cooldown,
    this.payload,
  }) : id = backId,
       role = DuoActionRole.back,
       badge = null,
       order = 0,
       shared = true,
       assert(
         icon != null || label != null,
         'A DuoAction needs an icon or a label.',
       );

  /// Closes a flow or a full-screen dialog. The same identity as
  /// [DuoAction.back], so the two morph into each other.
  const DuoAction.close({
    this.icon = DuoIcon.close,
    this.label,
    this.onPressed,
    this.enabled = true,
    this.tooltip,
    this.semanticLabel,
    this.key,
    this.hoist = DuoHoist.auto,
    this.guarded = true,
    this.cooldown,
    this.payload,
  }) : id = backId,
       role = DuoActionRole.close,
       badge = null,
       order = 0,
       shared = true,
       assert(
         icon != null || label != null,
         'A DuoAction needs an icon or a label.',
       );

  /// The [id] of every [DuoAction.back] and [DuoAction.close].
  static const Object backId = #duo_navigation_back;

  /// Identifies the action within its page (or across pages if [shared]).
  /// `DuoKeys.action(id)` finds it.
  final Object id;

  /// What the action is for.
  final DuoActionRole role;

  /// The icon, in the title bar and as a chip in the column.
  final DuoIcon? icon;

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
  final DuoBadge? badge;

  /// The tooltip; defaults to [label].
  final String? tooltip;

  /// What assistive technology reads; defaults to [tooltip], then [label].
  final String? semanticLabel;

  /// A key of the app's own (for example for UI tests), placed around the
  /// action inside `DuoKeys.action(id)`.
  final Key? key;

  /// Position among the page's actions in the column: lower values sit lower,
  /// closer to the rail. Equal values keep the declaration order. The leading
  /// action is always the lowest.
  final int order;

  /// Whether the action may move into the side column in wide mode.
  final DuoHoist hoist;

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
  bool get canHoist => icon != null && hoist == DuoHoist.auto;

  /// The callback builders should use: null while disabled.
  VoidCallback? get effectiveOnPressed => enabled ? onPressed : null;

  /// A copy with the given fields replaced; [id] and [shared] stay the same.
  /// Pass null for a nullable field to clear it.
  DuoAction<A> copyWith({
    DuoActionRole? role,
    Object? icon = _unset,
    Object? label = _unset,
    Object? onPressed = _unset,
    bool? enabled,
    Object? badge = _unset,
    Object? tooltip = _unset,
    Object? semanticLabel = _unset,
    Object? key = _unset,
    int? order,
    DuoHoist? hoist,
    bool? guarded,
    Object? cooldown = _unset,
    Object? payload = _unset,
  }) {
    return DuoAction<A>(
      id: id,
      role: role ?? this.role,
      icon: identical(icon, _unset) ? this.icon : icon as DuoIcon?,
      label: identical(label, _unset) ? this.label : label as String?,
      onPressed: identical(onPressed, _unset)
          ? this.onPressed
          : onPressed as VoidCallback?,
      enabled: enabled ?? this.enabled,
      badge: identical(badge, _unset) ? this.badge : badge as DuoBadge?,
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
      other is DuoAction<A> &&
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

import 'package:flutter/widgets.dart';

import '../geometry/layout_mode.dart';
import '../geometry/side.dart';
import 'action.dart';
import 'enums.dart';

/// Renders an action at a placement with the configured action builder.
typedef DockActionWidgetBuilder<A> =
    Widget Function(DockAction<A> action, DockActionPlacement placement);

/// What a page's title bar should show in the current mode.
///
/// In wide mode the actions that moved into the side column are in [hoisted]
/// and already rendered there; [leading] and [trailing] hold what stays in the
/// bar: label-only actions and actions with `hoist: DockHoist.never`. With
/// hoisting off (`DockHoisting.none`), nothing moves and the data is the same
/// in both modes.
///
/// [A] is the actions' payload type and [B] the type of [payload], the
/// page's data for the bar (a structured title, a bar style). Read it below a
/// `DockPageScope` with [DockBarData.of].
@immutable
class DockBarData<A, B> {
  /// Built by `DockPageScope`; you receive it in page builders.
  const DockBarData({
    required this.mode,
    required this.title,
    this.payload,
    required this.leading,
    required this.trailing,
    required this.hoisted,
    this.sideColumnSide,
    required DockActionWidgetBuilder<A> buildAction,
  }) : _buildAction = buildAction;

  /// The current layout mode.
  final DockLayoutMode mode;

  /// The page title.
  final Widget? title;

  /// The page's data for the bar, from `DockPageScope.barPayload`.
  final B? payload;

  /// The back or close action for the bar. Null in wide mode when it moved
  /// into the column; a text-only leading action ("Cancel") stays here in
  /// every mode.
  final DockAction<A>? leading;

  /// Actions for the bar. In wide mode only the ones that stay in the bar;
  /// the rest are in [hoisted].
  final List<DockAction<A>> trailing;

  /// Actions shown as side-column chips (wide mode only). Already rendered
  /// by the column; for information.
  final List<DockAction<A>> hoisted;

  /// Edge the side column is on when actions move into it; null otherwise
  /// (compact mode, or hoisting off).
  final DockSide? sideColumnSide;
  final DockActionWidgetBuilder<A> _buildAction;

  /// Whether the layout is [DockLayoutMode.wide].
  bool get isWide => mode == DockLayoutMode.wide;

  /// Whether [trailing] belongs at the start of the bar: the column is at the
  /// start edge, so bar actions follow it to the same side. `DockBarLayout`
  /// handles it.
  bool get trailingAtStart => sideColumnSide == DockSide.start;

  /// Renders an action with the configured action builder, with its keys.
  Widget buildAction(DockAction<A> action, DockActionPlacement placement) =>
      _buildAction(action, placement);

  /// The bar data of the nearest `DockPageScope`. Throws a [FlutterError]
  /// when there is none or its types don't match [A] and [B]; builders for
  /// any types use `DockBarData.of<Object?, Object?>`.
  static DockBarData<A, B> of<A, B>(BuildContext context) {
    final bar = context
        .dependOnInheritedWidgetOfExactType<DockBarDataScope>()
        ?.data;
    if (bar is DockBarData<A, B>) return bar;
    throw FlutterError.fromParts([
      if (bar == null)
        ErrorSummary('No DockPageScope found.')
      else
        ErrorSummary('The page\'s bar data does not match.'),
      if (bar == null)
        ErrorDescription(
          '${context.widget.runtimeType} reads the title bar of its page, and '
          'is not below a DockPageScope or DockPage.',
        )
      else
        ErrorDescription(
          'The page provides a ${bar.runtimeType}, and '
          '${context.widget.runtimeType} asked for DockBarData<$A, $B>.',
        ),
      ErrorHint(
        'Put a DockPageScope around the page (DockPage does it for you), and '
        'read it with the page\'s payload types, or with <Object?, Object?>.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// Like [of], but null when there is no matching `DockPageScope`.
  static DockBarData<A, B>? maybeOf<A, B>(BuildContext context) {
    final bar = context
        .dependOnInheritedWidgetOfExactType<DockBarDataScope>()
        ?.data;
    return bar is DockBarData<A, B> ? bar : null;
  }
}

/// Provides a page's [DockBarData] to its subtree. Inserted by
/// `DockPageScope`; not exported.
class DockBarDataScope extends InheritedWidget {
  /// Provides [data] to [child].
  const DockBarDataScope({super.key, required this.data, required super.child});

  /// The bar data, stored untyped so readers check its types themselves.
  final Object data;

  @override
  bool updateShouldNotify(DockBarDataScope oldWidget) =>
      !identical(data, oldWidget.data);
}

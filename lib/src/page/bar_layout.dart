import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Lays out a title bar: a [leading] action, a [title] and the [trailing]
/// actions, in the text direction.
///
/// * Normally: leading at the start, then the title, the actions at the end.
/// * With [actionsAtStart] (the side column is at the start edge, see
///   `DockBarData.trailingAtStart`): leading, then the actions, then the
///   title, so everything the thumb needs sits on the column's side.
/// * With [leadingAtEnd] (`DockBarData.leadingAtEnd`): the leading action
///   sits at the end edge, after the actions (a close action at the top
///   right).
/// * With [centerTitle]: the title is centered on the whole bar, as far as
///   the actions on either side allow.
///
/// It works with or without a leading action in every mode and mirrors in
/// right-to-left layouts. The default `DockAppBar` uses it; use it in custom
/// bars so they don't re-implement the mirroring.
class DockBarLayout extends StatelessWidget {
  /// Lays out the given parts; all are optional.
  const DockBarLayout({
    super.key,
    this.leading,
    this.title,
    this.trailing = const [],
    this.centerTitle = false,
    this.actionsAtStart = false,
    this.leadingAtEnd = false,
    this.spacing = 16,
    this.edgePadding = 4,
  });

  /// The back or close action.
  final Widget? leading;

  /// The title.
  final Widget? title;

  /// The actions, in reading order.
  final List<Widget> trailing;

  /// Whether the title is centered on the bar.
  final bool centerTitle;

  /// Whether the actions sit at the start, after [leading].
  final bool actionsAtStart;

  /// Whether [leading] sits at the end edge instead of the start.
  final bool leadingAtEnd;

  /// The space between the title and the actions on either side.
  final double spacing;

  /// The space between the bar's edges and the outermost parts.
  final double edgePadding;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final leading = this.leading;
    return CustomMultiChildLayout(
      delegate: _BarLayoutDelegate(
        textDirection: Directionality.of(context),
        centerTitle: centerTitle,
        actionsAtStart: actionsAtStart,
        leadingAtEnd: leadingAtEnd,
        spacing: spacing,
        edgePadding: edgePadding,
      ),
      children: [
        if (leading != null) LayoutId(id: _Part.leading, child: leading),
        if (trailing.isNotEmpty)
          LayoutId(
            id: _Part.trailing,
            child: Row(mainAxisSize: MainAxisSize.min, children: trailing),
          ),
        if (title != null) LayoutId(id: _Part.title, child: title),
      ],
    );
  }
}

enum _Part { leading, trailing, title }

class _BarLayoutDelegate extends MultiChildLayoutDelegate {
  _BarLayoutDelegate({
    required this.textDirection,
    required this.centerTitle,
    required this.actionsAtStart,
    required this.leadingAtEnd,
    required this.spacing,
    required this.edgePadding,
  });

  final TextDirection textDirection;
  final bool centerTitle;
  final bool actionsAtStart;
  final bool leadingAtEnd;
  final double spacing;
  final double edgePadding;

  @override
  void performLayout(Size size) {
    final loose = BoxConstraints.loose(size);
    var startEdge = edgePadding; // where the start group ends
    var endEdge = edgePadding; // width taken at the end

    void place(_Part part, Size child, double fromStart) {
      final y = (size.height - child.height) / 2;
      final x = textDirection == TextDirection.ltr
          ? fromStart
          : size.width - fromStart - child.width;
      positionChild(part, Offset(x, y));
    }

    if (hasChild(_Part.leading)) {
      final leading = layoutChild(_Part.leading, loose);
      if (leadingAtEnd) {
        place(_Part.leading, leading, size.width - endEdge - leading.width);
        endEdge += leading.width;
      } else {
        place(_Part.leading, leading, startEdge);
        startEdge += leading.width;
      }
    }
    if (hasChild(_Part.trailing)) {
      final trailing = layoutChild(_Part.trailing, loose);
      if (actionsAtStart) {
        place(_Part.trailing, trailing, startEdge);
        startEdge += trailing.width;
      } else {
        place(_Part.trailing, trailing, size.width - endEdge - trailing.width);
        endEdge += trailing.width;
      }
    }
    if (hasChild(_Part.title)) {
      final startLimit = startEdge > edgePadding
          ? startEdge + spacing
          : startEdge;
      final endLimit = endEdge > edgePadding ? endEdge + spacing : endEdge;
      final maxWidth = math.max(0.0, size.width - startLimit - endLimit);
      final title = layoutChild(
        _Part.title,
        BoxConstraints(maxWidth: maxWidth, maxHeight: size.height),
      );
      var x = startLimit;
      if (centerTitle) {
        final centered = (size.width - title.width) / 2;
        x = centered.clamp(startLimit, size.width - endLimit - title.width);
        if (x < startLimit) x = startLimit;
      }
      place(_Part.title, title, x);
    }
  }

  @override
  bool shouldRelayout(_BarLayoutDelegate oldDelegate) =>
      textDirection != oldDelegate.textDirection ||
      centerTitle != oldDelegate.centerTitle ||
      actionsAtStart != oldDelegate.actionsAtStart ||
      leadingAtEnd != oldDelegate.leadingAtEnd ||
      spacing != oldDelegate.spacing ||
      edgePadding != oldDelegate.edgePadding;
}

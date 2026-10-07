// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

/// The frame's children, laid out by [FrameLayout].
enum FrameSlot { body, bar, side }

/// Lays out the bar/side column first, then hands the body tight constraints
/// that also carry how much of it is obstructed (same trick as Scaffold).
class FrameLayout extends MultiChildLayoutDelegate {
  FrameLayout({
    required this.wide,
    required this.sideExtent,
    required this.sideOnRight,
  });

  final bool wide;
  final double sideExtent;
  final bool sideOnRight;

  @override
  void performLayout(Size size) {
    var obstruction = EdgeInsets.zero;
    if (wide && hasChild(FrameSlot.side)) {
      layoutChild(
        FrameSlot.side,
        BoxConstraints.tightFor(width: sideExtent, height: size.height),
      );
      positionChild(
        FrameSlot.side,
        Offset(sideOnRight ? size.width - sideExtent : 0, 0),
      );
      obstruction = sideOnRight
          ? EdgeInsets.only(right: sideExtent)
          : EdgeInsets.only(left: sideExtent);
    } else if (hasChild(FrameSlot.bar)) {
      final barSize = layoutChild(
        FrameSlot.bar,
        BoxConstraints(
          minWidth: size.width,
          maxWidth: size.width,
          maxHeight: size.height,
        ),
      );
      positionChild(FrameSlot.bar, Offset(0, size.height - barSize.height));
      obstruction = EdgeInsets.only(bottom: barSize.height);
    }
    layoutChild(
      FrameSlot.body,
      ObstructionConstraints(
        obstruction: obstruction,
        constraints: BoxConstraints.tight(size),
      ),
    );
    positionChild(FrameSlot.body, Offset.zero);
  }

  @override
  bool shouldRelayout(FrameLayout oldDelegate) =>
      wide != oldDelegate.wide ||
      sideExtent != oldDelegate.sideExtent ||
      sideOnRight != oldDelegate.sideOnRight;
}

class ObstructionConstraints extends BoxConstraints {
  ObstructionConstraints({
    required this.obstruction,
    required BoxConstraints constraints,
  }) : super(
         minWidth: constraints.minWidth,
         maxWidth: constraints.maxWidth,
         minHeight: constraints.minHeight,
         maxHeight: constraints.maxHeight,
       );

  final EdgeInsets obstruction;

  @override
  bool operator ==(Object other) =>
      super == other &&
      other is ObstructionConstraints &&
      other.obstruction == obstruction;

  @override
  int get hashCode => Object.hash(super.hashCode, obstruction);
}

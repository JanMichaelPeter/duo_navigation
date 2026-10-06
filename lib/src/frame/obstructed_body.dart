import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'frame_layout.dart';

/// The body fills the whole frame. The tab bar / side column is published as
/// extra MediaQuery padding, exactly like a notch or home indicator:
/// `SafeArea` content stops beside it, full-bleed content (maps, images,
/// colors) runs underneath.
class ObstructedBody extends StatelessWidget {
  const ObstructedBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final o = constraints is ObstructionConstraints
            ? constraints.obstruction
            : EdgeInsets.zero;
        final mq = MediaQuery.of(context);
        // A bottom bar hidden by the keyboard no longer obstructs anything.
        final paddingObstruction = o.copyWith(
          bottom: math.max(0.0, o.bottom - mq.viewInsets.bottom),
        );
        return MediaQuery(
          data: mq.copyWith(
            padding: _max(mq.padding, paddingObstruction),
            viewPadding: _max(mq.viewPadding, o),
          ),
          child: child,
        );
      },
    );
  }

  static EdgeInsets _max(EdgeInsets a, EdgeInsets b) => EdgeInsets.fromLTRB(
    math.max(a.left, b.left),
    math.max(a.top, b.top),
    math.max(a.right, b.right),
    math.max(a.bottom, b.bottom),
  );
}

// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import '../builders/builders.dart';

class ActionPresence extends StatefulWidget {
  const ActionPresence({
    super.key,
    required this.visible,
    required this.animateIn,
    required this.duration,
    required this.curve,
    required this.transitionBuilder,
    required this.onDismissed,
    required this.child,
  });

  final bool visible;
  final bool animateIn;
  final Duration duration;
  final Curve curve;
  final DockActionTransitionBuilder transitionBuilder;
  final VoidCallback onDismissed;
  final Widget child;

  @override
  State<ActionPresence> createState() => _ActionPresenceState();
}

class _ActionPresenceState extends State<ActionPresence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.animateIn ? 0 : 1,
  );
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
    reverseCurve: widget.curve.flipped,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatus);
    if (widget.visible && widget.animateIn) _controller.forward();
  }

  @override
  void didUpdateWidget(ActionPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.visible != oldWidget.visible) {
      widget.visible ? _controller.forward() : _controller.reverse();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !widget.visible) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: widget.transitionBuilder(context, _animation, widget.child),
    );
  }
}

import 'package:flutter/widgets.dart';

import 'dock_icon.dart';

/// Builds a widget for a [DuoIcon], in a design system's own way.
typedef DuoIconWidgetBuilder =
    Widget Function(BuildContext context, DuoIcon icon);

/// Shows [icon] with [builder] and cross-fades when it changes, such as back
/// turning into close or a star into a filled star.
///
/// Icons are told apart by [DuoIcon.identity], so rebuilding the same icon
/// doesn't restart the animation; give custom widget icons an identity
/// (`DuoIcon.widget(w, identity: ...)`). With reduced motion
/// (`MediaQuery.disableAnimations`) it swaps without animating.
///
/// Action builders use it with their own icon rendering:
///
/// ```dart
/// action: (context, action, placement) => MyIconButton(
///   icon: DuoIconMorph(icon: action.icon!, builder: (context, icon) => MyIcon.of(icon)),
///   onPressed: action.onPressed,
/// ),
/// ```
///
/// `DuoMaterial.morphingIcon` is this with Material icons.
class DuoIconMorph extends StatelessWidget {
  /// Shows [icon] with [builder], cross-fading when it changes.
  const DuoIconMorph({
    super.key,
    required this.icon,
    required this.builder,
    this.duration = const Duration(milliseconds: 200),
  });

  /// The icon to show.
  final DuoIcon icon;

  /// Builds the widget for an icon.
  final DuoIconWidgetBuilder builder;

  /// How long the cross-fade takes.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : duration,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: KeyedSubtree(
        key: ValueKey<Object>(icon.identity),
        child: Builder(builder: (context) => builder(context, icon)),
      ),
    );
  }
}

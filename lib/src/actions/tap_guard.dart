import 'package:flutter/foundation.dart';

import 'clock.dart';

/// Guards action taps against double taps and taps during route transitions.
///
/// While [enabled], an action fires only if its page is the one shown, its
/// route is not in a transition or a back gesture, and [cooldown] has passed
/// since the last guarded tap in the same frame (shell or modal).
@immutable
class DockTapGuard {
  /// The default guard: on, 350 ms cooldown, a stopwatch clock.
  const DockTapGuard({
    this.enabled = true,
    this.cooldown = const Duration(milliseconds: 350),
    this.clock,
  });

  /// A guard that lets every tap through. For tests that don't care about
  /// double-tap protection.
  static const DockTapGuard disabled = DockTapGuard(enabled: false);

  /// Whether taps are guarded at all. Off: every tap fires.
  final bool enabled;

  /// Minimum time between two guarded taps.
  final Duration cooldown;

  /// The time source. Null: a monotonic stopwatch. Tests use
  /// [DockClock.frameTime] (the default in `DockTestHarness`) or a fake.
  final DockClock? clock;

  @override
  bool operator ==(Object other) =>
      other is DockTapGuard &&
      other.enabled == enabled &&
      other.cooldown == cooldown &&
      other.clock == clock;

  @override
  int get hashCode => Object.hash(enabled, cooldown, clock);
}

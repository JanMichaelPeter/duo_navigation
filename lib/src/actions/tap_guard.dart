import 'package:flutter/foundation.dart';

import '../models/action.dart';
import 'clock.dart';

/// Why the tap guard dropped a tap.
enum DuoTapRejection {
  /// The action's page is not the one shown (another tab, a page above it,
  /// a dialog over it).
  notActive,

  /// A route transition or a back gesture is running.
  transition,

  /// The same action fired less than its cooldown ago.
  cooldown,
}

/// Called when the tap guard drops a tap; see [DuoTapGuard.onRejected].
typedef DuoTapRejected =
    void Function(DuoAction<Object?> action, DuoTapRejection reason);

/// Guards action taps against double taps and taps during route transitions.
///
/// While [enabled], a guarded action fires only if its page is the one
/// shown, its route is not in a transition or a back gesture, and the same
/// action has not fired within its cooldown ([DuoAction.cooldown], else
/// [cooldown]). Different actions don't block each other.
@immutable
class DuoTapGuard {
  /// The default guard: on, 350 ms cooldown, [DuoClock.system].
  const DuoTapGuard({
    this.enabled = true,
    this.cooldown = const Duration(milliseconds: 350),
    this.clock,
    this.onRejected,
  });

  /// A guard that lets every tap through. For tests that don't care about
  /// double-tap protection.
  static const DuoTapGuard disabled = DuoTapGuard(enabled: false);

  /// Whether taps are guarded at all. Off: every tap fires.
  final bool enabled;

  /// Minimum time between two taps on the same action, unless the action sets
  /// its own.
  final Duration cooldown;

  /// The time source. Null: [DuoClock.system], real time on a device and
  /// test time in widget tests. `DuoTestHarness` uses
  /// [DuoClock.frameTime]; tests that control time directly use a fake.
  final DuoClock? clock;

  /// Called with each dropped tap and the reason, for example to give
  /// feedback. Rejections are also logged in debug mode.
  final DuoTapRejected? onRejected;

  @override
  bool operator ==(Object other) =>
      other is DuoTapGuard &&
      other.enabled == enabled &&
      other.cooldown == cooldown &&
      other.clock == clock &&
      other.onRejected == onRejected;

  @override
  int get hashCode => Object.hash(enabled, cooldown, clock, onRejected);
}

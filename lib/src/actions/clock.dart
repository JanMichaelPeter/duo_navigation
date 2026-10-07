import 'package:flutter/scheduler.dart';

/// The time source of the tap guard.
///
/// Only differences between two readings matter, so any monotonic time base
/// works.
abstract interface class DockClock {
  /// A monotonic stopwatch that starts when it is created. The default.
  factory DockClock.stopwatch() = _StopwatchClock;

  /// The timestamp of the last frame
  /// ([SchedulerBinding.currentSystemFrameTimeStamp]). In widget tests,
  /// `tester.pump(duration)` advances it, so a test never waits on real time.
  /// `DockTestHarness` uses this clock.
  static const DockClock frameTime = _FrameTimeClock();

  /// The current time.
  Duration now();
}

class _StopwatchClock implements DockClock {
  _StopwatchClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration now() => _stopwatch.elapsed;
}

class _FrameTimeClock implements DockClock {
  const _FrameTimeClock();

  @override
  Duration now() => SchedulerBinding.instance.currentSystemFrameTimeStamp;
}

import 'package:flutter/scheduler.dart';

/// The time source of the tap guard.
///
/// Only differences between two readings matter, so any monotonic time base
/// works.
abstract interface class DuoClock {
  /// Real time, or frame time where that moved further: each reading
  /// advances by the larger of the two since the last reading. The default.
  ///
  /// On a device both run together, so this is real time. In widget tests
  /// real time barely passes while `tester.pump(duration)` and
  /// `tester.pumpAndSettle()` advance the frame time, so the tap guard's
  /// cooldown passes as it does in the test, also without
  /// `DuoTestHarness`.
  factory DuoClock.system() = _SystemClock;

  /// A monotonic stopwatch that starts when it is created: real time only.
  factory DuoClock.stopwatch() = _StopwatchClock;

  /// The timestamp of the last frame
  /// ([SchedulerBinding.currentSystemFrameTimeStamp]). In widget tests,
  /// `tester.pump(duration)` advances it, so a test never waits on real time.
  /// `DuoTestHarness` uses this clock.
  static const DuoClock frameTime = _FrameTimeClock();

  /// The current time.
  Duration now();
}

class _SystemClock implements DuoClock {
  _SystemClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;
  Duration? _lastReal;
  Duration _lastFrame = Duration.zero;
  Duration _now = Duration.zero;

  @override
  Duration now() {
    final real = _stopwatch.elapsed;
    final frame = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final lastReal = _lastReal;
    if (lastReal != null) {
      final byReal = real - lastReal;
      final byFrame = frame - _lastFrame;
      _now += byFrame > byReal ? byFrame : byReal;
    }
    _lastReal = real;
    _lastFrame = frame;
    return _now;
  }
}

class _StopwatchClock implements DuoClock {
  _StopwatchClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration now() => _stopwatch.elapsed;
}

class _FrameTimeClock implements DuoClock {
  const _FrameTimeClock();

  @override
  Duration now() => SchedulerBinding.instance.currentSystemFrameTimeStamp;
}

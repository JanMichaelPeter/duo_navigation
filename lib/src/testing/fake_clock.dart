import '../actions/clock.dart';

/// A [DuoClock] that only moves when a test [advance]s it.
///
/// Most tests don't need it: `DuoTestHarness` uses [DuoClock.frameTime],
/// which `tester.pump(duration)` advances. Use this one to control the tap
/// guard's time independently of frames.
class FakeDuoClock implements DuoClock {
  /// Starts at [elapsed].
  FakeDuoClock([this.elapsed = Duration.zero]);

  /// The current time.
  Duration elapsed;

  /// Moves the clock forward by [duration].
  void advance(Duration duration) => elapsed += duration;

  @override
  Duration now() => elapsed;
}

import '../actions/clock.dart';

/// A [DockClock] that only moves when a test [advance]s it.
///
/// Most tests don't need it: `DockTestHarness` uses [DockClock.frameTime],
/// which `tester.pump(duration)` advances. Use this one to control the tap
/// guard's time independently of frames.
class FakeDockClock implements DockClock {
  /// Starts at [elapsed].
  FakeDockClock([this.elapsed = Duration.zero]);

  /// The current time.
  Duration elapsed;

  /// Moves the clock forward by [duration].
  void advance(Duration duration) => elapsed += duration;

  @override
  Duration now() => elapsed;
}

// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../models/action.dart';
import 'clock.dart';
import 'tap_guard.dart';

/// Collects the actions of every page below one frame (shell or modal) and
/// decides whose actions the side column shows.
///
/// Each page registers. A page is "active" while its route is current and its
/// subtree is ticking (inactive tabs are wrapped in `TickerMode(false)`). The
/// most recently activated page wins, which handles push, pop, tab switches
/// and nested navigators without knowing about any router.
class DockActionHost extends ChangeNotifier {
  /// Creates an empty host. Frames create their own; you rarely need one.
  DockActionHost();

  /// How taps are guarded. The frame sets it from the configuration.
  DockTapGuard tapGuard = const DockTapGuard();

  final List<DockActionRegistration> _registrations = [];
  final DockClock _stopwatch = DockClock.stopwatch();
  Duration? _lastInvoke;
  int _serial = 0;
  bool _notifyScheduled = false;
  bool _disposed = false;

  /// Adds a page slot. Call [DockActionRegistration.dispose] when the
  /// page goes away.
  DockActionRegistration register() {
    final r = DockActionRegistration._(this);
    _registrations.add(r);
    return r;
  }

  /// The registration whose actions are on screen.
  DockActionRegistration? get active {
    DockActionRegistration? best;
    for (final r in _registrations) {
      if (r._active && (best == null || r._serial > best._serial)) best = r;
    }
    return best;
  }

  // Registrations update during build; listeners are notified after the frame.
  void _markDirty() {
    if (_notifyScheduled || _disposed) return;
    _notifyScheduled = true;
    final binding = SchedulerBinding.instance;
    binding.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
    binding.ensureVisualUpdate();
  }

  bool _tryInvoke(DockActionRegistration r) {
    if (!tapGuard.enabled) return true;
    if (r._disposed || !identical(active, r)) return false;
    if (!_isSettled(r._route)) return false;
    final now = (tapGuard.clock ?? _stopwatch).now();
    final last = _lastInvoke;
    if (last != null && now - last < tapGuard.cooldown) return false;
    _lastInvoke = now;
    return true;
  }

  static bool _isSettled(Route<dynamic>? route) {
    if (route == null) return true;
    if (!route.isCurrent) return false;
    if (route.navigator?.userGestureInProgress ?? false) return false;
    if (route is TransitionRoute) {
      if (_moving(route.animation) || _moving(route.secondaryAnimation)) {
        return false;
      }
    }
    return true;
  }

  static bool _moving(Animation<double>? a) =>
      a != null &&
      (a.status == AnimationStatus.forward ||
          a.status == AnimationStatus.reverse);

  @override
  /// Removes this page from the host.
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// One page's slot in an [DockActionHost]. [DockPage] manages this
/// for you; use it directly only for fully custom pages.
class DockActionRegistration {
  DockActionRegistration._(this.host);

  /// The host this registration belongs to.
  final DockActionHost host;
  List<DockAction> _actions = const [];
  Route<dynamic>? _route;
  bool _active = false;
  int _serial = 0;
  bool _disposed = false;

  /// Actions this page wants in the side column (icon actions, top to bottom).
  List<DockAction> get actions => _actions;

  /// Whether the page is currently shown (route current and ticking).
  bool get isActive => _active;

  /// Reports the page's current column [actions], whether it is [active]
  /// (visible and current), and its [route] for the transition check.
  void update({
    required List<DockAction> actions,
    required bool active,
    Route<dynamic>? route,
  }) {
    if (_disposed) return;
    final wasActive = _active;
    _actions = actions;
    _route = route;
    _active = active;
    if (active && !wasActive) _serial = ++host._serial;
    if (active || wasActive) host._markDirty();
  }

  /// Wraps [callback] so it only fires when this page is the active one, its
  /// route is not mid-transition, and the cooldown has passed. This is what
  /// prevents "tap back 3x, pop 3 pages".
  VoidCallback? guard(VoidCallback? callback) {
    if (callback == null) return null;
    return () {
      if (host._tryInvoke(this)) callback();
    };
  }

  /// [action] with its `onPressed` wrapped by [guard].
  DockAction guarded(DockAction action) =>
      action.copyWith(onPressed: guard(action.onPressed));

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    host._registrations.remove(this);
    if (_active) host._markDirty();
  }
}

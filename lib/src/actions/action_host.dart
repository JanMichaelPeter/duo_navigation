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
class DuoActionHost extends ChangeNotifier {
  /// Creates an empty host. Frames create their own; you rarely need one.
  DuoActionHost();

  /// How taps are guarded. The frame sets it from the configuration.
  DuoTapGuard tapGuard = const DuoTapGuard();

  final List<DuoActionRegistration> _registrations = [];
  final DuoClock _clock = DuoClock.system();
  final Map<Object, Duration> _lastInvoke = {};
  int _serial = 0;
  bool _notifyScheduled = false;
  bool _disposed = false;

  /// Adds a page slot. Call [DuoActionRegistration.dispose] when the
  /// page goes away.
  DuoActionRegistration register() {
    final r = DuoActionRegistration._(this);
    _registrations.add(r);
    return r;
  }

  /// The registration whose actions are on screen.
  DuoActionRegistration? get active {
    DuoActionRegistration? best;
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

  bool _tryInvoke(DuoActionRegistration r, DuoAction<Object?> action) {
    final reason = _rejection(r, action);
    if (reason == null) return true;
    assert(() {
      debugPrint(
        'duo_navigation: tap on action ${action.id} dropped (${reason.name})',
      );
      return true;
    }());
    tapGuard.onRejected?.call(action, reason);
    return false;
  }

  DuoTapRejection? _rejection(
    DuoActionRegistration r,
    DuoAction<Object?> action,
  ) {
    final route = r._route;
    if (r._disposed || !identical(active, r) || !(route?.isCurrent ?? true)) {
      return DuoTapRejection.notActive;
    }
    if (!_isSettled(route)) return DuoTapRejection.transition;
    final now = (tapGuard.clock ?? _clock).now();
    // Same identity as in the column: shared actions across pages, all
    // others per page.
    final Object key = action.shared ? action.id : (r, action.id);
    final last = _lastInvoke[key];
    if (last != null && now - last < (action.cooldown ?? tapGuard.cooldown)) {
      return DuoTapRejection.cooldown;
    }
    _lastInvoke[key] = now;
    return null;
  }

  static bool _isSettled(Route<dynamic>? route) {
    if (route == null) return true;
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

/// One page's slot in an [DuoActionHost]. [DuoPage] manages this
/// for you; use it directly only for fully custom pages.
class DuoActionRegistration {
  DuoActionRegistration._(this.host);

  /// The host this registration belongs to.
  final DuoActionHost host;
  List<DuoAction<Object?>> _actions = const [];
  Route<dynamic>? _route;
  bool _active = false;
  bool _navigationVisible = true;
  Widget? _backdrop;
  int _serial = 0;
  bool _disposed = false;

  /// Whether this page wants the navigation shown (`DuoPageScope.visible`).
  bool get navigationVisible => _navigationVisible;

  /// The page's backdrop (`DuoPageScope.backdrop`), or null.
  Widget? get backdrop => _backdrop;

  /// Actions this page wants in the side column (icon actions, top to bottom).
  List<DuoAction<Object?>> get actions => _actions;

  /// Whether the page is currently shown (route current and ticking).
  bool get isActive => _active;

  /// Reports the page's current column [actions], whether it is [active]
  /// (visible and current), and its [route] for the transition check.
  void update({
    required List<DuoAction<Object?>> actions,
    required bool active,
    Route<dynamic>? route,
    bool navigationVisible = true,
    Widget? backdrop,
  }) {
    if (_disposed) return;
    final wasActive = _active;
    final visibilityChanged = navigationVisible != _navigationVisible;
    // A page with a backdrop reports each rebuild, so the frame shows the
    // new configuration; pages without one never notify for it.
    final backdropChanged =
        !identical(backdrop, _backdrop) &&
        (backdrop != null || _backdrop != null);
    _navigationVisible = navigationVisible;
    _backdrop = backdrop;
    _actions = actions;
    _route = route;
    _active = active;
    if (active && !wasActive) _serial = ++host._serial;
    if (active || wasActive || visibilityChanged || backdropChanged) {
      host._markDirty();
    }
  }

  /// [action] as builders get it: `onPressed` is null while the action is
  /// disabled, and goes through the tap guard unless the guard or the action
  /// opts out. The guard is what prevents "tap back 3x, pop 3 pages".
  DuoAction<A> guarded<A>(DuoAction<A> action) {
    final callback = action.effectiveOnPressed;
    if (callback == null) return action.copyWith(onPressed: null);
    if (!action.guarded || !host.tapGuard.enabled) return action;
    return action.copyWith(
      onPressed: () {
        if (host._tryInvoke(this, action)) callback();
      },
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    host._registrations.remove(this);
    host._lastInvoke.removeWhere(
      (key, _) => key is (DuoActionRegistration, Object) && key.$1 == this,
    );
    if (_active) host._markDirty();
  }
}

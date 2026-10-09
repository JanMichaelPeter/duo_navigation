import 'package:flutter/widgets.dart';

import '../config/keyboard.dart';

import '../builders/builders.dart';
import '../geometry/body_mode.dart';
import '../models/action.dart';
import 'frame.dart';

/// Frame for modally presented content: wide mode gets a side column with the
/// actions (no rail), compact mode gets nothing extra.
///
/// [DuoPage] adds one automatically when it finds no scope above it (a
/// page pushed on the root navigator). Wrap a modal's own nested Navigator in
/// this explicitly so all its steps share one column, and the back button
/// stays in place between steps.
class DuoModalScope<A, B> extends StatelessWidget {
  /// Frames [child] as one modal with a shared side column.
  const DuoModalScope({
    super.key,
    this.bodyMode,
    this.hoisting,
    this.keyboard,
    this.builders,
    this.navigationVisible = true,
    this.backdrop,
    this.impliedLeading,
    this.leadingAtEnd,
    required this.child,
  });

  /// Whether the body is laid out beside the column or under it. Null:
  /// `DuoNavigationData.bodyMode`.
  final DuoBodyMode? bodyMode;

  /// Whether icon actions of its pages move into the column in wide mode.
  /// Null: `DuoNavigationData.hoisting`.
  final DuoHoisting? hoisting;

  /// How the bar, the column and the body handle the software keyboard in
  /// this frame, for example `DuoKeyboard(body: DuoBodyKeyboardBehavior.lift)`
  /// for screens whose bodies don't handle it. Null:
  /// `DuoNavigationData.keyboard`.
  final DuoKeyboard? keyboard;

  /// Builders for this modal frame only, on top of the app's; null fields
  /// fall back to them.
  final DuoBuilders<Object?, A, B>? builders;

  /// Whether the side column shows. False hides it with an animation. A page
  /// can hide it too (`DuoPageScope.visible`).
  final bool navigationVisible;

  /// Painted across the whole frame, under the body and the column. A page's
  /// own `DuoPageScope.backdrop` replaces it while that page is shown.
  final Widget? backdrop;

  /// The leading action of the modal's first page (the page on the route this
  /// scope is on, or the first page of a Navigator inside it) when that page
  /// declares none. It dismisses the modal. Null:
  /// `DuoNavigationData.modalLeading`, whose default is
  /// [DuoImpliedLeading.close] if the route is a full-screen dialog, else
  /// [DuoImpliedLeading.back]. Pages pushed inside the modal keep back.
  final DuoImpliedLeading? impliedLeading;

  /// Whether the leading action of the modal's first page sits at the end of
  /// the title bar. Null: `DuoNavigationData.modalLeading`.
  final bool? leadingAtEnd;

  /// The modal content, typically its own Navigator.
  final Widget child;

  @override
  Widget build(BuildContext context) => DuoFrame<Object?, A, B>(
    isModal: true,
    bodyMode: bodyMode,
    hoisting: hoisting,
    keyboard: keyboard,
    builders: builders,
    navigationVisible: navigationVisible,
    backdrop: backdrop,
    impliedLeading: impliedLeading,
    leadingAtEnd: leadingAtEnd,
    child: child,
  );
}

/// Test support for apps that use duo_navigation: a harness that pins the layout,
/// fakes for window edges and time, and keys to find the chrome.
///
/// This library does not depend on `flutter_test`, so importing it adds no
/// dependency. Find widgets with `find.byKey(DockKeys.action('share'))`.
library;

export 'src/keys.dart';
export 'src/testing/fake_clock.dart';
export 'src/testing/fake_window_edges_source.dart';
export 'src/testing/harness.dart';

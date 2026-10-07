import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files that may import Material or Cupertino: the Material entry point and
/// its implementation.
bool _mayUseDesignLibraries(String path) =>
    path == 'lib/material.dart' || path.startsWith('lib/src/material/');

/// 0.0.1 files that the 0.1.0 redesign replaces (#42). Remove each entry when
/// its file goes; the test fails once an entry no longer exists.
const _oldFiles = {
  'lib/src/defaults.dart',
  'lib/src/models/action.dart',
  'lib/src/page.dart',
};

final _designImport = RegExp(
  r'''^\s*(?:import|export)\s+['"]package:flutter/(?:material|cupertino)\.dart['"]''',
  multiLine: true,
);

void main() {
  test('core files import neither Material nor Cupertino', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll(r'\', '/');
      if (_mayUseDesignLibraries(path) || _oldFiles.contains(path)) continue;
      if (_designImport.hasMatch(file.readAsStringSync())) offenders.add(path);
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Core code depends on package:flutter/widgets.dart only. Move '
          'Material code to lib/src/material/ (exported by material.dart).',
    );
  });

  test('0.0.1 exceptions still exist', () {
    final gone = _oldFiles.where((path) => !File(path).existsSync());
    expect(
      gone,
      isEmpty,
      reason: 'Remove deleted files from _oldFiles in boundaries_test.dart.',
    );
  });
}

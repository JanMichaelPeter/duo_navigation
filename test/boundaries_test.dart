import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files that may import Material or Cupertino: the Material entry point and
/// its implementation.
bool _mayUseDesignLibraries(String path) =>
    path == 'lib/material.dart' || path.startsWith('lib/src/material/');

/// Directories that `geometry.dart` may export from: read-only layout types,
/// no page, action or builder types.
const _geometryDirs = ['src/geometry/', 'src/bleed/'];

final _directive = RegExp(
  r'''^\s*(import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

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
      if (_mayUseDesignLibraries(path)) continue;
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

  test('geometry.dart exports only read-only layout types', () {
    final exports = [
      for (final m in _directive.allMatches(
        File('lib/geometry.dart').readAsStringSync(),
      ))
        if (m[1] == 'export') m[2]!,
    ];
    expect(exports, isNotEmpty);
    expect(
      exports.where((uri) => !_geometryDirs.any(uri.startsWith)),
      isEmpty,
      reason: 'geometry.dart exports from ${_geometryDirs.join(' and ')} only.',
    );
  });

  test('geometry files depend on nothing outside geometry', () {
    for (final file in Directory('lib/src/geometry').listSync()) {
      if (file is! File) continue;
      for (final m in _directive.allMatches(file.readAsStringSync())) {
        final uri = m[2]!;
        final allowed =
            uri.startsWith('dart:') ||
            uri.startsWith('package:flutter/') ||
            !uri.contains('/');
        expect(allowed, isTrue, reason: '${file.path} imports $uri');
      }
    }
  });

  test('no library file depends on flutter_test', () {
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      expect(
        file.readAsStringSync(),
        isNot(contains('package:flutter_test/')),
        reason: '${file.path}: testing.dart must not add a test dependency.',
      );
    }
  });
}

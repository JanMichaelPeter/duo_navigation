import 'package:flutter/material.dart';

/// Presents [page] on the root navigator, above the tab shell.
Future<T?> presentModally<T>(BuildContext context, Widget page) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => page),
  );
}

void showToast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

import 'package:flutter/material.dart';
import 'package:duo_navigation/duo_navigation.dart';

/// An immersive page: while it is shown the tab bar or side column hides
/// (`visible: false`), and comes back when it is popped. Its close button
/// sits at the top right (`leadingAtEnd`) and stays in the title bar in wide
/// mode too (`DuoHoisting.none`), since the column is hidden.
class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DuoPage(
      visible: false,
      hoisting: DuoHoisting.none,
      leadingAtEnd: true,
      leading: DuoAction.close(
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: const ColoredBox(
        color: Colors.black,
        child: Center(
          child:
              Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 96),
        ),
      ),
    );
  }
}

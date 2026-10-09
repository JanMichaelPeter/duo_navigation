import 'package:duo_navigation/duo_navigation.dart';
import 'package:flutter/material.dart';

import '../navigation.dart';

/// Fully custom page (DockPage.custom). The "map" bleeds under the tab bar
/// and the side column (DockBleed); the floating title bar stays beside them
/// and lays itself out with DockBarLayout, so its actions follow the column
/// to the start edge.
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DockPage.custom(
      title: const Text('Map'),
      trailing: [
        DockAction(
          id: 'locate',
          icon: const DockIcon(Icons.my_location),
          tooltip: 'Locate me',
          onPressed: () => showToast(context, 'Locating…'),
        ),
      ],
      builder: (context, bar) => Material(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DockBleed(child: _FakeMap()),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    elevation: 2,
                    shape: const StadiumBorder(),
                    child: SizedBox(
                      width: 320,
                      height: 48,
                      child: DefaultTextStyle.merge(
                        style: Theme.of(context).textTheme.titleMedium,
                        child: DockBarLayout(
                          title: bar.title,
                          trailing: [
                            for (final a in bar.trailing)
                              bar.buildAction(
                                  a, DockActionPlacement.barTrailing),
                          ],
                          centerTitle: true,
                          actionsAtStart: bar.trailingAtStart,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FakeMap extends StatelessWidget {
  const _FakeMap();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(Theme.of(context).colorScheme),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.scheme);

  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ).createShader(rect),
    );
    final line = Paint()
      ..color = scheme.onPrimaryContainer.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.scheme != scheme;
}

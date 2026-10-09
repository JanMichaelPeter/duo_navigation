import 'package:duo_navigation/duo_navigation.dart';
import 'package:flutter/material.dart';

import '../navigation.dart';

/// Push several levels deep: the back chip stays put, per-page actions
/// animate out/in, "Back to top" collapses the stack in one smooth step.
class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key, required this.depth});

  final int depth;

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    final depth = widget.depth;
    return DuoPage(
      title: Text(depth == 0 ? 'Items' : 'Level $depth'),
      trailing: [
        if (depth == 0)
          DuoAction(
            id: 'add',
            icon: const DuoIcon(Icons.add),
            tooltip: 'Add',
            role: DuoActionRole.primary, // highlighted by the custom style
            onPressed: () => showToast(context, 'Add'),
          ),
        if (depth > 0)
          DuoAction(
            id: 'share',
            icon: const DuoIcon(Icons.ios_share),
            tooltip: 'Share',
            onPressed: () => showToast(context, 'Share level $depth'),
          ),
        if (depth.isOdd)
          DuoAction(
            id: 'favorite',
            icon: DuoIcon(_favorite ? Icons.star : Icons.star_border),
            tooltip: 'Favorite',
            onPressed: () => setState(() => _favorite = !_favorite),
          ),
      ],
      // The body sits beside the tab bar and the column: no SafeArea needed.
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.subdirectory_arrow_right),
            title: const Text('Go deeper'),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ItemsPage(depth: depth + 1))),
          ),
          if (depth > 0)
            ListTile(
              leading: const Icon(Icons.vertical_align_top),
              title: const Text('Back to top'),
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          for (var n = 1; n <= 30; n++)
            ListTile(title: Text('Row $n'), subtitle: Text('Level $depth')),
        ],
      ),
    );
  }
}

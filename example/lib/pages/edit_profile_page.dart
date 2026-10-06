import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';

/// Root-level modal. DockPage notices there's no shell above it and adds
/// its own frame: close chip in a side column, no rail.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DockPage(
      title: const Text('Edit profile'),
      trailing: [
        DockAction(
          id: 'save',
          label: 'Save',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            TextField(decoration: InputDecoration(labelText: 'Name')),
            SizedBox(height: 16),
            TextField(decoration: InputDecoration(labelText: 'Bio')),
          ],
        ),
      ),
    );
  }
}

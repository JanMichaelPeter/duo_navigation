import 'package:flutter/material.dart';
import 'package:duo_navigation/duo_navigation.dart';

/// Root-level modal. DockPage notices there's no shell above it and adds its
/// own frame. A text-only leading action ("Cancel") stays in the title bar in
/// every mode; with the keyboard open, the side column lifts above it.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DockPage(
      title: const Text('Edit profile'),
      leading: DockAction.back(
        icon: null,
        label: 'Cancel',
        onPressed: () => Navigator.of(context).pop(),
      ),
      trailing: [
        DockAction(
          id: 'save',
          icon: const DockIcon(Icons.check),
          tooltip: 'Save',
          role: DockActionRole.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          TextField(decoration: InputDecoration(labelText: 'Name')),
          SizedBox(height: 16),
          TextField(decoration: InputDecoration(labelText: 'Bio')),
        ],
      ),
    );
  }
}

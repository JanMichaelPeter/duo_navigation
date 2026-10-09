import 'package:flutter/material.dart';
import 'package:duo_navigation/material.dart';

import '../navigation.dart';
import 'camera_page.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'setup_flow.dart';

/// A page with its own Scaffold: DockPageScope declares the bar and the
/// actions, DockAppBar draws them. The gradient is the page's backdrop: it
/// runs under the tab bar and the side column, behind a transparent page.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DockPageScope(
      title: const Text('Profile'),
      trailing: [
        // Label-only: stays in the title bar even in wide mode.
        DockAction(
          id: 'edit',
          label: 'Edit',
          onPressed: () => presentModally(context, const EditProfilePage()),
        ),
      ],
      backdrop: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.secondaryContainer, scheme.surface],
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const DockAppBar(backgroundColor: Colors.transparent),
        body: ListView(
          children: [
            const ListTile(
              leading: CircleAvatar(child: Text('A')),
              title: Text('Alex Example'),
              subtitle: Text('Single modal: Edit (in the title bar)'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              subtitle: const Text('A plain Scaffold page with its own AppBar'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const SettingsPage())),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              subtitle: const Text('Immersive: the navigation hides'),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CameraPage())),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Run setup flow'),
              subtitle:
                  const Text('Modal with its own navigator: close → back'),
              onTap: () => presentModally(context, const SetupFlow()),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';

import '../navigation.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'setup_flow.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DockPage(
      title: const Text('Profile'),
      trailing: [
        // Label-only: stays in the title bar even in wide mode.
        DockAction(
          id: 'edit',
          label: 'Edit',
          onPressed: () => presentModally(context, const EditProfilePage()),
        ),
      ],
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          children: [
            const ListTile(
              leading: CircleAvatar(child: Text('A')),
              title: Text('Alex Example'),
              subtitle: Text('Single modal: Edit (top right)'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              subtitle: const Text('Subpage: tab bar / rail stay visible'),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage())),
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

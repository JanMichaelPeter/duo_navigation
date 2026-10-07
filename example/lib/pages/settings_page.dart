import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';

import '../navigation.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return DockPage(
      title: const Text('Settings'),
      trailing: [
        DockAction(
          id: 'help',
          icon: const DockIcon(Icons.help_outline),
          tooltip: 'Help',
          onPressed: () => showToast(context, 'Help'),
        ),
      ],
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Notifications'),
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
          ],
        ),
      ),
    );
  }
}

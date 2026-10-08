import 'package:flutter/material.dart';
import 'package:nav_dock/geometry.dart';

/// No page layer at all: a plain Scaffold with its own AppBar and back
/// button. The frame lays it out beside the chrome, and the column holds only
/// the rail. It reads the frame's layout from `geometry.dart`.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final geometry = DockGeometry.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          ListTile(
            title: const Text('Layout'),
            subtitle: Text(
              '${geometry.mode.name}, column on the ${geometry.side.name} '
              'edge, body mode ${geometry.bodyMode.name}',
            ),
          ),
        ],
      ),
    );
  }
}

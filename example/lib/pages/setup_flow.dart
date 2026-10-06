import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';

/// Multi-step modal: one DockModalScope around its own Navigator, so all
/// steps share one side column. Step 1's close chip morphs into a back chip.
class SetupFlow extends StatelessWidget {
  const SetupFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return DockModalScope(
      child: Navigator(
        onGenerateRoute: (_) =>
            MaterialPageRoute(builder: (_) => const SetupStep(step: 1)),
      ),
    );
  }
}

class SetupStep extends StatelessWidget {
  const SetupStep({super.key, required this.step});

  final int step;

  void _closeFlow(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).pop();

  @override
  Widget build(BuildContext context) {
    return DockPage(
      title: Text('Step $step of 3'),
      // Back-id with a close icon: same chip as the later back buttons.
      leading: step == 1
          ? DockAction.back(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () => _closeFlow(context),
            )
          : null,
      trailing: [
        if (step < 3)
          DockAction(
            id: 'next',
            label: 'Next',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SetupStep(step: step + 1))),
          )
        else
          DockAction(
              id: 'done', label: 'Done', onPressed: () => _closeFlow(context)),
      ],
      body: Center(
        child: Text('Setup step $step',
            style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

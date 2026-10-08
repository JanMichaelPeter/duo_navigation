import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';

/// Multi-step modal: one DockModalScope around its own Navigator, so all
/// steps share one side column. Step 1's implied close chip morphs into a
/// back chip.
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
      // No leading: step 1, the modal's first page, gets a close action that
      // dismisses the flow (the route is a full-screen dialog), the later
      // steps get back. Close and back share one identity, so the chip morphs.
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/congratulations/congratulations_test_ids.dart';

/// End of sign-up (native `CongratulationsFragment`). Leaving clears the flow
/// so the router stops treating the user as mid-sign-up.
class CongratulationsScreen extends ConsumerWidget {
  const CongratulationsScreen({super.key});

  void _finish(BuildContext context, WidgetRef ref) {
    ref.read(signUpFlowProvider.notifier).reset();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(userProfileProvider).value?.firstName;
    return StepScaffold(
      rootId: CongratulationsTestIds.root,
      titleId: CongratulationsTestIds.title,
      title: l10n.congratulationsTitle,
      showBack: false,
      children: [
        if (name != null && name.isNotEmpty)
          TestId(
            CongratulationsTestIds.greeting,
            child: Text(l10n.congratulationsGreeting(name)),
          ),
        const SizedBox(height: 24),
        TestId(
          CongratulationsTestIds.goHome,
          child: FilledButton(
            onPressed: () => _finish(context, ref),
            child: Text(l10n.goToHomeAction),
          ),
        ),
        const SizedBox(height: 12),
        // Native opens the create-event wizard; until that milestone exists
        // this also lands on home.
        TestId(
          CongratulationsTestIds.addEvent,
          child: OutlinedButton(
            onPressed: () => _finish(context, ref),
            child: Text(l10n.addFirstEventAction),
          ),
        ),
      ],
    );
  }
}

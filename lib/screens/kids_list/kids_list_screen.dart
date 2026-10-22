import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/failure_message.dart';
import 'package:racketmates/common/sign_up/create_account_controller.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/kids_list/kids_list_test_ids.dart';

/// Kids added by a parent (max 2); Next creates the account.
class KidsListScreen extends ConsumerWidget {
  const KidsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(signUpFlowProvider);
    final kids = draft?.kids ?? const <KidDraft>[];
    final create = ref.watch(createAccountControllerProvider);
    final canAdd = kids.length < SignUpDraft.maxKids;
    return StepScaffold(
      rootId: KidsListTestIds.root,
      titleId: KidsListTestIds.title,
      title: l10n.kidsTitle,
      primaryLabel: l10n.nextAction,
      primaryId: KidsListTestIds.next,
      loading: create.loading,
      onPrimary: kids.isEmpty
          ? null
          : () async {
              final ok = await ref
                  .read(createAccountControllerProvider.notifier)
                  .submit();
              if (ok && context.mounted) context.go(AppRoutes.profilePicture);
            },
      onBack: () => context.pop(),
      children: [
        for (var i = 0; i < kids.length; i++)
          TestId(
            KidsListTestIds.kid(i),
            child: Card(
              child: ListTile(
                title: Text('${kids[i].firstName} ${kids[i].lastName}'.trim()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TestId(
                      KidsListTestIds.edit(i),
                      child: IconButton(
                        tooltip: l10n.editAction,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.push(
                          AppRoutes.kidFormFor(index: i, fromList: true),
                        ),
                      ),
                    ),
                    TestId(
                      KidsListTestIds.remove(i),
                      child: IconButton(
                        tooltip: l10n.removeAction,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          ref.read(signUpFlowProvider.notifier).removeKid(i);
                          if (ref.read(signUpFlowProvider)!.kids.isEmpty &&
                              !ref.read(signUpFlowProvider)!.hasParent) {
                            context.pop();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        TestId(
          KidsListTestIds.add,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            onPressed: canAdd
                ? () => context.push(AppRoutes.kidFormFor(fromList: true))
                : null,
            label: Text(canAdd ? l10n.addKidAction : l10n.kidsMaxReached),
          ),
        ),
        if (create.failure != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TestId(
              KidsListTestIds.error,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  failureMessage(l10n, create.failure!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

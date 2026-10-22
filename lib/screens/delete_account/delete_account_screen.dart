import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/links/external_links.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/common/settings/logout.dart';
import 'package:racketmates/common/support/support_repository.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';

/// Ask for the account to be deleted (native `DeleteAccountFragment`): the
/// request goes to support as a message with a fixed subject, then the user is
/// signed out. A store subscription is not cancelled by this, so the screen
/// points to where it is managed.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.deleteConfirmText),
        actions: [
          TestId(
            DeleteAccountTestIds.cancel,
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.deleteCancel),
            ),
          ),
          TestId(
            DeleteAccountTestIds.confirmDelete,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteAction),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final profile = ref.read(userProfileProvider).value;
    final email = (profile?.email ?? '').isNotEmpty
        ? profile!.email!
        : DeleteAccountRequest.fallbackEmail;
    try {
      await ref
          .read(supportRepositoryProvider)
          .sendFeedback(
            email: email,
            subject: DeleteAccountRequest.subject,
            feedback: DeleteAccountRequest.feedback,
            mobileNumber: profile?.mobileNumber ?? '',
          );
    } on AppFailure {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: TestId(
          DeleteAccountTestIds.processing,
          child: Text(l10n.deleteProcessing),
        ),
        actions: [
          TestId(
            DeleteAccountTestIds.processingOk,
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.deleteOk),
            ),
          ),
        ],
      ),
    );
    // Signing out sends the router to the welcome screen.
    await ref.read(logoutProvider)();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(sessionInfoControllerProvider).user;
    final subscribed = (user?.subscribedDeviceType ?? '').isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          DeleteAccountTestIds.title,
          child: Semantics(header: true, child: Text(l10n.deleteTitle)),
        ),
      ),
      body: TestId(
        DeleteAccountTestIds.root,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l10n.deleteText),
            if (subscribed) ...[
              const SizedBox(height: 16),
              TestId(
                DeleteAccountTestIds.subscriptionNote,
                child: Text(l10n.deleteSubscription),
              ),
              TestId(
                DeleteAccountTestIds.manageSubscription,
                child: TextButton(
                  onPressed: () => ref
                      .read(externalLinksProvider)
                      .open(
                        defaultTargetPlatform == TargetPlatform.iOS
                            ? SubscriptionLinks.manageApple
                            : SubscriptionLinks.manageAndroid,
                      ),
                  child: Text(l10n.deleteManageSubscription),
                ),
              ),
            ],
            if (_failed) ...[
              const SizedBox(height: 12),
              TestId(
                DeleteAccountTestIds.failed,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.deleteFailed,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            TestId(
              DeleteAccountTestIds.delete,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: _busy ? null : _delete,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.deleteAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

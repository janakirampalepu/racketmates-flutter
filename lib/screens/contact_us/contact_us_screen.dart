import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/support/support_repository.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';
import 'package:racketmates/screens/sign_up_details/usecases/validate_sign_up_details.dart'
    show isValidEmail;

/// A message to the Racketmates team (native `ContactUsFragment`), sent with
/// the device facts support asks for.
class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _question = TextEditingController();
  bool _emailMissing = false;
  bool _emailInvalid = false;
  bool _subjectMissing = false;
  bool _questionMissing = false;
  bool _sending = false;
  bool _failed = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _email.dispose();
    _subject.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    setState(() {
      _emailMissing = email.isEmpty;
      _emailInvalid = email.isNotEmpty && !isValidEmail(email);
      _subjectMissing = _subject.text.trim().isEmpty;
      _questionMissing = _question.text.trim().isEmpty;
      _failed = false;
    });
    if (_emailMissing || _emailInvalid || _subjectMissing || _questionMissing) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .sendFeedback(
            email: email,
            subject: _subject.text.trim(),
            feedback: _question.text.trim(),
            mobileNumber: ref.read(userProfileProvider).value?.mobileNumber,
          );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.contactSent)));
      context.pop();
    } on AppFailure {
      if (mounted) {
        setState(() {
          _sending = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    // Start with the email on the account.
    final profile = ref.watch(userProfileProvider).value;
    if (!_prefilled && profile != null) {
      _prefilled = true;
      _email.text = profile.email ?? '';
    }

    Widget error(String id, String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TestId(
        id,
        child: Semantics(
          liveRegion: true,
          child: Text(text, style: TextStyle(color: errorColor)),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          ContactTestIds.title,
          child: Semantics(header: true, child: Text(l10n.contactTitle)),
        ),
      ),
      body: TestId(
        ContactTestIds.root,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TestId(
              ContactTestIds.email,
              child: TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.contactEmail,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (_emailMissing)
              error(ContactTestIds.emailError, l10n.contactEmailRequired),
            if (_emailInvalid)
              error(ContactTestIds.emailError, l10n.contactEmailInvalid),
            const SizedBox(height: 16),
            TestId(
              ContactTestIds.subject,
              child: TextField(
                controller: _subject,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.contactSubject,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (_subjectMissing)
              error(ContactTestIds.subjectError, l10n.contactSubjectRequired),
            const SizedBox(height: 16),
            TestId(
              ContactTestIds.question,
              child: TextField(
                controller: _question,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.contactQuestion,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (_questionMissing)
              error(ContactTestIds.questionError, l10n.contactQuestionRequired),
            if (_failed) error(ContactTestIds.failed, l10n.contactFailed),
            const SizedBox(height: 24),
            TestId(
              ContactTestIds.submit,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.contactSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

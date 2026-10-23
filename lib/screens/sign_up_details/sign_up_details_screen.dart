import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/errors/failure_message.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/sign_up_details/sign_up_details_state.dart';
import 'package:racketmates/screens/sign_up_details/sign_up_details_test_ids.dart';
import 'package:racketmates/screens/sign_up_details/sign_up_details_view_model.dart';

/// Name and optional email (native `SignUpDetailsFragment`).
class SignUpDetailsScreen extends ConsumerStatefulWidget {
  const SignUpDetailsScreen({super.key});

  @override
  ConsumerState<SignUpDetailsScreen> createState() =>
      _SignUpDetailsScreenState();
}

class _SignUpDetailsScreenState extends ConsumerState<SignUpDetailsScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(signUpFlowProvider);
    _first.text = draft?.firstName ?? '';
    _last.text = draft?.lastName ?? '';
    _email.text = draft?.email ?? '';
    Future.microtask(() async {
      await ref
          .read(signUpDetailsViewModelProvider.notifier)
          .loadResumeProfile();
      final loaded = ref.read(signUpFlowProvider);
      if (!mounted || loaded == null || _first.text.isNotEmpty) return;
      _first.text = loaded.firstName;
      _last.text = loaded.lastName;
      _email.text = loaded.email;
    });
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final ok = await ref
        .read(signUpDetailsViewModelProvider.notifier)
        .submit(
          firstName: _first.text,
          lastName: _last.text,
          email: _email.text,
        );
    if (ok && mounted) await context.push(AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(signUpDetailsViewModelProvider);
    final emailError = switch (state.emailError) {
      EmailError.invalid => ref.preMsg(
        MessageKeys.preEmailInvalid,
        l10n.emailInvalidError,
      ),
      EmailError.taken => ref.preMsg(
        MessageKeys.preEmailTaken,
        l10n.emailTakenError,
      ),
      null =>
        state.failure == null ? null : failureMessage(l10n, state.failure!),
    };
    return SignUpScaffold(
      rootId: SignUpDetailsTestIds.root,
      titleId: SignUpDetailsTestIds.title,
      backId: SignUpDetailsTestIds.back,
      title: l10n.signUpDetailsTitle,
      titleGap: 14,
      primaryLabel: l10n.nextAction,
      primaryId: SignUpDetailsTestIds.next,
      loading: state.loading,
      onPrimary: _next,
      onBack: () => context.pop(),
      children: [
        TestId(
          SignUpDetailsTestIds.firstName,
          child: NativeTextField(
            controller: _first,
            label: l10n.firstNameLabel,
            maxLength: 30,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            error: state.firstNameMissing
                ? ref.preMsg(
                    MessageKeys.preFirstNameRequired,
                    l10n.firstNameRequiredError,
                  )
                : null,
          ),
        ),
        TestId(
          SignUpDetailsTestIds.lastName,
          child: NativeTextField(
            controller: _last,
            label: l10n.lastNameLabel,
            maxLength: 30,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.familyName],
            error: state.lastNameMissing
                ? ref.preMsg(
                    MessageKeys.preLastNameRequired,
                    l10n.lastNameRequiredError,
                  )
                : null,
          ),
        ),
        TestId(
          SignUpDetailsTestIds.email,
          child: NativeTextField(
            controller: _email,
            label: l10n.emailLabel,
            keyboardType: TextInputType.emailAddress,
            capitalization: TextCapitalization.none,
            autofillHints: const [AutofillHints.email],
            error: emailError,
            onSubmitted: (_) => _next(),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/auth/phone_verification_repository.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/common/phone/phone_formatting.dart';
import 'package:racketmates/common/profile/roles_edit.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';

/// Add a kid or edit one (native `AddKidsFragment` in profile mode): names, an
/// optional mobile number that no registered user has, and at least one sport.
class KidEditScreen extends ConsumerWidget {
  const KidEditScreen({this.kidId, super.key});

  final int? kidId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          KidEditTestIds.title,
          child: Semantics(
            header: true,
            child: Text(kidId == null ? l10n.kidFormTitle : l10n.kidEditTitle),
          ),
        ),
      ),
      body: TestId(
        KidEditTestIds.root,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.profileLoadError)),
          data: (parent) {
            if (parent == null) {
              return Center(child: Text(l10n.profileLoadError));
            }
            AppUser? kid;
            for (final c in parent.children ?? const <AppUser>[]) {
              if (c.id == kidId) {
                kid = c;
              }
            }
            return _Form(parent: parent, kid: kid);
          },
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.parent, required this.kid});

  final AppUser parent;
  final AppUser? kid;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final KidInput _initial = widget.kid == null
      ? const KidInput(firstName: '', lastName: '')
      : KidInput.of(widget.kid!);
  late final _first = TextEditingController(text: _initial.firstName);
  late final _last = TextEditingController(text: _initial.lastName);
  late final _mobile = TextEditingController(text: _initial.mobileNumber);
  late Set<SportKey> _sports = _initial.sports;
  List<KidError> _errors = const [];
  bool _mobileInvalid = false;
  bool _mobileTaken = false;
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _mobile.dispose();
    super.dispose();
  }

  /// The parent's country, for the format of the kid's number.
  Country? _country() {
    final region = widget.parent.country?.regionCode;
    final list = ref.read(countriesProvider).value;
    if (region == null || list == null) return null;
    for (final c in list) {
      if (c.regionCode == region) return c;
    }
    return null;
  }

  Future<void> _save() async {
    final digits = digitsOnly(_mobile.text);
    final input = KidInput(
      firstName: _first.text,
      lastName: _last.text,
      mobileNumber: digits,
      sports: _sports,
    );
    final errors = validateKid(input);
    final country = _country();
    final invalid =
        digits.isNotEmpty &&
        country != null &&
        validateNationalNumber(digits, country) != PhoneValidation.ok;
    setState(() {
      _errors = errors;
      _mobileInvalid = invalid;
      _mobileTaken = false;
      _failed = false;
    });
    final parentId = widget.parent.id;
    if (errors.isNotEmpty || invalid || parentId == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      // A kid's number must not belong to a registered user, unless it is the
      // kid's own current number.
      if (digits.isNotEmpty &&
          digits != digitsOnly(widget.kid?.mobileNumber ?? '')) {
        final status = await ref
            .read(phoneVerificationRepositoryProvider)
            .validateMobileNumber(
              PhoneNumberParts(
                nationalNumber: digits,
                countryCode: widget.parent.country?.code ?? '',
                regionCode: widget.parent.country?.regionCode ?? '',
              ),
            );
        if (status.userExist ?? false) {
          if (mounted) {
            setState(() {
              _saving = false;
              _mobileTaken = true;
            });
          }
          return;
        }
      }
      final repo = ref.read(userRepositoryProvider);
      final form = kidForm(input, parentId: parentId, existing: widget.kid);
      if (widget.kid == null) {
        await repo.createKid(form);
      } else {
        await repo.updateUser(widget.kid!.id!, form);
      }
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.kid == null ? l10n.kidAdded : l10n.kidUpdated),
        ),
      );
      context.pop();
    } on AppFailure {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TestId(
          KidEditTestIds.firstName,
          child: TextField(
            controller: _first,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.profileFirstName,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (_errors.contains(KidError.firstNameMissing))
          error(KidEditTestIds.firstNameError, l10n.kidNameRequired),
        const SizedBox(height: 16),
        TestId(
          KidEditTestIds.lastName,
          child: TextField(
            controller: _last,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.profileLastName,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (_errors.contains(KidError.lastNameMissing))
          error(KidEditTestIds.lastNameError, l10n.kidNameRequired),
        const SizedBox(height: 16),
        TestId(
          KidEditTestIds.mobile,
          child: TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.kidMobileLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (_mobileInvalid)
          error(KidEditTestIds.mobileError, l10n.kidMobileInvalidError),
        if (_mobileTaken)
          error(KidEditTestIds.mobileError, l10n.kidMobileTakenError),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            l10n.kidSportsLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final sport in SportKey.values)
          TestId(
            KidEditTestIds.sport(sport.key),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(sportLabel(l10n, sport)),
              value: _sports.contains(sport),
              onChanged: (v) => setState(() {
                _sports = {
                  for (final s in _sports)
                    if (s != sport) s,
                  if (v ?? false) sport,
                };
              }),
            ),
          ),
        if (_errors.contains(KidError.sportMissing))
          error(KidEditTestIds.sportError, l10n.sportRequiredError),
        if (_failed) error(KidEditTestIds.failed, l10n.kidSaveFailed),
        const SizedBox(height: 16),
        TestId(
          KidEditTestIds.save,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.kidSave),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/media/image_picker_service.dart';
import 'package:racketmates/common/profile/profile_edit.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/profile/profile_test_ids.dart';

/// The user's profile (native `ProfilePicUpdateFragment`): photo, first and
/// last name and email. Changing roles, sports or the mobile number goes
/// through the sign-up screens and is later work.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          ProfileTestIds.title,
          child: Semantics(header: true, child: Text(l10n.profileTitle)),
        ),
      ),
      body: TestId(
        ProfileTestIds.root,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              _LoadError(onRetry: () => ref.invalidate(userProfileProvider)),
          data: (user) => user == null
              ? _LoadError(onRetry: () => ref.invalidate(userProfileProvider))
              : _Form(user: user),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TestId(ProfileTestIds.loadError, child: Text(l10n.profileLoadError)),
          TestId(
            ProfileTestIds.retry,
            child: TextButton(
              onPressed: onRetry,
              child: Text(l10n.retryAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.user});

  final AppUser user;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late ProfileEdit _edit = ProfileEdit.of(widget.user);
  late final _first = TextEditingController(text: _edit.firstName);
  late final _last = TextEditingController(text: _edit.lastName);
  late final _email = TextEditingController(text: _edit.email);
  List<ProfileError> _errors = const [];
  bool _emailTaken = false;
  bool _saving = false;
  bool _saveFailed = false;
  bool _photoBusy = false;
  bool _photoFailed = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  int? get _userId {
    final session = ref.read(sessionControllerProvider);
    return session is SignedIn ? session.token.user?.id : widget.user.id;
  }

  void _drop(ProfileError error) => setState(
    () => _errors = [
      for (final e in _errors)
        if (e != error) e,
    ],
  );

  Future<void> _save() async {
    final id = _userId;
    final errors = validateProfile(_edit);
    setState(() {
      _errors = errors;
      _saveFailed = false;
      _emailTaken = false;
    });
    if (errors.isNotEmpty || id == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      final email = _edit.normalizedEmail;
      // An email that changed must not belong to somebody else.
      if (email.isNotEmpty &&
          email != (widget.user.email ?? '').toLowerCase() &&
          await repo.isEmailTaken(
            email: email,
            displayName: '${_edit.firstName.trim()} ${_edit.lastName.trim()}',
            userId: id,
          )) {
        if (mounted) {
          setState(() {
            _saving = false;
            _emailTaken = true;
          });
        }
        return;
      }
      await repo.updateProfile(id, buildProfileUpdateBody(widget.user, _edit));
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
      context.pop();
    } on AppFailure {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveFailed = true;
        });
      }
    }
  }

  Future<void> _pickPhoto(PhotoSource source) async {
    final id = _userId;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final path = await ref.read(photoPickerProvider).pick(source);
    if (path == null || id == null || !mounted) return;
    setState(() {
      _photoBusy = true;
      _photoFailed = false;
    });
    try {
      await ref.read(userRepositoryProvider).uploadAvatar(id, path);
      ref.invalidate(userProfileProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.profilePhotoUpdated)));
    } on AppFailure {
      if (mounted) setState(() => _photoFailed = true);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    final id = _userId;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (id == null) return;
    setState(() {
      _photoBusy = true;
      _photoFailed = false;
    });
    try {
      await ref.read(userRepositoryProvider).removeAvatar(id);
      ref.invalidate(userProfileProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.profilePhotoRemoved)));
    } on AppFailure {
      if (mounted) setState(() => _photoFailed = true);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _choosePhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TestId(
              ProfileTestIds.takePhoto,
              child: ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.profilePhotoCamera),
                onTap: () => Navigator.of(sheetContext).pop(PhotoSource.camera),
              ),
            ),
            TestId(
              ProfileTestIds.choosePhoto,
              child: ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.profilePhotoGallery),
                onTap: () =>
                    Navigator.of(sheetContext).pop(PhotoSource.gallery),
              ),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickPhoto(source);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    // The saved profile may have a new photo while this form is open.
    final current = ref.watch(userProfileProvider).value ?? widget.user;
    final photo = (current.avatarFileAttachmentUrl ?? '').isNotEmpty
        ? current.avatarFileAttachmentUrl
        : current.thumbnailAttachmentUrl;
    final hasPhoto = (photo ?? '').isNotEmpty;

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
        Center(
          child: TestId(
            ProfileTestIds.avatar,
            child: Semantics(
              label: l10n.profileTitle,
              image: true,
              child: CircleAvatar(
                radius: 56,
                backgroundImage: hasPhoto ? NetworkImage(photo!) : null,
                onBackgroundImageError: hasPhoto ? (_, _) {} : null,
                child: hasPhoto ? null : const Icon(Icons.person, size: 56),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TestId(
              ProfileTestIds.changePhoto,
              child: TextButton.icon(
                onPressed: _photoBusy ? null : _choosePhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  hasPhoto ? l10n.profilePhotoChange : l10n.profilePhotoAdd,
                ),
              ),
            ),
            if (hasPhoto)
              TestId(
                ProfileTestIds.removePhoto,
                child: TextButton.icon(
                  onPressed: _photoBusy ? null : _removePhoto,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.profilePhotoRemove),
                ),
              ),
          ],
        ),
        if (_photoBusy) const LinearProgressIndicator(),
        if (_photoFailed)
          error(ProfileTestIds.photoFailed, l10n.profilePhotoFailed),
        const SizedBox(height: 16),
        TestId(
          ProfileTestIds.firstName,
          child: TextField(
            controller: _first,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.profileFirstName,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) {
              _edit = _edit.copyWith(firstName: v);
              _drop(ProfileError.firstNameMissing);
            },
          ),
        ),
        if (_errors.contains(ProfileError.firstNameMissing))
          error(ProfileTestIds.firstNameError, l10n.profileFirstNameRequired),
        const SizedBox(height: 16),
        TestId(
          ProfileTestIds.lastName,
          child: TextField(
            controller: _last,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.profileLastName,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) {
              _edit = _edit.copyWith(lastName: v);
              _drop(ProfileError.lastNameMissing);
            },
          ),
        ),
        if (_errors.contains(ProfileError.lastNameMissing))
          error(ProfileTestIds.lastNameError, l10n.profileLastNameRequired),
        const SizedBox(height: 16),
        TestId(
          ProfileTestIds.email,
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.profileEmail,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) {
              _edit = _edit.copyWith(email: v);
              _drop(ProfileError.emailInvalid);
              if (_emailTaken) setState(() => _emailTaken = false);
            },
          ),
        ),
        if (_errors.contains(ProfileError.emailInvalid))
          error(ProfileTestIds.emailError, l10n.profileEmailInvalid),
        if (_emailTaken)
          error(ProfileTestIds.emailError, l10n.profileEmailTaken),
        const SizedBox(height: 16),
        if ((widget.user.mobileNumber ?? '').isNotEmpty)
          TestId(
            ProfileTestIds.phone,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.profilePhone),
              subtitle: Text(widget.user.mobileNumber!),
              trailing: TestId(
                ProfileTestIds.changePhone,
                child: TextButton(
                  onPressed: () async {
                    await context.push(AppRoutes.changePhone);
                    ref.invalidate(userProfileProvider);
                  },
                  child: Text(l10n.profilePhoneChange),
                ),
              ),
            ),
          ),
        if (_saveFailed)
          error(ProfileTestIds.saveFailed, l10n.profileSaveFailed),
        const SizedBox(height: 16),
        TestId(
          ProfileTestIds.save,
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
                : Text(l10n.profileSave),
          ),
        ),
      ],
    );
  }
}

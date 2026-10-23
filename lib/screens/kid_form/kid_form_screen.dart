import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/failure_message.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/common/phone/phone_formatting.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/kid_form/kid_form_args.dart';
import 'package:racketmates/screens/kid_form/kid_form_state.dart';
import 'package:racketmates/screens/kid_form/kid_form_test_ids.dart';
import 'package:racketmates/screens/kid_form/kid_form_view_model.dart';

/// Add or edit a kid: names, optional mobile, sports (native `AddKidsFragment`).
/// The kid's profile photo is not migrated yet.
class KidFormScreen extends ConsumerStatefulWidget {
  const KidFormScreen({this.args = const KidFormArgs(), super.key});

  final KidFormArgs args;

  @override
  ConsumerState<KidFormScreen> createState() => _KidFormScreenState();
}

class _KidFormScreenState extends ConsumerState<KidFormScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _mobile = TextEditingController();
  Set<SportKey> _sports = {};

  @override
  void initState() {
    super.initState();
    final kids = ref.read(signUpFlowProvider)?.kids ?? const <KidDraft>[];
    final i = widget.args.index;
    if (i != null && i < kids.length) {
      _first.text = kids[i].firstName;
      _last.text = kids[i].lastName;
      _mobile.text = kids[i].mobileNumber;
      _sports = {...kids[i].sports};
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Country? _country() {
    final region = ref.read(signUpFlowProvider)?.phone.regionCode;
    final list = ref.read(countriesProvider).value;
    if (list == null) return null;
    return list.where((c) => c.regionCode == region).firstOrNull;
  }

  Future<void> _save() async {
    final ok = await ref
        .read(kidFormViewModelProvider.notifier)
        .save(
          firstName: _first.text,
          lastName: _last.text,
          mobile: _mobile.text,
          sports: _sports,
          country: _country(),
          index: widget.args.index,
        );
    if (!ok || !mounted) return;
    if (widget.args.fromList) {
      context.pop();
    } else {
      context.pushReplacement(AppRoutes.kidsList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(kidFormViewModelProvider);
    final country = _country();
    final mobileError = switch (state.mobileError) {
      KidMobileError.invalid => l10n.kidMobileInvalidError,
      KidMobileError.taken => l10n.kidMobileTakenError,
      null =>
        state.failure == null ? null : failureMessage(l10n, state.failure!),
    };
    final n = context.native;
    final sdp = context.sdp;
    return SignUpScaffold(
      rootId: KidFormTestIds.root,
      titleId: KidFormTestIds.title,
      title: l10n.kidFormTitle,
      titleGap: 14,
      primaryLabel: l10n.saveAction,
      primaryId: KidFormTestIds.save,
      loading: state.loading,
      onPrimary: _save,
      onBack: () => context.pop(),
      children: [
        TestId(
          KidFormTestIds.firstName,
          child: NativeTextField(
            controller: _first,
            label: l10n.firstNameLabel,
            maxLength: 30,
            textInputAction: TextInputAction.next,
            error: state.firstNameMissing ? l10n.firstNameRequiredError : null,
          ),
        ),
        TestId(
          KidFormTestIds.lastName,
          child: NativeTextField(
            controller: _last,
            label: l10n.lastNameLabel,
            maxLength: 30,
            textInputAction: TextInputAction.next,
            error: state.lastNameMissing ? l10n.lastNameRequiredError : null,
          ),
        ),
        TestId(
          KidFormTestIds.mobile,
          child: NativeTextField(
            controller: _mobile,
            label: l10n.kidMobileLabel,
            keyboardType: TextInputType.phone,
            capitalization: TextCapitalization.none,
            inputFormatters: [
              if (country != null) NationalNumberFormatter(country),
              LengthLimitingTextInputFormatter(32),
            ],
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: sdp(32),
                  child: Center(
                    child: Text(
                      country?.flag ?? '',
                      style: TextStyle(
                        fontSize: sdp(24),
                        color: n.scheduleDayColor,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: sdp(4), right: sdp(8)),
                  child: Text(
                    country?.dialCode ?? '',
                    style: NativeText.regular(sdp(12), n.textSecondary),
                  ),
                ),
              ],
            ),
            error: mobileError,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: sdp(12), bottom: sdp(10)),
          child: Text(
            l10n.kidSportsLabel,
            style: NativeText.regular(sdp(12), n.textSecondary),
          ),
        ),
        if (state.sportMissing)
          TestId(
            KidFormTestIds.sportError,
            child: Padding(
              padding: EdgeInsets.only(bottom: sdp(8)),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.sportRequiredError,
                  style: NativeText.regular(sdp(12), n.statusColorsLightRed),
                ),
              ),
            ),
          ),
        for (final sport in SportKey.values)
          TestId(
            KidFormTestIds.sport(sport.key),
            child: NativeChoiceCard(
              icon: 'ic_${sport.name}_sport',
              iconSize: 28,
              padding: 12,
              titleSize: 12,
              title: sportLabel(l10n, sport),
              selected: _sports.contains(sport),
              onChanged: () => setState(() {
                _sports = {..._sports};
                if (!_sports.add(sport)) _sports.remove(sport);
              }),
            ),
          ),
      ],
    );
  }
}

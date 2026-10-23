import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/errors/failure_message.dart';
import 'package:racketmates/common/sign_up/create_account_controller.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/common/sign_up/sport_labels.dart';
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
    final n = context.native;
    final sdp = context.sdp;
    return SignUpScaffold(
      rootId: KidsListTestIds.root,
      titleId: KidsListTestIds.title,
      title: l10n.kidsTitle,
      titleGap: 14,
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
        TestId(
          KidsListTestIds.add,
          child: Padding(
            padding: EdgeInsets.only(top: sdp(6), bottom: sdp(10)),
            child: Material(
              color: n.backgroundSolidSecondary2,
              borderRadius: BorderRadius.circular(sdp(8)),
              child: InkWell(
                borderRadius: BorderRadius.circular(sdp(8)),
                onTap: canAdd
                    ? () => context.push(AppRoutes.kidFormFor(fromList: true))
                    : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: EdgeInsets.all(sdp(10)),
                    child: Row(
                      children: [
                        SvgIcon(
                          'ic_add_team',
                          size: sdp(20),
                          color: n.textPrimary,
                        ),
                        SizedBox(width: sdp(8)),
                        Expanded(
                          child: Text(
                            canAdd ? l10n.addKidAction : l10n.kidsMaxReached,
                            style: NativeText.medium(sdp(12), n.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        for (var i = 0; i < kids.length; i++)
          TestId(
            KidsListTestIds.kid(i),
            child: Padding(
              padding: EdgeInsets.only(bottom: sdp(8)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(sdp(12)),
                  border: Border.all(
                    color: n.statusColorsDarkGray,
                    width: sdp(1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TestId(
                        KidsListTestIds.edit(i),
                        child: Semantics(
                          button: true,
                          label: l10n.editAction,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(sdp(12)),
                            onTap: () => context.push(
                              AppRoutes.kidFormFor(index: i, fromList: true),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Padding(
                                padding: EdgeInsets.all(sdp(10)),
                                child: Row(
                                  children: [
                                    _Initials(kid: kids[i]),
                                    SizedBox(width: sdp(8)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${kids[i].firstName} ${kids[i].lastName}'
                                                .trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: NativeText.semibold(
                                              sdp(12),
                                              n.textPrimary,
                                            ),
                                          ),
                                          if (kids[i].sports.isNotEmpty)
                                            Text(
                                              [
                                                for (final sport
                                                    in kids[i].sports)
                                                  sportLabel(l10n, sport),
                                              ].join(', '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: NativeText.medium(
                                                sdp(10),
                                                n.textTertiary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SvgIcon(
                                      'ic_next_arrow_v2',
                                      size: sdp(14),
                                      color: n.textPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    TestId(
                      KidsListTestIds.remove(i),
                      child: IconButton(
                        tooltip: l10n.removeAction,
                        icon: Icon(
                          Icons.delete_outline,
                          color: n.statusColorsLightRed,
                        ),
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

/// The kid's round picture slot: the initials in lime (native `tvInitials`).
class _Initials extends StatelessWidget {
  const _Initials({required this.kid});

  final KidDraft kid;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    String first(String s) => s.trim().isEmpty ? '' : s.trim()[0].toUpperCase();
    return Container(
      width: sdp(40),
      height: sdp(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: n.colorPrimary, width: sdp(1)),
      ),
      child: Text(
        '${first(kid.firstName)}${first(kid.lastName)}',
        style: NativeText.medium(sdp(12), n.mainTertiary),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final n = context.native;
    final sdp = context.sdp;
    final name = ref.watch(userProfileProvider).value?.firstName;
    return Scaffold(
      body: TestId(
        CongratulationsTestIds.root,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [n.congratsStartGradient, n.congratsEndGradient],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ExcludeSemantics(
                      // The artwork is 390 x 422: full width, its own height.
                      child: AspectRatio(
                        aspectRatio: 390 / 422,
                        child: SvgPicture.asset(
                          'assets/icons/ic_sign_up_completed.svg',
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        sdp(16),
                        sdp(20),
                        sdp(16),
                        sdp(10),
                      ),
                      child: TestId(
                        CongratulationsTestIds.title,
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.congratulationsTitle,
                            textAlign: TextAlign.center,
                            style: NativeText.semibold(sdp(20), n.textPrimary),
                          ),
                        ),
                      ),
                    ),
                    if (name != null && name.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: sdp(16)),
                        child: TestId(
                          CongratulationsTestIds.greeting,
                          child: Text(
                            l10n.congratulationsGreeting(name),
                            textAlign: TextAlign.center,
                            style: NativeText.regular(sdp(12), n.textSecondary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    sdp(12),
                    sdp(10),
                    sdp(12),
                    sdp(30),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Native opens the create-event wizard; until that is
                      // wired in here this also lands on home.
                      TestId(
                        CongratulationsTestIds.addEvent,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: Size.fromHeight(sdp(50)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sdp(12)),
                            ),
                            textStyle: NativeText.bold(sdp(14), n.black),
                          ),
                          onPressed: () => _finish(context, ref),
                          child: Text(l10n.addFirstEventAction),
                        ),
                      ),
                      SizedBox(height: sdp(10)),
                      TestId(
                        CongratulationsTestIds.goHome,
                        child: InkWell(
                          onTap: () => _finish(context, ref),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Center(
                              child: Text(
                                l10n.goToHomeAction,
                                style: NativeText.bold(sdp(14), n.iconPrimary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

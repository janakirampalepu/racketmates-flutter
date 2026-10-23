import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/welcome/landing_video.dart';
import 'package:racketmates/screens/welcome/welcome_test_ids.dart';

/// Signed-out landing, laid out like the native `activity_app_landing.xml`:
/// the brand video behind, the logo and title at the top, the sub text above
/// the buttons, *Sign up* and "Already a member? Sign in" at the bottom.
/// The *Explore* button (native `OnboardOptions`) is not migrated.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    return Scaffold(
      backgroundColor: n.windowBackgroundColor,
      body: TestId(
        WelcomeTestIds.root,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const LandingVideo(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(sdp(16), sdp(32), sdp(16), 0),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgIcon('ic_app_logo', size: sdp(32)),
                          SizedBox(width: sdp(12)),
                          Flexible(
                            child: TestId(
                              WelcomeTestIds.title,
                              child: Text(
                                ref.preMsg(
                                  MessageKeys.preProductTitle,
                                  l10n.welcomeTitle,
                                ),
                                textAlign: TextAlign.center,
                                style: NativeText.semibold(
                                  sdp(24),
                                  n.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(sdp(16), 0, sdp(16), sdp(16)),
                    child: TestId(
                      WelcomeTestIds.subtitle,
                      child: Text(
                        ref.preMsg(
                          MessageKeys.preProductSubText,
                          l10n.welcomeSubtitle,
                        ),
                        textAlign: TextAlign.center,
                        style: NativeText.regular(sdp(16), n.textSecondary),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: sdp(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: sdp(8)),
                        TestId(
                          WelcomeTestIds.signUpButton,
                          child: SizedBox(
                            height: sdp(48),
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: Size.fromHeight(sdp(48)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(sdp(12)),
                                ),
                                textStyle: NativeText.bold(sdp(14), n.black),
                              ),
                              onPressed: () => context.push(
                                AppRoutes.phoneEntryFor('signUp'),
                              ),
                              child: Text(
                                ref.preMsg(
                                  MessageKeys.preSignUpButton,
                                  l10n.signUpAction,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: sdp(12)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ref.preMsg(
                                MessageKeys.preAlreadyMember,
                                l10n.welcomeAlreadyMember,
                              ),
                              style: NativeText.regular(sdp(14), n.textPrimary),
                            ),
                            SizedBox(width: sdp(4)),
                            TestId(
                              WelcomeTestIds.signInButton,
                              child: InkWell(
                                onTap: () => context.push(
                                  AppRoutes.phoneEntryFor('signIn'),
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                    minWidth: 48,
                                  ),
                                  child: Center(
                                    child: Text(
                                      ref.preMsg(
                                        MessageKeys.preSignInLink,
                                        l10n.signInAction,
                                      ),
                                      style: NativeText.semibold(
                                        sdp(14),
                                        n.imagePrimeryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sdp(8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/sign_up/sign_up_flow.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/startup/pending_upgrade.dart';
import 'package:racketmates/screens/app_update/app_update_screen.dart';
import 'package:racketmates/screens/country_picker/country_picker_screen.dart';
import 'package:racketmates/screens/place_picker/place_picker_screen.dart';
import 'package:racketmates/screens/create_event_success/create_event_success_screen.dart';
import 'package:racketmates/common/create_event/match_draft.dart';
import 'package:racketmates/screens/create_event_assign_players/create_event_assign_players_screen.dart';
import 'package:racketmates/screens/create_event_assign_type/create_event_assign_type_screen.dart';
import 'package:racketmates/screens/create_event_matches/create_event_matches_screen.dart';
import 'package:racketmates/screens/create_event_round_robin_format/create_event_round_robin_format_screen.dart';
import 'package:racketmates/screens/create_event_slot_picker/create_event_slot_picker_screen.dart';
import 'package:racketmates/screens/event_manage/event_manage_screen.dart';
import 'package:racketmates/screens/event_manage_add_people/event_manage_add_people_screen.dart';
import 'package:racketmates/screens/event_manage_players/event_manage_players_screen.dart';
import 'package:racketmates/screens/event_manage_schedule/event_manage_schedule_screen.dart';
import 'package:racketmates/screens/event_manage_score_entry/event_manage_score_entry_screen.dart';
import 'package:racketmates/screens/event_manage_scores/event_manage_scores_screen.dart';
import 'package:racketmates/screens/event_manage_settings/event_manage_settings_screen.dart';
import 'package:racketmates/screens/create_event_review/create_event_review_screen.dart';
import 'package:racketmates/screens/create_event_home_away/create_event_home_away_screen.dart';
import 'package:racketmates/screens/create_event_opponent_select/create_event_opponent_select_screen.dart';
import 'package:racketmates/screens/create_event_team_choice/create_event_team_choice_screen.dart';
import 'package:racketmates/screens/create_event_team_dynamics/create_event_team_dynamics_screen.dart';
import 'package:racketmates/screens/create_event_team_select/create_event_team_select_screen.dart';
import 'package:racketmates/screens/create_event_invite_settings/create_event_invite_settings_screen.dart';
import 'package:racketmates/screens/create_event_when_where/create_event_when_where_screen.dart';
import 'package:racketmates/screens/create_event_coaches/create_event_coaches_screen.dart';
import 'package:racketmates/screens/create_event_players/create_event_players_screen.dart';
import 'package:racketmates/screens/create_event_settings/create_event_settings_screen.dart';
import 'package:racketmates/screens/create_event_sport/create_event_sport_screen.dart';
import 'package:racketmates/screens/create_event_type/create_event_type_screen.dart';
import 'package:racketmates/screens/sports_selection/sports_selection_screen.dart';
import 'package:racketmates/screens/sign_up_details/sign_up_details_screen.dart';
import 'package:racketmates/screens/role_selection/role_selection_screen.dart';
import 'package:racketmates/screens/profile_picture/profile_picture_screen.dart';
import 'package:racketmates/screens/kids_list/kids_list_screen.dart';
import 'package:racketmates/screens/kid_form/kid_form_screen.dart';
import 'package:racketmates/screens/kid_form/kid_form_args.dart';
import 'package:racketmates/screens/congratulations/congratulations_screen.dart';
import 'package:racketmates/screens/chat/chat_screen.dart';
import 'package:racketmates/screens/event_details/event_details_screen.dart';
import 'package:racketmates/screens/home/home_screen.dart';
import 'package:racketmates/screens/main_shell/main_shell_screen.dart';
import 'package:racketmates/screens/schedule/schedule_screen.dart';
import 'package:racketmates/screens/create_team/create_team_screen.dart';
import 'package:racketmates/screens/create_team_members/create_team_members_screen.dart';
import 'package:racketmates/screens/team_details/team_details_screen.dart';
import 'package:racketmates/screens/teams/teams_screen.dart';
import 'package:racketmates/screens/otp/otp_args.dart';
import 'package:racketmates/screens/otp/otp_screen.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_args.dart';
import 'package:racketmates/screens/phone_entry/phone_entry_screen.dart';
import 'package:racketmates/screens/splash/splash_screen.dart';
import 'package:racketmates/screens/welcome/welcome_screen.dart';

/// Pure redirect rules (unit-testable). Order matters:
/// 1. mandatory upgrade locks everything to the update screen;
/// 2. while the session is being restored only the splash may show;
/// 3. signed-out users cannot open protected routes; signed-in users skip welcome.
String? computeRedirect({
  required String location,
  required SessionState session,
  required bool mandatoryUpgrade,
  bool signUpInProgress = false,
}) {
  if (mandatoryUpgrade) {
    return location == AppRoutes.appUpdate ? null : AppRoutes.appUpdate;
  }
  if (session is SessionRestoring) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  if (session is SignedOut &&
      (AppRoutes.isProtected(location) ||
          AppRoutes.afterAccountCreated.contains(location))) {
    return AppRoutes.welcome;
  }
  if (session is SignedIn && !signUpInProgress) {
    if (AppRoutes.preLogin.contains(location) ||
        AppRoutes.isSignUpStep(location)) {
      return AppRoutes.home;
    }
  }
  return null;
}

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Central route table. Notification and universal-link routes are added here
/// by their milestones; unknown locations fall back to the splash, which
/// resolves to home (signed in) or welcome (signed out).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref
    ..listen(sessionControllerProvider, (_, _) => refresh.ping())
    ..listen(pendingUpgradeProvider, (_, _) => refresh.ping())
    ..listen(signUpFlowProvider, (_, _) => refresh.ping())
    ..onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => computeRedirect(
      location: state.uri.path,
      session: ref.read(sessionControllerProvider),
      mandatoryUpgrade: ref.read(pendingUpgradeProvider)?.isMandatory ?? false,
      signUpInProgress: ref.read(signUpFlowProvider) != null,
    ),
    errorBuilder: (context, state) => const SplashScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneEntry,
        builder: (context, state) => PhoneEntryScreen(
          mode: state.uri.queryParameters['mode'] == 'signUp'
              ? PhoneEntryMode.signUp
              : PhoneEntryMode.signIn,
        ),
      ),
      GoRoute(
        path: AppRoutes.countryPicker,
        builder: (context, state) => const CountryPickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        // Without the entry step's data (e.g. process restart) start over.
        redirect: (context, state) =>
            ref.read(pendingOtpArgsProvider) == null ? AppRoutes.welcome : null,
        builder: (context, state) =>
            OtpScreen(args: ref.read(pendingOtpArgsProvider)!),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        redirect: (context, state) =>
            ref.read(signUpFlowProvider) == null ? AppRoutes.welcome : null,
        builder: (context, state) => const SignUpDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.sportsSelection}/:role',
        builder: (context, state) => SportsSelectionScreen(
          role: state.pathParameters['role'] == 'coach'
              ? RoleKeys.coach
              : RoleKeys.player,
        ),
      ),
      GoRoute(
        path: AppRoutes.kidsList,
        builder: (context, state) => const KidsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.kidForm,
        builder: (context, state) => KidFormScreen(
          args: KidFormArgs(
            index: int.tryParse(state.uri.queryParameters['index'] ?? ''),
            fromList: state.uri.queryParameters['list'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.profilePicture,
        builder: (context, state) => const ProfilePictureScreen(),
      ),
      GoRoute(
        path: AppRoutes.congratulations,
        builder: (context, state) => const CongratulationsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            MainShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.schedule,
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.teams,
                builder: (context, state) => const TeamsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.event}/:id',
        // A malformed id (e.g. from a bad deep link) falls back to home.
        redirect: (context, state) =>
            int.tryParse(state.pathParameters['id'] ?? '') == null
            ? AppRoutes.home
            : null,
        builder: (context, state) =>
            EventDetailsScreen(eventId: int.parse(state.pathParameters['id']!)),
        routes: [
          GoRoute(
            path: 'manage',
            builder: (context, state) => EventManageScreen(
              eventId: int.parse(state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) => EventManageSettingsScreen(
                  eventId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'players',
                builder: (context, state) => EventManagePlayersScreen(
                  eventId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'add-people',
                builder: (context, state) => EventManageAddPeopleScreen(
                  eventId: int.parse(state.pathParameters['id']!),
                  coaches: state.uri.queryParameters['role'] == 'coach',
                ),
              ),
              GoRoute(
                path: 'schedule',
                builder: (context, state) => EventManageScheduleScreen(
                  eventId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'scores',
                builder: (context, state) => EventManageScoresScreen(
                  eventId: int.parse(state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: ':matchId',
                    // A malformed match id goes back to the list.
                    redirect: (context, state) =>
                        int.tryParse(state.pathParameters['matchId'] ?? '') ==
                            null
                        ? AppRoutes.eventManageScoresFor(
                            int.parse(state.pathParameters['id']!),
                          )
                        : null,
                    builder: (context, state) => EventManageScoreEntryScreen(
                      eventId: int.parse(state.pathParameters['id']!),
                      matchId: int.parse(state.pathParameters['matchId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.places,
        builder: (context, state) =>
            PlacePickerScreen(sportType: state.uri.queryParameters['sport']),
      ),
      GoRoute(
        path: AppRoutes.createEvent,
        // Wizard steps need a started draft (e.g. not after a process restart).
        redirect: (context, state) => ref.read(createEventFlowProvider) == null
            ? AppRoutes.schedule
            : null,
        builder: (context, state) => const CreateEventTypeScreen(),
        routes: [
          GoRoute(
            path: 'sport',
            builder: (context, state) => const CreateEventSportScreen(),
          ),
          GoRoute(
            path: 'team-choice',
            builder: (context, state) => const CreateEventTeamChoiceScreen(),
          ),
          GoRoute(
            path: 'team-select',
            builder: (context, state) => const CreateEventTeamSelectScreen(),
          ),
          GoRoute(
            path: 'team-dynamics',
            builder: (context, state) => const CreateEventTeamDynamicsScreen(),
          ),
          GoRoute(
            path: 'opponent-select',
            builder: (context, state) =>
                const CreateEventOpponentSelectScreen(),
          ),
          GoRoute(
            path: 'home-away',
            builder: (context, state) => const CreateEventHomeAwayScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const CreateEventSettingsScreen(),
          ),
          GoRoute(
            path: 'coaches',
            builder: (context, state) => const CreateEventCoachesScreen(),
          ),
          GoRoute(
            path: 'players',
            builder: (context, state) => const CreateEventPlayersScreen(),
          ),
          GoRoute(
            path: 'matches',
            builder: (context, state) => const CreateEventMatchesScreen(),
          ),
          GoRoute(
            path: 'round-robin-format',
            builder: (context, state) =>
                const CreateEventRoundRobinFormatScreen(),
          ),
          GoRoute(
            path: 'assign-type',
            builder: (context, state) => const CreateEventAssignTypeScreen(),
          ),
          GoRoute(
            path: 'assign-players',
            builder: (context, state) => const CreateEventAssignPlayersScreen(),
            routes: [
              GoRoute(
                path: 'pick',
                builder: (context, state) {
                  final q = state.uri.queryParameters;
                  return CreateEventSlotPickerScreen(
                    match: int.tryParse(q['match'] ?? '') ?? 0,
                    slot: MatchSlot(
                      q['side'] ?? MatchKeys.sideTop,
                      q['position'] ?? MatchKeys.positionCenter,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'when-where',
            builder: (context, state) => const CreateEventWhenWhereScreen(),
          ),
          GoRoute(
            path: 'invite-settings',
            builder: (context, state) =>
                const CreateEventInviteSettingsScreen(),
          ),
          GoRoute(
            path: 'review',
            builder: (context, state) => const CreateEventReviewScreen(),
          ),
          // The draft is cleared when leaving; the id travels in the URL.
          GoRoute(
            path: 'success',
            builder: (context, state) => CreateEventSuccessScreen(
              eventId: int.tryParse(state.uri.queryParameters['eventId'] ?? ''),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.team}/:id',
        // A malformed id (e.g. from a bad deep link) falls back to the teams tab.
        redirect: (context, state) =>
            int.tryParse(state.pathParameters['id'] ?? '') == null
            ? AppRoutes.teams
            : null,
        builder: (context, state) =>
            TeamDetailsScreen(teamId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: AppRoutes.createTeam,
        builder: (context, state) => const CreateTeamScreen(),
        routes: [
          GoRoute(
            path: 'members',
            builder: (context, state) => const CreateTeamMembersScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.appUpdate,
        builder: (context, state) => const AppUpdateScreen(),
      ),
    ],
  );
});

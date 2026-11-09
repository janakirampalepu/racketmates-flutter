import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/create_event/global_create_event.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/common/widgets/family_user_picker.dart';
import 'package:racketmates/common/widgets/home_sections.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/home/home_downtime_banner.dart';
import 'package:racketmates/screens/home/home_test_ids.dart';
import 'package:racketmates/screens/home/home_view_model.dart';

/// Home tab: a maintenance notice, the family picker, upcoming events,
/// pending actions and activity (native `HomeFragment`/iOS `GlobalHomeView`).
/// "Latest updates" and "recent games" are left out: neither native app
/// currently fetches or shows them. RSVP/swipe actions on the cards arrive
/// with the event-management milestone. The three data sections are shared
/// with Team Home (`lib/common/widgets/home_sections.dart`) — native reuses
/// the same `HomeFragmentViewModel`/layout for both, parameterized by an
/// optional team.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(homeViewModelProvider(null));
    final vm = ref.read(homeViewModelProvider(null).notifier);
    final profile = ref.watch(userProfileProvider).value;
    final name = profile?.firstName;
    // Native makes the greeting and the family-avatar picker mutually
    // exclusive (Android `HomeFragment.handleSelectedPlayers()` blanks the
    // toolbar title and shows the avatar row instead when there are kids;
    // iOS `navigationLeftView()` does the same in its nav bar), rather than
    // showing both at once.
    final showFamilyAvatars = hasFamilyToPick(profile);
    final n = context.native;
    final sdp = context.sdp;
    final canOfferCreate = canOfferGlobalCreateEvent(ref);
    return Scaffold(
      backgroundColor: n.backgroundSolidPrimary,
      appBar: AppBar(
        backgroundColor: n.backgroundSolidPrimary,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(sdp(1)),
          child: Container(height: sdp(1), color: n.ndotsColor),
        ),
        title: showFamilyAvatars
            ? const FamilyAvatarsRow(compact: true)
            : TestId(
                HomeTestIds.greeting,
                child: Text(
                  (name != null && name.isNotEmpty)
                      ? l10n.homeGreeting(name)
                      : l10n.homePlaceholder,
                  style: NativeText.semibold(sdp(18), n.textPrimary),
                ),
              ),
        actions: [
          TestId(
            HomeTestIds.settingsButton,
            child: IconButton(
              tooltip: l10n.homeSettingsAction,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ),
        ],
      ),
      body: TestId(
        HomeTestIds.root,
        child: RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView(
            key: const Key(HomeTestIds.list),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: sdp(4)),
            children: [
              const HomeDowntimeBanner(),
              UpcomingEventsSection(
                l10n: l10n,
                value: state.upcoming,
                onRetry: () => vm.reload(HomeSection.upcoming),
                sectionId: HomeTestIds.upcomingSection,
                seeAllId: HomeTestIds.seeAllUpcoming,
                retryId: HomeTestIds.retry(HomeTestIds.upcomingSection),
                createEventId: HomeTestIds.createEvent,
                eventIdFor: (id) => HomeTestIds.event('upcoming', id),
                onSeeAll: () => context.go(AppRoutes.schedule),
                canOfferCreate: canOfferCreate,
                onCreateEvent: startGlobalCreateEvent,
              ),
              // Native `homePageSections`: a `VStack(spacing:
              // SpacingConstants.space32)` between every section.
              SizedBox(height: sdp(32)),
              PendingActionsSection(
                l10n: l10n,
                value: state.pending,
                onRetry: () => vm.reload(HomeSection.pending),
                sectionId: HomeTestIds.pendingSection,
                retryId: HomeTestIds.retry(HomeTestIds.pendingSection),
                actionIdFor: HomeTestIds.pendingAction,
              ),
              SizedBox(height: sdp(32)),
              HomeActivitySection(
                l10n: l10n,
                value: state.activity,
                onRetry: () => vm.reload(HomeSection.activity),
                sectionId: HomeTestIds.activitySection,
                retryId: HomeTestIds.retry(HomeTestIds.activitySection),
                yearBadgeId: HomeTestIds.activityYear,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

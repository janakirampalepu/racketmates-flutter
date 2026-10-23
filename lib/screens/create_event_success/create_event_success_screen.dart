import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/event_drafts/event_draft_actions.dart';
import 'package:racketmates/screens/create_event_success/create_event_success_test_ids.dart';
import 'package:racketmates/screens/home/home_view_model.dart';
import 'package:racketmates/screens/schedule/schedule_view_model.dart';

/// Event created. Leaving clears the wizard and refreshes home and schedule.
class CreateEventSuccessScreen extends ConsumerWidget {
  const CreateEventSuccessScreen({this.eventId, super.key});

  final int? eventId;

  void _finish(BuildContext context, WidgetRef ref, {required bool details}) {
    ref
      ..invalidate(homeViewModelProvider)
      ..invalidate(scheduleListViewModelProvider)
      ..invalidate(createEventSubmitterProvider)
      ..invalidate(draftsProvider);
    ref.read(createEventFlowProvider.notifier).reset();
    context.go(AppRoutes.schedule);
    if (details && eventId != null) {
      context.push(AppRoutes.eventFor(eventId!));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: StepScaffold(
        rootId: CreateEventSuccessTestIds.root,
        titleId: CreateEventSuccessTestIds.title,
        title: ref.msg(MessageKeys.createdTitle, l10n.createdTitle),
        showBack: false,
        children: [
          TestId(
            CreateEventSuccessTestIds.goToSchedule,
            child: FilledButton(
              onPressed: () => _finish(context, ref, details: false),
              child: Text(
                ref.msg(
                  MessageKeys.createdGoToSchedule,
                  l10n.createdGoToSchedule,
                ),
              ),
            ),
          ),
          if (eventId != null) ...[
            const SizedBox(height: 12),
            TestId(
              CreateEventSuccessTestIds.seeDetails,
              child: OutlinedButton(
                onPressed: () => _finish(context, ref, details: true),
                child: Text(
                  ref.msg(
                    MessageKeys.createdSeeDetails,
                    l10n.createdSeeDetails,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

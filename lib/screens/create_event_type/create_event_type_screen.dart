import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_controller.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/content/reference_data.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/events/event_labels.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/create_event_type/create_event_type_test_ids.dart';

/// First wizard step: the event type (backend `event_type` reference data, in
/// the backend's order). Only the types this build can create are selectable.
class CreateEventTypeScreen extends ConsumerWidget {
  const CreateEventTypeScreen({super.key});

  void _close(BuildContext context, WidgetRef ref) {
    ref.read(createEventFlowProvider.notifier).reset();
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reference = ref.watch(referenceDataProvider);
    var items = reference.ofType(ReferenceTypes.eventType);
    // Reference data not loaded yet (first run offline): still offer the types
    // this build supports, with readable labels.
    if (items.isEmpty) {
      items = [for (final key in supportedEventTypes) ReferenceItem(key: key)];
    }
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(createEventFlowProvider.notifier).reset();
      },
      child: StepScaffold(
        rootId: CreateEventTypeTestIds.root,
        titleId: CreateEventTypeTestIds.title,
        title: ref.msg(MessageKeys.createTypeTitle, l10n.createTypeTitle),
        backId: CreateEventTypeTestIds.close,
        onBack: () => _close(context, ref),
        children: [
          for (final item in items)
            if (item.key != null)
              _TypeTile(
                itemKey: item.key!,
                label: item.localizedLabel ?? humanizeKey(item.key),
                subText: item.localizedSubText,
                enabled: supportedEventTypes.contains(item.key),
                onTap: () {
                  final flow = ref.read(createEventFlowProvider.notifier)
                    ..setEventType(item.key!);
                  final next = flow.next(CreateEventStep.type)!;
                  context.push(AppRoutes.routeForStep(next));
                },
              ),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.itemKey,
    required this.label,
    required this.subText,
    required this.enabled,
    required this.onTap,
  });

  final String itemKey;
  final String label;
  final String? subText;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sub = enabled ? subText : l10n.createTypeUnavailable;
    return TestId(
      CreateEventTypeTestIds.type(itemKey),
      child: Card(
        child: ListTile(
          minVerticalPadding: 12,
          enabled: enabled,
          title: Text(label),
          subtitle: (sub ?? '').isEmpty ? null : Text(sub!),
          trailing: enabled ? const Icon(Icons.chevron_right) : null,
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}

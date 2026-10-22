import 'package:flutter/material.dart';
import 'package:racketmates/common/accessibility/test_id.dart';

/// Layout shared by the multi-step flows: back button, title, scrollable body
/// and a primary action pinned at the bottom.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    required this.rootId,
    required this.title,
    required this.children,
    this.primaryLabel,
    this.primaryId,
    this.onPrimary,
    this.loading = false,
    this.showBack = true,
    this.backId,
    this.onBack,
    this.titleId,
    super.key,
  });

  final String rootId;
  final String title;
  final String? titleId;
  final List<Widget> children;
  final String? primaryLabel;
  final String? primaryId;
  final VoidCallback? onPrimary;
  final bool loading;
  final bool showBack;
  final String? backId;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final heading = Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium,
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBack
            ? TestId(
                backId ?? '${rootId}_back_button',
                child: BackButton(onPressed: onBack),
              )
            : null,
      ),
      body: TestId(
        rootId,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    titleId == null
                        ? heading
                        : TestId(titleId!, child: heading),
                    const SizedBox(height: 16),
                    ...children,
                  ],
                ),
              ),
              if (primaryLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: TestId(
                    primaryId ?? '${rootId}_primary_button',
                    child: FilledButton(
                      onPressed: loading ? null : onPrimary,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(primaryLabel!),
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

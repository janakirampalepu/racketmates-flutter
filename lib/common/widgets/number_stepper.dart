import 'package:flutter/material.dart';
import 'package:racketmates/common/accessibility/test_id.dart';

/// `- value +` control with 48 dp buttons and a spoken label.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    required this.value,
    required this.onChanged,
    required this.idPrefix,
    required this.label,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.min = 1,
    this.max,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  /// Appium identifiers: `<idPrefix>_decrease`, `<idPrefix>_value`,
  /// `<idPrefix>_increase`.
  final String idPrefix;
  final String label;
  final String decreaseLabel;
  final String increaseLabel;
  final int min;
  final int? max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TestId(
          '${idPrefix}_decrease',
          child: IconButton.outlined(
            tooltip: '$decreaseLabel $label',
            icon: const Icon(Icons.remove),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
        ),
        TestId(
          '${idPrefix}_value',
          child: Semantics(
            label: '$label: $value',
            excludeSemantics: true,
            child: SizedBox(
              width: 48,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
        TestId(
          '${idPrefix}_increase',
          child: IconButton.outlined(
            tooltip: '$increaseLabel $label',
            icon: const Icon(Icons.add),
            onPressed: (max == null || value < max!)
                ? () => onChanged(value + 1)
                : null,
          ),
        ),
      ],
    );
  }
}

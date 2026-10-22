import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/phone/country.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/country_picker/country_picker_test_ids.dart';

/// Searchable country list; pops with the chosen [Country]
/// (native `CountryPickerActvity`).
class CountryPickerScreen extends ConsumerStatefulWidget {
  const CountryPickerScreen({super.key});

  @override
  ConsumerState<CountryPickerScreen> createState() =>
      _CountryPickerScreenState();
}

class _CountryPickerScreenState extends ConsumerState<CountryPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countries = ref.watch(countriesProvider).value ?? const <Country>[];
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? countries
        : [
            for (final c in countries)
              if (c.name.toLowerCase().contains(q) ||
                  c.dialCode.contains(q) ||
                  c.regionCode.toLowerCase() == q)
                c,
          ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.countryPickerTitle)),
      body: TestId(
        CountryPickerTestIds.root,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TestId(
                CountryPickerTestIds.search,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: l10n.searchHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            ),
            Expanded(
              child: TestId(
                CountryPickerTestIds.list,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final country = filtered[index];
                    return TestId(
                      CountryPickerTestIds.item(country.regionCode),
                      child: ListTile(
                        leading: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(country.name),
                        trailing: Text(country.dialCode),
                        onTap: () => context.pop(country),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/place_picker/place_picker_state.dart';
import 'package:racketmates/screens/place_picker/place_picker_test_ids.dart';
import 'package:racketmates/screens/place_picker/place_picker_view_model.dart';

/// Venue search + favourites; pops with the chosen [PlaceItem]
/// (native `LocationActivity` / `LocationsListFragment`, selection mode).
class PlacePickerScreen extends ConsumerWidget {
  const PlacePickerScreen({this.sportType, super.key});

  /// Backend sport key to filter by (`st_tennis`), or null for all venues.
  final String? sportType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = placePickerViewModelProvider(sportType);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.placePickerTitle),
          bottom: TabBar(
            tabs: [
              TestId(
                PlacePickerTestIds.tabSearch,
                child: Tab(text: l10n.tabSearchPlaces),
              ),
              TestId(
                PlacePickerTestIds.tabFavourites,
                child: Tab(text: l10n.tabFavouritePlaces),
              ),
            ],
          ),
        ),
        body: TestId(
          PlacePickerTestIds.root,
          child: TabBarView(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TestId(
                      PlacePickerTestIds.search,
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          labelText: l10n.placeSearchHint,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: vm.setQuery,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _PlaceList(
                      list: state.search,
                      emptyText: l10n.placesEmpty,
                      busyId: state.togglingFavouriteFor,
                      onRetry: vm.loadSearch,
                      onToggle: vm.toggleFavourite,
                    ),
                  ),
                ],
              ),
              _PlaceList(
                list: state.favourites,
                emptyText: l10n.placesFavouritesEmpty,
                busyId: state.togglingFavouriteFor,
                onRetry: vm.loadFavourites,
                onToggle: vm.toggleFavourite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceList extends StatelessWidget {
  const _PlaceList({
    required this.list,
    required this.emptyText,
    required this.busyId,
    required this.onRetry,
    required this.onToggle,
  });

  final PlaceListState list;
  final String emptyText;
  final int? busyId;
  final VoidCallback onRetry;
  final void Function(PlaceItem) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (list.loading && list.places.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.failure != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.placesLoadError),
            TestId(
              PlacePickerTestIds.retry,
              child: TextButton(
                onPressed: onRetry,
                child: Text(l10n.retryAction),
              ),
            ),
          ],
        ),
      );
    }
    if (list.isEmpty) {
      return Center(
        child: TestId(PlacePickerTestIds.empty, child: Text(emptyText)),
      );
    }
    return ListView.builder(
      itemCount: list.places.length,
      itemBuilder: (context, index) {
        final place = list.places[index];
        final id = place.id;
        final isFav = place.favourite ?? false;
        return TestId(
          PlacePickerTestIds.place(id ?? index),
          child: ListTile(
            minVerticalPadding: 12,
            title: Text(place.name ?? ''),
            subtitle: Text(
              [
                if ((place.address ?? '').isNotEmpty) place.address!,
                if ((place.distance ?? '').isNotEmpty) place.distance!,
              ].join(' · '),
            ),
            trailing: TestId(
              PlacePickerTestIds.favourite(id ?? index),
              child: IconButton(
                tooltip: isFav
                    ? l10n.removeFavouriteAction
                    : l10n.addFavouriteAction,
                icon: Icon(isFav ? Icons.star : Icons.star_border),
                onPressed: busyId != null ? null : () => onToggle(place),
              ),
            ),
            onTap: () => context.pop(place),
          ),
        );
      },
    );
  }
}

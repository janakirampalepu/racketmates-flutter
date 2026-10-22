import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/location/location_platform.dart';
import 'package:racketmates/common/location/user_location.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/locations/locations_test_ids.dart';
import 'package:racketmates/screens/place_picker/place_picker_state.dart';
import 'package:racketmates/screens/place_picker/place_picker_view_model.dart';

/// Venues near the user and their favourites (native `LocationsListFragment` /
/// `MyFavoritePlacesFragment`): search by name, ordered by distance once the
/// device position is known, a distance filter, and a star per venue. A venue
/// opens its page. Creating a venue (address search, courts) is not part of
/// this build.
class LocationsScreen extends ConsumerStatefulWidget {
  const LocationsScreen({super.key});

  @override
  ConsumerState<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends ConsumerState<LocationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final AppLifecycleListener _lifecycle;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Back from the system settings after allowing location.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (ref.read(userLocationProvider).permission !=
            LocationPermission.granted) {
          unawaited(ref.read(userLocationProvider.notifier).recheck());
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  PlacePickerViewModel get _vm =>
      ref.read(placePickerViewModelProvider(null).notifier);

  Future<void> _open(PlaceItem place) async {
    final id = place.id;
    if (id == null) return;
    await context.push(AppRoutes.venueFor(id));
    if (!mounted) return;
    // The venue page may have changed the star.
    unawaited(_vm.loadFavourites());
    unawaited(_vm.loadSearch());
  }

  Future<void> _filter(String unit) async {
    final current =
        ref.read(searchDistanceProvider).value ?? defaultSearchDistance;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(initial: current, unit: unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(placePickerViewModelProvider(null));
    final location = ref.watch(userLocationProvider);
    final distance =
        ref.watch(searchDistanceProvider).value ?? defaultSearchDistance;
    final unitKey = ref.watch(sessionInfoControllerProvider).user?.distanceType;
    final unit = ref.refLabel(unitKey, l10n.locationsDefaultUnit);

    // A new position or radius asks for new results.
    ref
      ..listen(userLocationProvider.select((s) => s.position), (prev, next) {
        if (prev != next) unawaited(_vm.loadSearch());
      })
      ..listen(searchDistanceProvider.select((s) => s.value), (prev, next) {
        if (prev != null && prev != next) unawaited(_vm.loadSearch());
      });

    Widget banner() {
      if (location.loading) {
        return Text(l10n.locationsLocating);
      }
      if (location.known) {
        return Text(
          '${l10n.locationsNearYou} · ${l10n.locationsDistanceValue(distance, unit)}',
        );
      }
      final denied = location.permission == LocationPermission.denied;
      return Row(
        children: [
          Expanded(child: Text(l10n.locationsNoLocation)),
          TestId(
            denied
                ? LocationsTestIds.openSettings
                : LocationsTestIds.enableLocation,
            child: TextButton(
              onPressed: () => denied
                  ? ref.read(userLocationProvider.notifier).openSettings()
                  : ref.read(userLocationProvider.notifier).ensure(),
              child: Text(
                denied ? l10n.locationsOpenSettings : l10n.locationsEnable,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          LocationsTestIds.title,
          child: Semantics(header: true, child: Text(l10n.locationsTitle)),
        ),
        actions: [
          if (location.known)
            TestId(
              LocationsTestIds.filterButton,
              child: IconButton(
                tooltip: l10n.locationsFilter,
                icon: const Icon(Icons.tune),
                onPressed: () => _filter(unit),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            TestId(
              LocationsTestIds.tabNearby,
              child: Tab(text: l10n.locationsNearby),
            ),
            TestId(
              LocationsTestIds.tabFavourites,
              child: Tab(text: l10n.locationsFavourites),
            ),
          ],
        ),
      ),
      body: TestId(
        LocationsTestIds.root,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TestId(
                LocationsTestIds.search,
                child: TextField(
                  controller: _search,
                  onChanged: _vm.setQuery,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: l10n.locationsSearchHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TestId(LocationsTestIds.locationBanner, child: banner()),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _VenueList(
                    list: state.search,
                    emptyText: l10n.placesEmpty,
                    busyId: state.togglingFavouriteFor,
                    onRetry: _vm.loadSearch,
                    onToggle: _vm.toggleFavourite,
                    onOpen: _open,
                  ),
                  _VenueList(
                    list: state.favourites,
                    emptyText: l10n.placesFavouritesEmpty,
                    busyId: state.togglingFavouriteFor,
                    onRetry: _vm.loadFavourites,
                    onToggle: _vm.toggleFavourite,
                    onOpen: _open,
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

class _VenueList extends StatelessWidget {
  const _VenueList({
    required this.list,
    required this.emptyText,
    required this.busyId,
    required this.onRetry,
    required this.onToggle,
    required this.onOpen,
  });

  final PlaceListState list;
  final String emptyText;
  final int? busyId;
  final VoidCallback onRetry;
  final void Function(PlaceItem) onToggle;
  final void Function(PlaceItem) onOpen;

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
            TestId(LocationsTestIds.error, child: Text(l10n.placesLoadError)),
            TestId(
              LocationsTestIds.retry,
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
        child: TestId(LocationsTestIds.empty, child: Text(emptyText)),
      );
    }
    return TestId(
      LocationsTestIds.list,
      child: ListView.builder(
        itemCount: list.places.length,
        itemBuilder: (context, index) {
          final place = list.places[index];
          final id = place.id;
          final fav = place.favourite ?? false;
          return TestId(
            LocationsTestIds.place(id ?? index),
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
                LocationsTestIds.favourite(id ?? index),
                child: IconButton(
                  tooltip: fav
                      ? l10n.removeFavouriteAction
                      : l10n.addFavouriteAction,
                  icon: Icon(fav ? Icons.star : Icons.star_border),
                  onPressed: busyId != null ? null : () => onToggle(place),
                ),
              ),
              onTap: () => onOpen(place),
            ),
          );
        },
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial, required this.unit});

  final int initial;
  final String unit;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: TestId(
        LocationsTestIds.filterSheet,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.locationsFilter,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(l10n.locationsDistanceHint),
              const SizedBox(height: 8),
              TestId(
                LocationsTestIds.distanceSlider,
                child: Slider(
                  value: _value.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: l10n.locationsDistanceValue(_value, widget.unit),
                  semanticFormatterCallback: (v) =>
                      l10n.locationsDistanceValue(v.round(), widget.unit),
                  onChanged: (v) => setState(() => _value = v.round()),
                ),
              ),
              Text(l10n.locationsDistanceValue(_value, widget.unit)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TestId(
                      LocationsTestIds.filterReset,
                      child: OutlinedButton(
                        onPressed: () async {
                          await ref
                              .read(searchDistanceProvider.notifier)
                              .reset();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: Text(l10n.locationsReset),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TestId(
                      LocationsTestIds.filterApply,
                      child: FilledButton(
                        onPressed: () async {
                          await ref
                              .read(searchDistanceProvider.notifier)
                              .set(_value);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: Text(l10n.locationsApply),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

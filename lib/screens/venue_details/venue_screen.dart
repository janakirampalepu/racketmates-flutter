import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/links/external_links.dart';
import 'package:racketmates/common/places/map_links.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/places/places_repository.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/locations/locations_test_ids.dart';

final venueProvider = FutureProvider.autoDispose.family<PlaceItem, int>(
  (ref, id) => ref.read(placesRepositoryProvider).details(id),
);

/// One venue (native `LocationDetailsPicker` / `LocationCourtInfoFragment`):
/// where it is, what kind of place, its courts, the star, and directions in
/// the device's map app. Editing a venue or its courts is not part of this
/// build.
class VenueScreen extends ConsumerStatefulWidget {
  const VenueScreen({required this.placeId, super.key});

  final int placeId;

  @override
  ConsumerState<VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends ConsumerState<VenueScreen> {
  /// The star as the user left it, until the server's copy is reloaded.
  bool? _favourite;
  bool _busy = false;

  Future<void> _toggle(PlaceItem place) async {
    final next = !(_favourite ?? place.favourite ?? false);
    setState(() => _busy = true);
    try {
      await ref
          .read(placesRepositoryProvider)
          .setFavourite(widget.placeId, favourite: next);
      if (mounted) setState(() => _favourite = next);
    } on AppFailure {
      // The star stays as it was.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final venue = ref.watch(venueProvider(widget.placeId));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: TestId(
          VenueTestIds.title,
          child: Semantics(
            header: true,
            child: Text(venue.value?.name ?? l10n.locationsTitle),
          ),
        ),
        actions: [
          if (venue.value case final place?)
            TestId(
              VenueTestIds.favourite,
              child: IconButton(
                tooltip: (_favourite ?? place.favourite ?? false)
                    ? l10n.removeFavouriteAction
                    : l10n.addFavouriteAction,
                icon: Icon(
                  (_favourite ?? place.favourite ?? false)
                      ? Icons.star
                      : Icons.star_border,
                ),
                onPressed: _busy ? null : () => _toggle(place),
              ),
            ),
        ],
      ),
      body: TestId(
        VenueTestIds.root,
        child: venue.when(
          loading: () => Center(
            child: TestId(
              VenueTestIds.loading,
              child: Semantics(
                label: l10n.chatConnecting,
                child: const CircularProgressIndicator(),
              ),
            ),
          ),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TestId(VenueTestIds.error, child: Text(l10n.venueLoadError)),
                TestId(
                  VenueTestIds.retry,
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(venueProvider(widget.placeId)),
                    child: Text(l10n.retryAction),
                  ),
                ),
              ],
            ),
          ),
          data: (place) => _Details(place: place),
        ),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.place});

  final PlaceItem place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final courts = place.placeCourts ?? const <PlaceCourt>[];
    final typeLabel = ref.refLabel(place.placeType, '');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (typeLabel.isNotEmpty)
          TestId(VenueTestIds.type, child: Text(typeLabel)),
        if ((place.address ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          TestId(
            VenueTestIds.address,
            child: Text(
              place.address!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
        if ((place.distance ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          TestId(VenueTestIds.distance, child: Text(place.distance!)),
        ],
        if (place.requiresMembership ?? false) ...[
          const SizedBox(height: 8),
          TestId(VenueTestIds.membership, child: Text(l10n.venueMembership)),
        ],
        if (hasMapTarget(place)) ...[
          const SizedBox(height: 16),
          TestId(
            VenueTestIds.directions,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.directions),
              label: Text(l10n.venueDirections),
              onPressed: () => unawaited(
                ref
                    .read(externalLinksProvider)
                    .open(mapLinkFor(place, defaultTargetPlatform)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            l10n.venueCourts,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (courts.isEmpty)
          TestId(VenueTestIds.noCourts, child: Text(l10n.venueNoCourts))
        else
          TestId(
            VenueTestIds.courts,
            child: Column(
              children: [
                for (final (i, court) in courts.indexed)
                  TestId(
                    VenueTestIds.court(court.id ?? i),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(court.name ?? ''),
                      subtitle: Text(
                        [
                          ref.refLabel(court.sportType, ''),
                          switch (court.courtType) {
                            'ct_indoor' => l10n.venueCourtIndoor,
                            'ct_outdoor' => l10n.venueCourtOutdoor,
                            _ => '',
                          },
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

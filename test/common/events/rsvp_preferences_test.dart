import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/events/models/event_details.dart';
import 'package:racketmates/common/events/rsvp_preferences.dart';
import 'package:racketmates/common/users/models/app_user.dart';

EventDetails _event({
  String type = 'et_round_robin',
  String? game,
  String? partnership,
}) =>
    EventDetails(eventType: type, gameType: game, partnershipType: partnership);

const _player = CurrentUserEventDetail(isPlayer: true);
final _partner = EventParticipant(
  id: 77,
  user: const AppUser(id: 5, firstName: 'Zoe', lastName: 'Vega'),
);

void main() {
  group('who is asked', () {
    test(
      'players of a round robin, unless it is plain singles or rotating',
      () {
        expect(
          asksPreferences(
            _event(game: 'egt_both', partnership: 'ept_fixed'),
            _player,
          ),
          isTrue,
        );
        expect(
          asksPreferences(
            _event(game: 'egt_both', partnership: 'ept_rotating'),
            _player,
          ),
          isTrue,
        );
        expect(
          asksPreferences(
            _event(game: 'egt_doubles', partnership: 'ept_fixed'),
            _player,
          ),
          isTrue,
        );
        expect(
          asksPreferences(
            _event(game: 'egt_doubles', partnership: 'ept_rotating'),
            _player,
          ),
          isFalse,
        );
        expect(
          asksPreferences(
            _event(game: 'egt_singles', partnership: 'ept_fixed'),
            _player,
          ),
          isFalse,
        );
      },
    );

    test('not for other events or people who do not play', () {
      final e = _event(game: 'egt_both', partnership: 'ept_fixed');
      expect(
        asksPreferences(
          _event(type: 'et_competitive', game: 'egt_both'),
          _player,
        ),
        isFalse,
      );
      expect(
        asksPreferences(e, const CurrentUserEventDetail(isPlayer: false)),
        isFalse,
      );
      expect(asksPreferences(e, null), isFalse);
    });

    test('match type needs both game types, partner needs fixed or unset', () {
      expect(asksMatchType(_event(game: 'egt_both')), isTrue);
      expect(asksMatchType(_event(game: 'egt_doubles')), isFalse);
      expect(asksPartner(_event(partnership: 'ept_fixed')), isTrue);
      expect(
        asksPartner(_event()),
        isTrue,
      ); // like native: only rotating skips it
      expect(asksPartner(_event(partnership: 'ept_rotating')), isFalse);
    });
  });

  group('starting values', () {
    final both = _event(game: 'egt_both', partnership: 'ept_fixed');

    test('a new response starts with doubles and a partner', () {
      final p = initialPreferences(
        both,
        CurrentUserEventDetail(
          preferredMatchType: 'mt_undecided',
          eventPartner: _partner,
        ),
        editing: false,
      );
      expect(p.matchType, 'mt_doubles');
      expect(p.partnerType, partnerHas);
      expect(p.partner?.id, 77); // someone who asked keeps being offered
    });

    test('changing starts from what is stored', () {
      final p = initialPreferences(
        both,
        const CurrentUserEventDetail(
          preferredMatchType: 'mt_undecided',
          partnershipPreference: partnerNeeds,
        ),
        editing: true,
      );
      expect(p.matchType, 'mt_undecided');
      expect(p.partnerType, partnerNeeds);
    });

    test('no match type when the event has one game type', () {
      expect(
        initialPreferences(
          _event(game: 'egt_doubles'),
          _player,
          editing: false,
        ).matchType,
        isNull,
      );
    });
  });

  group('what is sent', () {
    final both = _event(game: 'egt_both', partnership: 'ept_fixed');

    test('someone with a partner must name one', () {
      expect(preferencesComplete(both, const RsvpPreferences()), isFalse);
      expect(
        preferencesComplete(both, RsvpPreferences(partner: _partner)),
        isTrue,
      );
      expect(
        preferencesComplete(
          both,
          const RsvpPreferences(partnerType: partnerNeeds),
        ),
        isTrue,
      );
      expect(
        preferencesComplete(
          _event(partnership: 'ept_rotating'),
          const RsvpPreferences(),
        ),
        isTrue,
      );
    });

    test('match type, note and partner go out as the server names them', () {
      expect(
        preferenceFields(
          both,
          RsvpPreferences(
            matchType: 'mt_undecided',
            partner: _partner,
            notes: 'late',
          ),
          withNotes: true,
        ),
        {
          'preferred_match_type': 'mt_undecided',
          'notes': 'late',
          'event_partner_id': 77,
        },
      );
    });

    test('no partner is sent for "I need a partner" or without notes', () {
      expect(
        preferenceFields(
          both,
          RsvpPreferences(
            matchType: 'mt_doubles',
            partnerType: partnerNeeds,
            partner: _partner,
          ),
          withNotes: false,
        ),
        {'preferred_match_type': 'mt_doubles'},
      );
    });

    test('rotating partners and one game type send nothing but the note', () {
      expect(
        preferenceFields(
          _event(game: 'egt_doubles', partnership: 'ept_rotating'),
          RsvpPreferences(
            matchType: 'mt_doubles',
            partner: _partner,
            notes: 'x',
          ),
          withNotes: true,
        ),
        {'notes': 'x'},
      );
    });
  });

  group('partner standing', () {
    final fixed = _event(game: 'egt_doubles', partnership: 'ept_fixed');

    PartnerStanding standing(
      String? preference,
      EventParticipant? partner, {
      EventDetails? event,
    }) => partnerStandingFor(
      event ?? fixed,
      CurrentUserEventDetail(
        partnershipPreference: preference,
        eventPartner: partner,
      ),
    );

    test('the four cases of a fixed-partner event', () {
      expect(standing(partnerHas, _partner), PartnerStanding.mine);
      expect(standing(null, _partner), PartnerStanding.requested);
      expect(standing(partnerHas, null), PartnerStanding.needsChoice);
      expect(standing(null, null), PartnerStanding.none);
    });

    test('other events have none', () {
      expect(
        standing(
          partnerHas,
          _partner,
          event: _event(game: 'egt_singles', partnership: 'ept_fixed'),
        ),
        PartnerStanding.none,
      );
      expect(
        standing(
          partnerHas,
          _partner,
          event: _event(game: 'egt_both', partnership: 'ept_rotating'),
        ),
        PartnerStanding.none,
      );
      expect(
        standing(
          partnerHas,
          _partner,
          event: _event(type: 'et_casual', partnership: 'ept_fixed'),
        ),
        PartnerStanding.none,
      );
      expect(partnerStandingFor(fixed, null), PartnerStanding.none);
    });
  });
}

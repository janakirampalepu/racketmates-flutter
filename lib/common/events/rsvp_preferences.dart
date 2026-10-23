import 'package:racketmates/common/events/models/event_details.dart';

/// `partnership_preference` values.
const partnerHas = 'eppp_has_partner';
const partnerNeeds = 'eppp_needs_partner';

/// Native `COURT_NOTES_LENGTH`.
const rsvpNotesLimit = 100;

/// What a round robin player says when responding: the match type they like,
/// whether they come with a partner (and who), and a note.
class RsvpPreferences {
  const RsvpPreferences({
    this.matchType,
    this.partnerType = partnerHas,
    this.partner,
    this.notes = '',
  });

  /// `mt_doubles` or `mt_undecided`; null when the event is one game type.
  final String? matchType;
  final String partnerType;
  final EventParticipant? partner;
  final String notes;

  RsvpPreferences copyWith({
    String? Function()? matchType,
    String? partnerType,
    EventParticipant? Function()? partner,
    String? notes,
  }) => RsvpPreferences(
    matchType: matchType != null ? matchType() : this.matchType,
    partnerType: partnerType ?? this.partnerType,
    partner: partner != null ? partner() : this.partner,
    notes: notes ?? this.notes,
  );
}

/// Round robin players are asked about their game, unless the event is
/// singles only, or the game type is fixed and partners rotate (native
/// `llRoundRobinOptions`).
bool asksPreferences(EventDetails event, CurrentUserEventDetail? me) =>
    event.isRoundRobin &&
    (me?.isPlayer ?? false) &&
    !(event.gameType == 'egt_singles' ||
        (event.gameType != 'egt_both' &&
            event.partnershipType == 'ept_rotating'));

/// Doubles or either: only when the event allows both.
bool asksMatchType(EventDetails event) => event.gameType == 'egt_both';

/// Partners are asked about unless they rotate.
bool asksPartner(EventDetails event) => event.partnershipType != 'ept_rotating';

/// Where the preferences start: a new response starts with doubles and a
/// partner; changing one starts from what is stored.
RsvpPreferences initialPreferences(
  EventDetails event,
  CurrentUserEventDetail? me, {
  required bool editing,
}) => RsvpPreferences(
  matchType: asksMatchType(event)
      ? (editing ? (me?.preferredMatchType ?? 'mt_doubles') : 'mt_doubles')
      : null,
  partnerType: editing ? (me?.partnershipPreference ?? partnerHas) : partnerHas,
  partner: me?.eventPartner,
);

/// Someone who says they have a partner must name one.
bool preferencesComplete(EventDetails event, RsvpPreferences p) =>
    !(asksPartner(event) && p.partnerType == partnerHas && p.partner == null);

/// The fields sent with the response. [withNotes] is for a new response; a
/// partner is only sent for "I have a partner".
Map<String, dynamic> preferenceFields(
  EventDetails event,
  RsvpPreferences p, {
  required bool withNotes,
}) => {
  if (asksMatchType(event) && p.matchType != null)
    'preferred_match_type': p.matchType,
  if (withNotes) 'notes': p.notes,
  if (asksPartner(event) &&
      p.partnerType == partnerHas &&
      p.partner?.id != null)
    'event_partner_id': p.partner!.id,
};

/// Where a player stands on a fixed-partner event (native
/// `refreshEventPartnerForSelectedUser`).
enum PartnerStanding {
  /// Not a fixed-partner event, or nothing to say yet.
  none,

  /// The player chose a partner.
  mine,

  /// Another player asked this one to be their partner.
  requested,

  /// The player wants a partner but has not chosen one.
  needsChoice,
}

PartnerStanding partnerStandingFor(
  EventDetails event,
  CurrentUserEventDetail? me,
) {
  if (!(event.isRoundRobin &&
          event.gameType != 'egt_singles' &&
          event.partnershipType == 'ept_fixed') ||
      me == null) {
    return PartnerStanding.none;
  }
  final preference = me.partnershipPreference;
  final partner = me.eventPartner;
  if (preference != null && partner != null) return PartnerStanding.mine;
  if (preference == null && partner != null) return PartnerStanding.requested;
  if (preference != null && partner == null) return PartnerStanding.needsChoice;
  return PartnerStanding.none;
}

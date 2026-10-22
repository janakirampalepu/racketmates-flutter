import 'package:racketmates/common/sign_up/sign_up_draft.dart';

/// Where to go next; encodes the native role-based routing
/// (`RoleSelectionFragment`, `Player/CoachSportsListFragment`, `KidsList`).
enum SignUpStep { playerSports, coachSports, kidForm, kidsList, createAccount }

SignUpStep _kidsStep(SignUpDraft draft) =>
    draft.kids.isEmpty ? SignUpStep.kidForm : SignUpStep.kidsList;

SignUpStep stepAfterRoles(SignUpDraft draft) {
  if (draft.hasOnlyParent) return _kidsStep(draft);
  if (draft.hasCoach && !draft.hasPlayer) return SignUpStep.coachSports;
  return SignUpStep.playerSports;
}

SignUpStep stepAfterPlayerSports(SignUpDraft draft) {
  if (draft.hasCoach) return SignUpStep.coachSports;
  if (draft.hasParent) return _kidsStep(draft);
  return SignUpStep.createAccount;
}

SignUpStep stepAfterCoachSports(SignUpDraft draft) =>
    draft.hasParent ? _kidsStep(draft) : SignUpStep.createAccount;

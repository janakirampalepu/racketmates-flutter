import 'package:racketmates/common/auth/models/session_token.dart';

sealed class SessionState {
  const SessionState();
}

/// Persisted session not yet read (cold start).
class SessionRestoring extends SessionState {
  const SessionRestoring();
}

class SignedIn extends SessionState {
  const SignedIn(this.token);

  final SessionToken token;
}

class SignedOut extends SessionState {
  const SignedOut();
}

import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/users/models/app_user.dart';

class CreateEventPlayersState {
  const CreateEventPlayersState({
    this.query = '',
    this.results = const [],
    this.loading = true,
    this.failure,
  });

  final String query;
  final List<AppUser> results;
  final bool loading;
  final AppFailure? failure;

  bool get isEmpty => !loading && failure == null && results.isEmpty;

  CreateEventPlayersState copyWith({
    String? query,
    List<AppUser>? results,
    bool? loading,
    AppFailure? Function()? failure,
  }) => CreateEventPlayersState(
    query: query ?? this.query,
    results: results ?? this.results,
    loading: loading ?? this.loading,
    failure: failure != null ? failure() : this.failure,
  );
}

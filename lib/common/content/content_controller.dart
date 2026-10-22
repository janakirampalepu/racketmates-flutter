import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/auth/models/app_metadata.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/content/content_api.dart';
import 'package:racketmates/common/content/content_cache.dart';
import 'package:racketmates/common/content/content_repository.dart';
import 'package:racketmates/common/content/messages.dart';
import 'package:racketmates/common/content/reference_data.dart';
import 'package:racketmates/common/errors/app_failure.dart';

class ContentState {
  ContentState({
    this.messages = Messages.empty,
    this.preLogin = Messages.empty,
    ReferenceData? reference,
    this.cacheLoaded = false,
  }) : reference = reference ?? ReferenceData.empty;

  final Messages messages;
  final Messages preLogin;
  final ReferenceData reference;

  /// The persisted copies were read (even if there were none).
  final bool cacheLoaded;

  ContentState copyWith({
    Messages? messages,
    Messages? preLogin,
    ReferenceData? reference,
    bool? cacheLoaded,
  }) => ContentState(
    messages: messages ?? this.messages,
    preLogin: preLogin ?? this.preLogin,
    reference: reference ?? this.reference,
    cacheLoaded: cacheLoaded ?? this.cacheLoaded,
  );
}

/// Loads server-driven strings and reference data: cache first (so screens have
/// copy offline and instantly), then refresh when the metadata versions or the
/// language changed, or when nothing is cached.
class ContentController extends Notifier<ContentState> {
  @override
  ContentState build() => ContentState();

  ContentCache get _cache => ref.read(contentCacheProvider);

  ContentRepository get _repo => ref.read(contentRepositoryProvider);

  String get _language =>
      WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();

  Future<void> loadCache() async {
    final snapshot = await _cache.read();
    if (!ref.mounted) return;
    state = state.copyWith(
      messages: snapshot.messages == null ? null : Messages(snapshot.messages!),
      preLogin: snapshot.preLoginMessages == null
          ? null
          : Messages(snapshot.preLoginMessages!),
      reference: snapshot.referenceData == null
          ? null
          : ReferenceData.fromResponse(
              ReferenceDataResponse.fromJson({
                'reference_data': snapshot.referenceData,
              }),
            ),
      cacheLoaded: true,
    );
  }

  /// Refreshes whatever is stale given the server's [metadata] (null when the
  /// metadata could not be fetched: only fill in what is missing).
  Future<void> onMetadata(AppMetadata? metadata) async {
    final snapshot = await _cache.read();
    final languageChanged =
        snapshot.language != null && snapshot.language != _language;
    final messagesVersion = metadata?.resourceStringsLatestVersion;
    final referenceVersion = metadata?.referenceDataLastUpdated;
    final staleMessages =
        snapshot.messages == null ||
        languageChanged ||
        (messagesVersion != null &&
            messagesVersion != snapshot.messagesVersion);
    final staleReference =
        snapshot.referenceData == null ||
        languageChanged ||
        (referenceVersion != null &&
            referenceVersion != snapshot.referenceVersion);
    final stalePreLogin = snapshot.preLoginMessages == null || staleMessages;
    await refresh(
      messages: staleMessages,
      preLogin: stalePreLogin,
      reference: staleReference,
      messagesVersion: messagesVersion,
      referenceVersion: referenceVersion,
    );
  }

  /// Fetches the selected parts. A failure keeps the cached copy.
  Future<void> refresh({
    bool messages = true,
    bool preLogin = true,
    bool reference = true,
    int? messagesVersion,
    int? referenceVersion,
  }) async {
    await Future.wait([
      if (messages) _fetchMessages(messagesVersion),
      if (preLogin) _fetchPreLogin(),
      if (reference) _fetchReference(referenceVersion),
    ]);
  }

  Future<void> _fetchMessages(int? version) async {
    try {
      final tree = await _repo.messages();
      if (!ref.mounted) return;
      state = state.copyWith(messages: Messages(tree));
      await _cache.write(
        messages: tree,
        messagesVersion: version,
        language: _language,
      );
    } on AppFailure {
      // keep the cached strings
    }
  }

  Future<void> _fetchPreLogin() async {
    try {
      final tree = await _repo.preLoginMessages();
      if (!ref.mounted) return;
      state = state.copyWith(preLogin: Messages(tree));
      await _cache.write(preLoginMessages: tree, language: _language);
    } on AppFailure {
      // keep the cached strings
    }
  }

  Future<void> _fetchReference(int? version) async {
    try {
      final response = await _repo.referenceData();
      if (!ref.mounted) return;
      final data = ReferenceData.fromResponse(response);
      state = state.copyWith(reference: data);
      await _cache.write(
        referenceData: data.toJsonList(),
        referenceVersion: version,
        language: _language,
      );
    } on AppFailure {
      // keep the cached reference data
    }
  }
}

final contentCacheProvider = Provider<ContentCache>(
  (ref) => PrefsContentCache(),
);

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final config = ref.watch(environmentConfigProvider);
  return ContentRepositoryImpl(
    api: ContentApi(ref.watch(authDioProvider)),
    clientId: config.oauthClientId,
    clientSecret: config.oauthClientSecret,
  );
});

final contentControllerProvider =
    NotifierProvider<ContentController, ContentState>(ContentController.new);

/// Convenience selectors. Screens use
/// `ref.watch(messagesProvider).text(MessageKeys.x, l10n.fallback)`.
final messagesProvider = Provider<Messages>(
  (ref) => ref.watch(contentControllerProvider.select((s) => s.messages)),
);

final preLoginMessagesProvider = Provider<Messages>(
  (ref) => ref.watch(contentControllerProvider.select((s) => s.preLogin)),
);

final referenceDataProvider = Provider<ReferenceData>(
  (ref) => ref.watch(contentControllerProvider.select((s) => s.reference)),
);

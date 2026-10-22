import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/config/brand_config.dart';
import 'package:racketmates/app/app_resume_gate.dart';
import 'package:racketmates/app/notifications/notification_host.dart';
import 'package:racketmates/app/notifications/push_sync.dart';
import 'package:racketmates/app/router/app_router.dart';
import 'package:racketmates/app/theme/app_theme.dart';
import 'package:racketmates/common/chat/chat_controller.dart';
import 'package:racketmates/common/session/session_info_controller.dart';
import 'package:racketmates/l10n/app_localizations.dart';

final brandConfigProvider = Provider<BrandConfig>(
  (ref) => BrandConfig.racketmates,
);

class RacketmatesApp extends ConsumerWidget {
  const RacketmatesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    ref
      ..watch(sessionInfoSyncProvider) // keeps session_info current
      ..watch(pushSyncProvider) // device registration and notifications
      ..watch(chatSyncProvider); // Sendbird connection
    return MaterialApp.router(
      title: brand.displayName,
      theme: AppTheme.light(brand),
      darkTheme: AppTheme.dark(brand),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
      scaffoldMessengerKey: ref.watch(rootMessengerKeyProvider),
      builder: (context, child) => NotificationHost(
        child: AppResumeGate(child: child ?? const SizedBox()),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

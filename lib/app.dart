import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_navigator.dart';
import 'core/providers/l10n_providers.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/focus_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/date_time_formats.dart';
import 'core/widgets/event_detail_sheet.dart';
import 'core/widgets/notification_bootstrap.dart';
import 'features/shell/main_shell.dart';
import 'l10n/app_localizations.dart';

class SoftScheduleApp extends ConsumerWidget {
  const SoftScheduleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);
    final language = ref.watch(appLanguageProvider);

    ref.listen<int?>(pendingNotificationEventIdProvider, (prev, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationEvent(ref, next);
        });
      }
    });

    return MaterialApp(
      key: ValueKey('app-$language'),
      navigatorKey: rootNavigatorKey,
      title: 'Soft Schedule',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      locale: switch (language) {
        AppLanguage.zh => const Locale('zh'),
        AppLanguage.en => const Locale('en'),
        AppLanguage.system => null,
      },
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (locales, supported) {
        return resolveAppLocale(language);
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: NotificationBootstrap(
        child: MainShell(key: ValueKey('shell-$language')),
      ),
    );
  }

  Future<void> _handleNotificationEvent(WidgetRef ref, int eventId) async {
    ref.read(pendingNotificationEventIdProvider.notifier).state = null;
    ref.read(shellTabProvider.notifier).state = 0;

    final event = await ref.read(eventRepositoryProvider).getById(eventId);
    if (event == null) return;

    if (event.hasDate) {
      ref.read(homeSelectedDateProvider.notifier).state =
          DateTimeFormats.parseDate(event.date);
    }

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    await showEventDetailSheet(context: context, ref: ref, event: event);
  }
}

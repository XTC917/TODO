import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft_schedule/core/providers/app_providers.dart';
import 'package:soft_schedule/features/settings/default_reminder_settings_page.dart';
import 'package:soft_schedule/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to an at-time reminder when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(defaultReminderOffsetsProvider), [0]);
  });

  test('persists a chosen preset offset', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container
        .read(defaultReminderOffsetsProvider.notifier)
        .setOffsets(const [300]);

    expect(container.read(defaultReminderOffsetsProvider), [300]);
    expect(prefs.getString('default_reminder_offsets'), '[300]');
  });

  test('persists "no reminder" distinctly from the default', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container
        .read(defaultReminderOffsetsProvider.notifier)
        .setOffsets(const []);

    expect(container.read(defaultReminderOffsetsProvider), isEmpty);
    expect(prefs.getString('default_reminder_offsets'), 'none');

    final restored = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restored.dispose);
    expect(restored.read(defaultReminderOffsetsProvider), isEmpty);
  });

  testWidgets('page lists presets and saves the no-reminder choice',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DefaultReminderSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('\u51c6\u65f6'), findsOneWidget);
    expect(find.text('\u4e0d\u63d0\u9192'), findsOneWidget);

    await tester.tap(find.text('\u4e0d\u63d0\u9192'));
    await tester.pumpAndSettle();

    expect(prefs.getString('default_reminder_offsets'), 'none');
  });
}

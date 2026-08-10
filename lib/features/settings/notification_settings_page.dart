import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/reminder/reminder_log.dart';
import '../../core/reminder/reminder_native.dart';
import '../../core/services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/settings_widgets.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage>
    with WidgetsBindingObserver {
  bool _awaitingAutostartReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(notificationPermissionProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(notificationPermissionProvider);
      if (_awaitingAutostartReturn) {
        _awaitingAutostartReturn = false;
        unawaited(_markAutostartConfigured());
      }
      setState(() {});
    }
  }

  Future<void> _markAutostartConfigured() async {
    await ReminderNative.markAutostartConfigured(
      ref.read(sharedPreferencesProvider),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remindersEnabled = ref.watch(remindersEnabledProvider);
    final permissionAsync = ref.watch(notificationPermissionProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    return SettingsSubpageScaffold(
      title: l10n.settingsNotifications,
      body: SettingsGroup(
        children: [
          SwitchListTile(
            title: Text(l10n.enableReminders),
            value: remindersEnabled,
            onChanged: (v) =>
                ref.read(remindersEnabledProvider.notifier).setEnabled(v),
          ),
          permissionAsync.when(
            data: (granted) => _PermissionSection(
              granted: granted,
              showAutostartOnAndroid: Platform.isAndroid,
              autostartConfiguredFuture:
                  ReminderNative.isAutostartConfigured(prefs),
              onOpenNotificationSettings: () =>
                  _openSystemNotificationSettings(context),
              onRequestExactAlarm: () => _requestExactAlarm(context),
              onRequestBatteryOptimization: () =>
                  _requestBatteryOptimization(context),
              onOpenAutostartSettings: () => _openAutostartSettings(context),
            ),
            loading: () => const ListTile(title: Text('…')),
            error: (_, __) => ListTile(
              title: Text(l10n.notificationPermissionDenied),
              trailing: TextButton(
                onPressed: () => _openSystemNotificationSettings(context),
                child: Text(l10n.openNotificationSettings),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSystemNotificationSettings(BuildContext context) async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
    if (!mounted) return;
    await refreshNotificationPermission(ref);
    await _rescheduleIfEnabled();
    setState(() {});
  }

  Future<void> _requestExactAlarm(BuildContext context) async {
    reminderLog('settings exactAlarmPermission()');
    await NotificationService.instance.requestExactAlarmsPermission();
    if (!mounted) return;
    ref.invalidate(notificationPermissionProvider);
    setState(() {});
    await _rescheduleIfEnabled();
  }

  Future<void> _requestBatteryOptimization(BuildContext context) async {
    reminderLog('settings batteryOptimization()');
    await NotificationService.instance.requestIgnoreBatteryOptimization();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openAutostartSettings(BuildContext context) async {
    reminderLog('settings autostart openSettings()');
    _awaitingAutostartReturn = true;
    await ReminderNative.openAutostartSettings();
  }

  Future<void> _rescheduleIfEnabled() async {
    if (!ref.read(remindersEnabledProvider)) return;
    await NotificationService.instance.rescheduleAll(
      ref.read(eventRepositoryProvider),
    );
  }
}

class _PermissionSection extends StatelessWidget {
  const _PermissionSection({
    required this.granted,
    required this.showAutostartOnAndroid,
    required this.autostartConfiguredFuture,
    required this.onOpenNotificationSettings,
    required this.onRequestExactAlarm,
    required this.onRequestBatteryOptimization,
    required this.onOpenAutostartSettings,
  });

  final bool granted;
  final bool showAutostartOnAndroid;
  final Future<bool> autostartConfiguredFuture;
  final VoidCallback onOpenNotificationSettings;
  final VoidCallback onRequestExactAlarm;
  final VoidCallback onRequestBatteryOptimization;
  final VoidCallback onOpenAutostartSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.security_outlined, size: 22),
          title: Text(l10n.settingsNotificationPermission),
          subtitle: Text(
            granted
                ? l10n.notificationPermissionGranted
                : l10n.notificationPermissionDenied,
          ),
          trailing: granted
              ? Icon(Icons.check_circle_outline, color: theme.colorScheme.primary)
              : null,
        ),
        if (!granted)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FilledButton(
              onPressed: onOpenNotificationSettings,
              child: Text(l10n.openNotificationSettings),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.reminderSetupHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        if (granted) ...[
          FutureBuilder<bool>(
            future: NotificationService.instance.canScheduleExactAlarms(),
            builder: (context, snapshot) {
              if (snapshot.data != false) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.exactAlarmPermissionHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onRequestExactAlarm,
                      child: Text(l10n.requestExactAlarmPermission),
                    ),
                  ],
                ),
              );
            },
          ),
          FutureBuilder<bool>(
            future:
                NotificationService.instance.isBatteryOptimizationIgnored(),
            builder: (context, snapshot) {
              if (snapshot.data != false) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.batteryOptimizationHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onRequestBatteryOptimization,
                      child: Text(l10n.requestBatteryOptimization),
                    ),
                  ],
                ),
              );
            },
          ),
          if (showAutostartOnAndroid)
            FutureBuilder<bool>(
              future: autostartConfiguredFuture,
              builder: (context, snapshot) {
                if (snapshot.data == true) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.rocket_launch_outlined, size: 22),
                        title: Text(l10n.settingsAutostartPermission),
                        subtitle: Text(l10n.autostartPermissionNotConfigured),
                      ),
                      Text(
                        l10n.autostartPermissionHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: onOpenAutostartSettings,
                        child: Text(l10n.requestAutostartPermission),
                      ),
                    ],
                  ),
                );
              },
            ),
          FutureBuilder<int>(
            future: NotificationService.instance.pendingCount(),
            builder: (context, snapshot) {
              final count = snapshot.data;
              if (count == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.pendingNotifications(count),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

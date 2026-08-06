import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/reminder/reminder_log.dart';
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
  bool _schedulingTest = false;

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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remindersEnabled = ref.watch(remindersEnabledProvider);
    final permissionAsync = ref.watch(notificationPermissionProvider);

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
              schedulingTest: _schedulingTest,
              onRequestPermission: () => _requestPermission(context),
              onOpenSettings: () => _openSystemNotificationSettings(context),
              onRequestExactAlarm: () => _requestExactAlarm(context),
              onRequestBatteryOptimization: () =>
                  _requestBatteryOptimization(context),
              onScheduleTest: () => _scheduleTestReminder(context),
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

  Future<void> _requestPermission(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    reminderLog('settings requestPermission()');
    final granted = await NotificationService.instance
        .requestPermissionsWhenReady(force: true);
    if (!mounted) return;
    await refreshNotificationPermission(ref);
    if (granted) await _rescheduleIfEnabled();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? l10n.notificationPermissionGranted
              : l10n.testNotificationFailed,
        ),
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

  Future<void> _rescheduleIfEnabled() async {
    if (!ref.read(remindersEnabledProvider)) return;
    await NotificationService.instance.rescheduleAll(
      ref.read(eventRepositoryProvider),
    );
  }

  Future<void> _scheduleTestReminder(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _schedulingTest = true);
    TestNotificationResult result;
    try {
      result = await NotificationService.instance.showTestNotification();
    } finally {
      if (mounted) setState(() => _schedulingTest = false);
    }
    if (!mounted) return;

    final message = switch (result) {
      TestNotificationResult.success => l10n.testNotificationSuccess,
      TestNotificationResult.permissionDenied => l10n.testNotificationFailed,
      TestNotificationResult.notInitialized => l10n.testNotificationInitFailed,
      TestNotificationResult.timedOut => l10n.testNotificationTimedOut,
      TestNotificationResult.showFailed => l10n.testNotificationFailed,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
    setState(() {});
  }
}

class _PermissionSection extends StatelessWidget {
  const _PermissionSection({
    required this.granted,
    required this.schedulingTest,
    required this.onRequestPermission,
    required this.onOpenSettings,
    required this.onRequestExactAlarm,
    required this.onRequestBatteryOptimization,
    required this.onScheduleTest,
  });

  final bool granted;
  final bool schedulingTest;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;
  final VoidCallback onRequestExactAlarm;
  final VoidCallback onRequestBatteryOptimization;
  final VoidCallback onScheduleTest;

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
        if (!granted) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FilledButton(
              onPressed: onRequestPermission,
              child: Text(l10n.requestNotificationPermission),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: OutlinedButton(
              onPressed: onOpenSettings,
              child: Text(l10n.openNotificationSettings),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.reminderSetupHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: OutlinedButton.icon(
            onPressed: schedulingTest ? null : onScheduleTest,
            icon: schedulingTest
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.notifications_active),
            label: Text(
              schedulingTest
                  ? l10n.testNotificationSending
                  : l10n.testNotificationNow,
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

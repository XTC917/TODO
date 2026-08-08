import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'widgets/settings_widgets.dart';

class WidgetSettingsPage extends StatelessWidget {
  const WidgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SettingsSubpageScaffold(
      title: l10n.settingsWidgets,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.widgetSetupIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SettingsGroup(
            children: [
              _StepTile(number: 1, text: l10n.widgetSetupStep1),
              _StepTile(number: 2, text: l10n.widgetSetupStep2),
              _StepTile(number: 3, text: l10n.widgetSetupStep3),
              _StepTile(number: 4, text: l10n.widgetSetupStep4),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.widgetSetupTypesTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SettingsGroup(
            children: [
              _WidgetTypeTile(
                icon: Icons.checklist_rounded,
                title: l10n.widgetSetupTypeTodo,
                subtitle: l10n.widgetSetupTypeTodoHint,
              ),
              _WidgetTypeTile(
                icon: Icons.calendar_today_outlined,
                title: l10n.widgetSetupTypeSchedule,
                subtitle: l10n.widgetSetupTypeScheduleHint,
              ),
              _WidgetTypeTile(
                icon: Icons.timer_outlined,
                title: l10n.widgetSetupTypeFocus,
                subtitle: l10n.widgetSetupTypeFocusHint,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.widgetSetupToggleHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetTypeTile extends StatelessWidget {
  const _WidgetTypeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

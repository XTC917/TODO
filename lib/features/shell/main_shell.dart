import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/focus_providers.dart';
import '../../l10n/app_localizations.dart';
import '../calendar/calendar_page.dart';
import '../focus/focus_page.dart';
import '../home/home_page.dart';
import '../settings/settings_page.dart';
import '../statistics/statistics_page.dart';
import '../todo/todo_page.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _pages = <Widget>[
    HomePage(),
    TodoPage(),
    FocusPage(),
    CalendarPage(),
    StatisticsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellTabProvider);
    final immersive = ref.watch(focusImmersiveModeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: _pages,
      ),
      bottomNavigationBar: immersive
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) {
                ref.read(shellTabProvider.notifier).state = value;
              },
              destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist_rounded),
            label: l10n.navTodo,
          ),
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            selectedIcon: const Icon(Icons.timer_rounded),
            label: l10n.navFocus,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: l10n.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.navSettings,
          ),
              ],
            ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/schedule/event_form_page.dart';
import '../../models/enums.dart';
import '../navigation/app_navigator.dart';
import '../providers/app_providers.dart';
import '../providers/focus_providers.dart';
import '../utils/date_time_formats.dart';
import 'home_widget_keys.dart';
import 'home_widget_sync.dart';

void handleWidgetLaunch(WidgetRef ref, Uri? uri) {
  if (uri == null) return;
  if (uri.scheme != HomeWidgetUris.scheme) return;

  switch (uri.host) {
    case 'home':
      ref.read(shellTabProvider.notifier).state = 0;
    case 'todo':
      if (uri.path == '/toggle') {
        unawaited(_toggleTodoForeground(ref, uri));
      } else if (uri.path == '/add') {
        ref.read(shellTabProvider.notifier).state = 1;
        _pushEventForm(ref, TaskType.todo);
      } else {
        ref.read(shellTabProvider.notifier).state = 1;
      }
    case 'calendar':
      if (uri.path == '/add') {
        ref.read(shellTabProvider.notifier).state = 3;
        _pushEventForm(
          ref,
          TaskType.schedule,
          initialDate: DateTimeFormats.dateOnly(DateTime.now()),
        );
      } else {
        ref.read(shellTabProvider.notifier).state = 3;
      }
    case 'focus':
      ref.read(shellTabProvider.notifier).state = 2;
  }
}

void _pushEventForm(
  WidgetRef ref,
  TaskType taskType, {
  DateTime? initialDate,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventFormPage(
          forceTaskType: taskType,
          initialDate: initialDate,
        ),
      ),
    );
  });
}

Future<void> _toggleTodoForeground(WidgetRef ref, Uri uri) async {
  final id = int.tryParse(uri.queryParameters['id'] ?? '');
  if (id == null) return;
  final repo = ref.read(eventRepositoryProvider);
  final event = await repo.getById(id);
  if (event == null || !event.isTodo) return;
  await ref.read(eventActionsProvider).toggleTodo(id, !event.isCompleted);
  await ref.read(homeWidgetSyncProvider).syncNow();
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/schedule/event_form_page.dart';
import '../navigation/app_navigator.dart';
import '../providers/app_providers.dart';
import '../providers/focus_providers.dart';
import 'home_widget_keys.dart';
import 'home_widget_sync.dart';

void handleWidgetLaunch(WidgetRef ref, Uri? uri) {
  if (uri == null) return;
  if (uri.scheme != HomeWidgetUris.scheme) return;

  switch (uri.host) {
    case 'home':
      ref.read(shellTabProvider.notifier).state = 0;
      if (uri.path == '/add') {
        _pushEventForm(ref);
      }
    case 'todo':
      if (uri.path == '/toggle') {
        unawaited(_toggleFromWidget(ref, uri));
      } else if (uri.path == '/add') {
        ref.read(shellTabProvider.notifier).state = 1;
        _pushEventForm(ref);
      } else {
        ref.read(shellTabProvider.notifier).state = 1;
      }
    case 'calendar':
      if (uri.path == '/add') {
        ref.read(shellTabProvider.notifier).state = 0;
        _pushEventForm(ref);
      } else {
        ref.read(shellTabProvider.notifier).state = 3;
      }
    case 'focus':
      ref.read(shellTabProvider.notifier).state = 2;
  }
}

void _pushEventForm(WidgetRef ref, {DateTime? initialDate}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final selected = ref.read(homeSelectedDateProvider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventFormPage(
          initialDate: initialDate ?? selected,
        ),
      ),
    );
  });
}

Future<void> _toggleFromWidget(WidgetRef ref, Uri uri) async {
  final id = int.tryParse(uri.queryParameters['id'] ?? '');
  if (id == null) return;
  final repo = ref.read(eventRepositoryProvider);
  final event = await repo.getById(id);
  if (event == null) return;
  await ref.read(eventActionsProvider).toggleOccurrence(
        event,
        !event.isCompleted,
      );
  await ref.read(homeWidgetSyncProvider).syncNow();
}

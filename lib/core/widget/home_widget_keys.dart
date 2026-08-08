/// Shared preference keys for home screen widgets (Flutter ↔ Android Glance).
class HomeWidgetKeys {
  HomeWidgetKeys._();

  static const date = 'juju_date';
  static const todoDone = 'juju_todo_done';
  static const todoTotal = 'juju_todo_total';
  static const todosJson = 'juju_todos_json';
  static const schedulesJson = 'juju_schedules_json';
  static const focusSeconds = 'juju_focus_seconds';
  static const accentHex = 'juju_accent_hex';

  static const labelTodoTitle = 'juju_label_todo_title';
  static const labelScheduleTitle = 'juju_label_schedule_title';
  static const labelFocusTitle = 'juju_label_focus_title';
  static const labelStartFocus = 'juju_label_start_focus';
  static const labelEmpty = 'juju_label_empty';
  static const labelTodoProgress = 'juju_label_todo_progress';
  static const labelFocusDuration = 'juju_label_focus_duration';
  static const labelOpenFocus = 'juju_label_open_focus';

  static const androidTodoReceiver =
      'com.example.soft_schedule.widget.TodoWidgetReceiver';
  static const androidScheduleReceiver =
      'com.example.soft_schedule.widget.ScheduleWidgetReceiver';
  static const androidFocusReceiver =
      'com.example.soft_schedule.widget.FocusWidgetReceiver';
}

/// Deep-link URIs opened when a widget is tapped.
class HomeWidgetUris {
  HomeWidgetUris._();

  static const scheme = 'jujuschedule';
  static const home = '$scheme://home';
  static const todo = '$scheme://todo';
  static const calendar = '$scheme://calendar';
  static const focus = '$scheme://focus';
  static const todoAdd = '$scheme://todo/add';
  static const calendarAdd = '$scheme://calendar/add';
}

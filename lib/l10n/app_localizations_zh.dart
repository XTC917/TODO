// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'JUJU Schedule';

  @override
  String get navHome => '首页';

  @override
  String get navTodo => '待办';

  @override
  String get navFocus => '专注';

  @override
  String get navCalendar => '日历';

  @override
  String get navStats => '统计';

  @override
  String get navSettings => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get accentColor => '主题色';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get notifications => '通知';

  @override
  String get enableReminders => '开启提醒';

  @override
  String get notificationPermissionGranted => '通知权限已开启';

  @override
  String get notificationPermissionDenied => '通知权限未开启';

  @override
  String get openNotificationSettings => '前往系统通知设置';

  @override
  String get requestNotificationPermission => '允许通知';

  @override
  String get testNotificationNow => '发送测试通知';

  @override
  String get testNotificationSuccess => '测试通知已发送';

  @override
  String get testNotificationFailed => '无法发送通知，请检查权限和系统设置';

  @override
  String pendingNotifications(Object count) {
    return '已安排 $count 条提醒';
  }

  @override
  String get reminderSetupHint => '创建任务时点击「提醒」选择通知时间。';

  @override
  String get remindersDisabledHint => '已在设置中关闭提醒';

  @override
  String get exportDatabase => '导出数据库';

  @override
  String get importDatabase => '导入数据库';

  @override
  String get about => '关于';

  @override
  String aboutSubtitle(String version) {
    return 'Soft Schedule $version';
  }

  @override
  String get aboutLegalese => '个人日程本\n数据仅保存在本地';

  @override
  String exportSuccess(String path) {
    return '已导出：$path';
  }

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get importTitle => '导入数据库';

  @override
  String get importMessage => '这将替换所有现有数据，是否继续？';

  @override
  String get importSuccess => '导入成功';

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get cancel => '取消';

  @override
  String get import => '导入';

  @override
  String get save => '保存';

  @override
  String get create => '创建';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get copy => '复制';

  @override
  String get changeDate => '修改日期';

  @override
  String batchSelected(int count) {
    return '已选择 $count 项';
  }

  @override
  String get noTimeTasksCannotChangeDate => '无时间任务无法修改日期。';

  @override
  String get backToToday => '回到今天';

  @override
  String get today => '今天';

  @override
  String get swipeHint => '← 左右滑动切换日期 →';

  @override
  String get timeline => '时间轴';

  @override
  String get todaysTodo => '今日待办';

  @override
  String get todoSection => '待办';

  @override
  String completed(int count) {
    return '已完成 ($count)';
  }

  @override
  String longTermTasks(int count) {
    return '长期任务（$count）';
  }

  @override
  String get longTermTask => '长期任务';

  @override
  String get noTodosYet => '暂无待办';

  @override
  String get noTodosForDay => '当天暂无待办';

  @override
  String get noTimelineItems => '当天暂无时间安排';

  @override
  String get noTodos => '暂无待办';

  @override
  String loadFailed(String error) {
    return '加载失败：$error';
  }

  @override
  String errorGeneric(String error) {
    return '错误：$error';
  }

  @override
  String get titleRequired => '请输入任务标题。';

  @override
  String get saveFailedRetry => '保存失败，请稍后重试。';

  @override
  String get confirmDeleteTitle => '删除';

  @override
  String get confirmDeleteMessage => '确定删除此任务？';

  @override
  String get addTitle => '新建';

  @override
  String get editTitle => '编辑';

  @override
  String get titleLabel => '标题';

  @override
  String get typeLabel => '类型';

  @override
  String get taskTypeTodo => '待办';

  @override
  String get taskTypeSchedule => '日程';

  @override
  String get timeModeLabel => '时间模式';

  @override
  String get timeBlock => '时间段';

  @override
  String get deadline => '截止';

  @override
  String get noTime => '无时间';

  @override
  String get dateLabel => '日期';

  @override
  String get startLabel => '开始';

  @override
  String get endLabel => '结束';

  @override
  String get deadlineLabel => '截止时间';

  @override
  String get noteLabel => '备注';

  @override
  String get moreOptions => '更多选项';

  @override
  String get endTimeAfterStart => '结束时间必须晚于开始时间';

  @override
  String get detailType => '类型';

  @override
  String get detailDate => '日期';

  @override
  String get detailTime => '时间';

  @override
  String get detailNote => '备注';

  @override
  String get detailTodo => '待办';

  @override
  String get detailSchedule => '日程';

  @override
  String get markComplete => '标记完成';

  @override
  String get completedLabel => '已完成';

  @override
  String get deadlineBadge => '截止';

  @override
  String get relativeYesterday => '昨天';

  @override
  String get relativeToday => '今天';

  @override
  String get relativeTomorrow => '明天';

  @override
  String get weekdayMon => '周一';

  @override
  String get weekdayTue => '周二';

  @override
  String get weekdayWed => '周三';

  @override
  String get weekdayThu => '周四';

  @override
  String get weekdayFri => '周五';

  @override
  String get weekdaySat => '周六';

  @override
  String get weekdaySun => '周日';

  @override
  String get notificationUpcomingTodo => '即将开始的待办';

  @override
  String get notificationUpcomingSchedule => '即将开始的日程';

  @override
  String schedulesCount(int count) {
    return '$count 个日程';
  }

  @override
  String todosCount(int count) {
    return '$count 个待办';
  }

  @override
  String doneCount(int count) {
    return '已完成 $count';
  }

  @override
  String focusDuration(String duration) {
    return ' · 专注 $duration';
  }

  @override
  String get exportDialogTitle => '导出数据库';

  @override
  String get importDialogTitle => '导入数据库';

  @override
  String get repeatOneTime => '一次性';

  @override
  String get repeatDaily => '每天';

  @override
  String get repeatWeekly => '每周';

  @override
  String get repeatMonthly => '每月';

  @override
  String get reminderLabel => '提醒';

  @override
  String get reminderNone => '不提醒';

  @override
  String get reminderAtDueTime => '准时';

  @override
  String reminderMinutesBeforeDue(int count) {
    return '提前 $count 分钟';
  }

  @override
  String reminderHoursBeforeDue(int count) {
    return '提前 $count 小时';
  }

  @override
  String reminderDaysBeforeDue(int count) {
    return '提前 $count 天';
  }

  @override
  String get reminderCustomOption => '自定义…';

  @override
  String get reminderCustomTitle => '自定义提醒';

  @override
  String get reminderEnterAmount => '数量';

  @override
  String get reminderUnitMinutes => '分钟';

  @override
  String get reminderUnitHours => '小时';

  @override
  String get reminderUnitDays => '天';

  @override
  String get done => '完成';

  @override
  String timeUntilStart(String time) {
    return '距离开始还有 $time';
  }

  @override
  String get timeUntilStartNow => '即将开始';

  @override
  String timeUntilStartMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String timeUntilStartHours(int count) {
    return '$count 小时';
  }

  @override
  String timeUntilStartHoursMinutes(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String timeUntilStartDays(int count) {
    return '$count 天';
  }

  @override
  String timeUntilStartDaysHours(int days, int hours) {
    return '$days 天 $hours 小时';
  }

  @override
  String get detailTimeUntilStart => '距离开始';

  @override
  String get detailReminder => '提醒';

  @override
  String get focusTitle => '专注';

  @override
  String get focusPomodoro => '番茄钟';

  @override
  String get focusStopwatch => '正计时';

  @override
  String get focusStart => '开始';

  @override
  String get focusPause => '暂停';

  @override
  String get focusResume => '继续';

  @override
  String get focusEnd => '结束';

  @override
  String focusMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String focusCustom(int minutes) {
    return '自定义 $minutes';
  }

  @override
  String focusSaved(String duration) {
    return '已保存 $duration';
  }

  @override
  String get statsTitle => '统计';

  @override
  String get statsDay => '日';

  @override
  String get statsWeek => '周';

  @override
  String get statsDailyFocus => '每日专注';

  @override
  String get statsWeeklyFocus => '每周专注';

  @override
  String get statsDailyTodo => '每日待办完成率';

  @override
  String get statsWeeklyTodo => '每周完成率';

  @override
  String statsFocusLabel(String duration) {
    return '专注：$duration';
  }

  @override
  String statsTasksLabel(int done, int total) {
    return '任务：$done/$total';
  }

  @override
  String statsProgressLabel(int percent) {
    return '进度：$percent%';
  }

  @override
  String deadlineTime(String time) {
    return '截止 $time';
  }
}

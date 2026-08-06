// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'JUJU Schedule';

  @override
  String get navHome => '홈';

  @override
  String get navTodo => '할 일';

  @override
  String get navFocus => '집중';

  @override
  String get navCalendar => '캘린더';

  @override
  String get navStats => '통계';

  @override
  String get navSettings => '설정';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsAppearance => '모양';

  @override
  String get settingsNotifications => '알림';

  @override
  String get settingsFocus => '집중';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsGeneral => '일반';

  @override
  String get settingsAbout => '정보';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsStatusEnabled => '켜짐';

  @override
  String get settingsStatusDisabled => '꺼짐';

  @override
  String settingsVersionLabel(String version) {
    return '버전 $version';
  }

  @override
  String get settingsDefaultCountdown => '기본 카운트다운';

  @override
  String get settingsDefaultDisplayMode => '기본 표시 방식';

  @override
  String get settingsDisplayModeHour => '시간';

  @override
  String get settingsDisplayModeMinute => '분';

  @override
  String get settingsKeepScreenAwake => '화면 켜짐 유지';

  @override
  String get settingsKeepScreenAwakeHint => '집중 세션 중 화면이 꺼지지 않도록 합니다';

  @override
  String get settingsImmersiveModeHint => '실행 중인 타이머를 길게 눌러 몰입 모드로 들어갑니다.';

  @override
  String get settingsNotificationPermission => '알림 권한';

  @override
  String get settingsAppName => '앱 이름';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsGitHub => 'GitHub';

  @override
  String get settingsGitHubCopied => 'GitHub 링크가 복사되었습니다';

  @override
  String get settingsLicenses => '라이선스';

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsShowSampleData => '샘플 데이터 표시';

  @override
  String get settingsShowSampleDataHint => '앱을 빠르게 익히도록 내장 샘플 일정과 할 일을 표시합니다';

  @override
  String get settingsHideSampleDataTitle => '샘플 데이터를 숨길까요?';

  @override
  String get settingsHideSampleDataMessage =>
      '샘플 데이터만 숨겨지며, 본인의 일정과 할 일은 그대로 유지됩니다.';

  @override
  String get settingsHideSampleDataConfirm => '숨기기';

  @override
  String get demoSampleReadOnlyHint =>
      '샘플 항목은 읽기 전용입니다. 더 이상 필요 없으면 설정에서 샘플 데이터를 끌 수 있습니다.';

  @override
  String get demoScheduleWelcomeTitle => 'Welcome to JUJU Schedule 👋';

  @override
  String get demoScheduleWelcomeNote => 'Hope it helps you organize every day.';

  @override
  String get demoScheduleAddTitle => '오른쪽 하단 + 를 눌러 일정 추가';

  @override
  String get demoScheduleAddNote => '나만의 일정을 만들어 보세요.';

  @override
  String get demoScheduleDetailTitle => '카드를 눌러 상세 보기';

  @override
  String get demoScheduleDetailNote => '제목, 시간, 메모, 알림을 편집할 수 있습니다.';

  @override
  String get demoScheduleSwipeTitle => '왼쪽으로 밀어 빠른 편집';

  @override
  String get demoScheduleSwipeNote => '상세 페이지에서도 편집하거나 삭제할 수 있습니다.';

  @override
  String get demoScheduleReminderTitle => '알림 설정';

  @override
  String get demoScheduleReminderNote => '\"정시\" 또는 \"5분 전\"을 설정해 보세요.';

  @override
  String get demoScheduleHideTitle => '설정에서 샘플 데이터 끄기';

  @override
  String get demoScheduleHideNote => '언제든지 샘플 데이터를 숨기거나 다시 표시할 수 있습니다.';

  @override
  String get demoTodoWelcomeTitle => 'Welcome to JUJU Schedule 👋';

  @override
  String get demoTodoAddTitle => '오른쪽 하단 + 를 눌러 할 일 추가';

  @override
  String get demoTodoSwipeTitle => '왼쪽으로 밀어 할 일 빠른 편집';

  @override
  String get demoTodoThemeTitle => '테마 색상 변경';

  @override
  String get demoTodoLanguageTitle => '앱 언어 변경';

  @override
  String get demoTodoFocusTitle => '집중 세션 시작';

  @override
  String get demoTodoStatsTitle => '통계 페이지 보기';

  @override
  String get demoTodoHideTitle => '설정에서 샘플 데이터 끄기';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get accentColor => '강조 색상';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 설정 따름';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageKo => '한국어';

  @override
  String get notifications => '알림';

  @override
  String get enableReminders => '알림 켜기';

  @override
  String get notificationPermissionGranted => '알림 권한 허용됨';

  @override
  String get notificationPermissionDenied => '알림 권한 거부됨';

  @override
  String get openNotificationSettings => '알림 설정 열기';

  @override
  String get requestNotificationPermission => '알림 허용';

  @override
  String get testNotificationNow => '테스트 알림 보내기';

  @override
  String get testNotificationSuccess => '테스트 알림을 보냈습니다';

  @override
  String get testNotificationFailed => '알림을 보낼 수 없습니다. 권한과 시스템 설정을 확인하세요.';

  @override
  String pendingNotifications(Object count) {
    return '예약된 알림 $count개';
  }

  @override
  String get reminderSetupHint => '작업 생성 시 「알림」을 눌러 알림 시간을 선택하세요.';

  @override
  String get remindersDisabledHint => '설정에서 알림이 꺼져 있습니다';

  @override
  String get exportDatabase => '데이터베이스 내보내기';

  @override
  String get importDatabase => '데이터베이스 가져오기';

  @override
  String get about => '정보';

  @override
  String aboutSubtitle(String version) {
    return 'Soft Schedule $version';
  }

  @override
  String get aboutLegalese => '개인 일정장\n데이터는 기기에만 저장됩니다';

  @override
  String exportSuccess(String path) {
    return '내보냄: $path';
  }

  @override
  String exportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get importTitle => '데이터베이스 가져오기';

  @override
  String get importMessage => '모든 기존 데이터가 교체됩니다. 계속할까요?';

  @override
  String get importSuccess => '가져오기 성공';

  @override
  String importFailed(String error) {
    return '가져오기 실패: $error';
  }

  @override
  String get cancel => '취소';

  @override
  String get import => '가져오기';

  @override
  String get save => '저장';

  @override
  String get create => '만들기';

  @override
  String get delete => '삭제';

  @override
  String get edit => '편집';

  @override
  String get copy => '복사';

  @override
  String get changeDate => '날짜 변경';

  @override
  String batchSelected(int count) {
    return '$count개 선택됨';
  }

  @override
  String get noTimeTasksCannotChangeDate => '시간 없는 작업은 날짜를 변경할 수 없습니다.';

  @override
  String get backToToday => '오늘로';

  @override
  String get today => '오늘';

  @override
  String get swipeHint => '← 스와이프하여 날짜 변경 →';

  @override
  String get timeline => '타임라인';

  @override
  String get todaysTodo => '오늘 할 일';

  @override
  String get todoSection => '할 일';

  @override
  String completed(int count) {
    return '완료 ($count)';
  }

  @override
  String longTermTasks(int count) {
    return '장기 ($count)';
  }

  @override
  String get longTermTask => '장기 작업';

  @override
  String get noTodosYet => '할 일 없음';

  @override
  String get noTodosForDay => '이 날 할 일 없음';

  @override
  String get noTimelineItems => '이 날 일정 없음';

  @override
  String get noTodos => '할 일 없음';

  @override
  String loadFailed(String error) {
    return '불러오기 실패: $error';
  }

  @override
  String errorGeneric(String error) {
    return '오류: $error';
  }

  @override
  String get titleRequired => '작업 제목을 입력하세요.';

  @override
  String titleTooLong(int max) {
    return '제목은 $max자 이하여야 합니다.';
  }

  @override
  String noteTooLong(int max) {
    return '메모는 $max자 이하여야 합니다.';
  }

  @override
  String get saveFailedRetry => '저장 실패. 다시 시도하세요.';

  @override
  String get confirmDeleteTitle => '삭제';

  @override
  String get confirmDeleteMessage => '이 항목을 삭제할까요?';

  @override
  String get addTitle => '추가';

  @override
  String get editTitle => '편집';

  @override
  String get titleLabel => '제목';

  @override
  String get typeLabel => '유형';

  @override
  String get taskTypeTodo => '할 일';

  @override
  String get taskTypeSchedule => '일정';

  @override
  String get timeModeLabel => '시간 모드';

  @override
  String get timeBlock => '시간 블록';

  @override
  String get deadline => '마감';

  @override
  String get noTime => '시간 없음';

  @override
  String get dateLabel => '날짜';

  @override
  String get startLabel => '시작';

  @override
  String get endLabel => '종료';

  @override
  String get deadlineLabel => '마감 시간';

  @override
  String get noteLabel => '메모';

  @override
  String get moreOptions => '더보기';

  @override
  String get endTimeAfterStart => '종료 시간은 시작 시간보다 늦어야 합니다';

  @override
  String get detailType => '유형';

  @override
  String get detailDate => '날짜';

  @override
  String get detailTime => '시간';

  @override
  String get detailNote => '메모';

  @override
  String get detailTodo => '할 일';

  @override
  String get detailSchedule => '일정';

  @override
  String get markComplete => '완료로 표시';

  @override
  String get completedLabel => '완료됨';

  @override
  String get deadlineBadge => '마감';

  @override
  String get relativeYesterday => '어제';

  @override
  String get relativeToday => '오늘';

  @override
  String get relativeTomorrow => '내일';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get weekdaySun => '일';

  @override
  String get notificationUpcomingTodo => '곧 시작할 할 일';

  @override
  String get notificationUpcomingSchedule => '곧 시작할 일정';

  @override
  String schedulesCount(int count) {
    return '일정 $count개';
  }

  @override
  String todosCount(int count) {
    return '할 일 $count개';
  }

  @override
  String doneCount(int count) {
    return '완료 $count';
  }

  @override
  String focusDuration(String duration) {
    return ' · 집중 $duration';
  }

  @override
  String get exportDialogTitle => '데이터베이스 내보내기';

  @override
  String get importDialogTitle => '데이터베이스 가져오기';

  @override
  String get repeatOneTime => '한 번';

  @override
  String get repeatDaily => '매일';

  @override
  String get repeatWeekly => '매주';

  @override
  String get repeatMonthly => '매월';

  @override
  String get reminderLabel => '알림';

  @override
  String get reminderNone => '알림 없음';

  @override
  String get reminderAtDueTime => '정시';

  @override
  String reminderMinutesBeforeDue(int count) {
    return '$count분 전';
  }

  @override
  String reminderHoursBeforeDue(int count) {
    return '$count시간 전';
  }

  @override
  String reminderDaysBeforeDue(int count) {
    return '$count일 전';
  }

  @override
  String get reminderCustomOption => '사용자 지정…';

  @override
  String get reminderCustomTitle => '사용자 지정 알림';

  @override
  String get reminderEnterAmount => '수량';

  @override
  String get reminderUnitMinutes => '분';

  @override
  String get reminderUnitHours => '시간';

  @override
  String get reminderUnitDays => '일';

  @override
  String reminderSelectedCount(int count) {
    return '알림 $count개 선택됨';
  }

  @override
  String get done => '완료';

  @override
  String timeUntilStart(String time) {
    return '시작까지 $time';
  }

  @override
  String get timeUntilStartNow => '곧 시작';

  @override
  String timeUntilStartMinutes(int count) {
    return '$count분 후';
  }

  @override
  String timeUntilStartHours(int count) {
    return '$count시간 후';
  }

  @override
  String timeUntilStartHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분 후';
  }

  @override
  String timeUntilStartDays(int count) {
    return '$count일 후';
  }

  @override
  String timeUntilStartDaysHours(int days, int hours) {
    return '$days일 $hours시간 후';
  }

  @override
  String get detailTimeUntilStart => '시작까지';

  @override
  String get detailReminder => '알림';

  @override
  String get focusTitle => '집중';

  @override
  String get focusPomodoro => '뽀모도로';

  @override
  String get focusStopwatch => '스톱워치';

  @override
  String get focusStart => '시작';

  @override
  String get focusPause => '일시정지';

  @override
  String get focusResume => '계속';

  @override
  String get focusEnd => '종료';

  @override
  String focusMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String focusCustom(int minutes) {
    return '사용자 지정 $minutes';
  }

  @override
  String focusSaved(String duration) {
    return '저장됨 $duration';
  }

  @override
  String get focusSelectTask => '집중 작업 선택';

  @override
  String get focusTodayTasks => '오늘 일정 및 작업';

  @override
  String get focusNoTask => '미분류';

  @override
  String get focusCompletedTitle => '집중 완료 🎉';

  @override
  String get focusSummaryTask => '작업';

  @override
  String get focusSummaryDuration => '시간';

  @override
  String get focusSummaryStart => '시작';

  @override
  String get focusSummaryEnd => '종료';

  @override
  String get focusCustomDuration => '사용자 지정 시간';

  @override
  String get focusHoursLabel => '시간';

  @override
  String get focusMinutesFieldLabel => '분';

  @override
  String get focusAddPreset => '추가';

  @override
  String get focusTapToToggleDisplay => '탭하여 표시 전환';

  @override
  String get focusDoneDelete => '완료';

  @override
  String get focusCurrentTask => '작업 선택';

  @override
  String get focusCustomTaskHint => '사용자 지정 작업명 입력';

  @override
  String get focusUseCustomTask => '사용';

  @override
  String get focusCurrentFocus => '현재 집중';

  @override
  String get focusSelectTodo => '작업 선택';

  @override
  String get focusTaskModeCustom => '사용자 지정';

  @override
  String get focusImmersiveExit => '종료';

  @override
  String get focusLongPressImmersive => '타이머 길게 눌러 몰입 모드';

  @override
  String get focusViewRecords => '집중 기록 보기';

  @override
  String get focusRecordsTitle => '집중 기록';

  @override
  String get focusRecordsEmpty => '집중 기록이 없습니다';

  @override
  String get focusEditRecord => '집중 기록 편집';

  @override
  String get focusRecordTaskLabel => '작업 이름';

  @override
  String get focusRecordDate => '날짜';

  @override
  String get focusRecordStartTime => '시작 시간';

  @override
  String get focusRecordEndTime => '종료 시간';

  @override
  String focusDurationHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String focusDurationHours(int hours) {
    return '$hours시간';
  }

  @override
  String focusDurationMinutesOnly(int minutes) {
    return '$minutes분';
  }

  @override
  String get statsTitle => '통계';

  @override
  String get statsDay => '일';

  @override
  String get statsWeek => '주';

  @override
  String get statsMonth => '월';

  @override
  String get statsYear => '년';

  @override
  String get statsOverview => '개요';

  @override
  String get statsCompleted => '완료';

  @override
  String get statsPending => '대기';

  @override
  String get statsFocusTime => '집중 시간';

  @override
  String get statsFocusRanking => '집중 순위';

  @override
  String get statsViewAll => '전체 보기 >';

  @override
  String get statsMonthlyFocus => '월별 집중';

  @override
  String get statsThisWeek => '이번 주';

  @override
  String get statsLastWeek => '지난 주';

  @override
  String get statsNextWeek => '다음 주';

  @override
  String get statsFocus => '집중';

  @override
  String statsSessionsCount(int count) {
    return '세션 $count';
  }

  @override
  String statsSessionDetail(String start, String end, String duration) {
    return '$start–$end  $duration';
  }

  @override
  String get statsRankingEmpty => '집중 기록 없음';

  @override
  String get statsDailyFocus => '일별 집중';

  @override
  String get statsWeeklyFocus => '주별 집중';

  @override
  String get statsDailyTodo => '일별 할 일 완료율';

  @override
  String get statsWeeklyTodo => '주별 완료율';

  @override
  String statsFocusLabel(String duration) {
    return '집중: $duration';
  }

  @override
  String statsTasksLabel(int done, int total) {
    return '작업: $done/$total';
  }

  @override
  String statsProgressLabel(int percent) {
    return '진행: $percent%';
  }

  @override
  String deadlineTime(String time) {
    return '마감 $time';
  }
}

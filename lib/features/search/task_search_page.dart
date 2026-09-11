import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/focus_providers.dart';
import '../../core/utils/date_time_formats.dart';
import '../../core/utils/event_display.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import 'task_search_providers.dart';
import 'task_search_service.dart';

/// Shared entry button for the unified task search.
///
/// Small and quiet by design: plain search icon, no background, so it fits
/// into existing headers without stealing focus.
class TaskSearchButton extends StatelessWidget {
  const TaskSearchButton({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _tooltip(context),
      icon: Icon(Icons.search_rounded, size: size),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: () => openTaskSearch(context),
    );
  }

  String _tooltip(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'zh':
        return '搜索任务';
      case 'ko':
        return '작업 검색';
      default:
        return 'Search tasks';
    }
  }
}

Future<void> openTaskSearch(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const TaskSearchPage()),
  );
}

/// Unified search across all tasks/events. Entered from Todo, Schedule
/// (Home timeline) and Calendar via [TaskSearchButton].
class TaskSearchPage extends ConsumerStatefulWidget {
  const TaskSearchPage({super.key});

  @override
  ConsumerState<TaskSearchPage> createState() => _TaskSearchPageState();
}

class _TaskSearchPageState extends ConsumerState<TaskSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  TaskSearchStatusFilter _status = TaskSearchStatusFilter.all;
  TaskSearchTypeFilter _type = TaskSearchTypeFilter.all;
  TaskSearchTimeFilter _time = TaskSearchTimeFilter.all;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final eventsAsync = ref.watch(allEventsForSearchProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Centered, self-contained search bar: leaves natural margins on
            // both sides instead of stretching edge to edge.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    icon: const Icon(Icons.arrow_back_rounded),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Material(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: true,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: _hintText(context),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              hintStyle:
                                  theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface
                                    .withValues(alpha: 0.45),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              suffixIcon: _query.isEmpty &&
                                      _controller.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip:
                                          MaterialLocalizations.of(context)
                                              .deleteButtonTooltip,
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: _clear,
                                    ),
                            ),
                            style: theme.textTheme.bodyMedium,
                            onChanged: _onChanged,
                            onSubmitted: (v) {
                              _debounce?.cancel();
                              setState(() => _query = v.trim());
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _FilterBar(
              status: _status,
              type: _type,
              time: _time,
              onStatus: (v) => setState(() => _status = v),
              onType: (v) => setState(() => _type = v),
              onTime: (v) => setState(() => _time = v),
            ),
            Expanded(
              child: eventsAsync.when(
                data: (events) => _SearchBody(
                  query: _query,
                  events: events,
                  status: _status,
                  type: _type,
                  time: _time,
                  onJump: (result) =>
                      _jumpToCalendarDate(context, ref, result),
                ),
                loading: () => const Center(
                    child: CircularProgressIndicator.adaptive()),
                error: (e, _) =>
                    Center(child: Text(l10n.errorGeneric('$e'))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hintText(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'zh':
        return '搜索任务…';
      case 'ko':
        return '작업 검색…';
      default:
        return 'Search tasks…';
    }
  }

  void _jumpToCalendarDate(
    BuildContext context,
    WidgetRef ref,
    TaskSearchResult result,
  ) {
    // Each result carries its own occurrence date, so recurring hits land on
    // the tapped day — never the series start or "next" occurrence.
    final target = DateTimeFormats.dateOnly(result.targetDate);
    ref.read(calendarSelectedDateProvider.notifier).state = target;
    ref.read(calendarFocusedMonthProvider.notifier).state =
        DateTime(target.year, target.month);
    ref.read(homeSelectedDateProvider.notifier).state = target;
    ref.read(shellTabProvider.notifier).state = 3;
    Navigator.of(context).pop();
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.status,
    required this.type,
    required this.time,
    required this.onStatus,
    required this.onType,
    required this.onTime,
  });

  final TaskSearchStatusFilter status;
  final TaskSearchTypeFilter type;
  final TaskSearchTimeFilter time;
  final ValueChanged<TaskSearchStatusFilter> onStatus;
  final ValueChanged<TaskSearchTypeFilter> onType;
  final ValueChanged<TaskSearchTimeFilter> onTime;

  @override
  Widget build(BuildContext context) {
    String label(String zh, String en, String ko) {
      return switch (Localizations.localeOf(context).languageCode) {
        'zh' => zh,
        'ko' => ko,
        _ => en,
      };
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          _FilterRow<TaskSearchStatusFilter>(
            label: label('状态', 'Status', '상태'),
            values: TaskSearchStatusFilter.values,
            selected: status,
            onSelected: onStatus,
            text: (v) => switch (v) {
              TaskSearchStatusFilter.all => label('全部', 'All', '전체'),
              TaskSearchStatusFilter.incomplete =>
                label('未完成', 'Open', '미완료'),
              TaskSearchStatusFilter.completed =>
                label('已完成', 'Done', '완료'),
            },
          ),
          const SizedBox(height: 4),
          _FilterRow<TaskSearchTypeFilter>(
            label: label('类型', 'Type', '유형'),
            values: TaskSearchTypeFilter.values,
            selected: type,
            onSelected: onType,
            text: (v) => switch (v) {
              TaskSearchTypeFilter.all => label('全部', 'All', '전체'),
              TaskSearchTypeFilter.todo => label('待办', 'Todo', '할 일'),
              TaskSearchTypeFilter.schedule =>
                label('日程', 'Schedule', '일정'),
            },
          ),
          const SizedBox(height: 4),
          _FilterRow<TaskSearchTimeFilter>(
            label: label('时间', 'Time', '시간'),
            values: TaskSearchTimeFilter.values,
            selected: time,
            onSelected: onTime,
            text: (v) => switch (v) {
              TaskSearchTimeFilter.all => label('全部', 'All', '전체'),
              TaskSearchTimeFilter.future => label('将来', 'Future', '이후'),
              TaskSearchTimeFilter.past => label('过去', 'Past', '이전'),
            },
          ),
        ],
      ),
    );
  }
}

class _FilterRow<T> extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.text,
  });

  final String label;
  final List<T> values;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T value) text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final v in values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterChip(
                      label: text(v),
                      selected: v == selected,
                      onTap: () => onSelected(v),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.16)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                )
              : null,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.query,
    required this.events,
    required this.status,
    required this.type,
    required this.time,
    required this.onJump,
  });

  final String query;
  final List<Event> events;
  final TaskSearchStatusFilter status;
  final TaskSearchTypeFilter type;
  final TaskSearchTimeFilter time;
  final ValueChanged<TaskSearchResult> onJump;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return _HintState(hint: _initialHint(context));
    }
    final results = TaskSearchService.search(
      events,
      query,
      status: status,
      type: type,
      time: time,
    );
    if (results.isEmpty) {
      return _HintState(hint: _emptyHint(context));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        return _SearchResultTile(
          result: results[index],
          query: query,
          onTap: () => onJump(results[index]),
        );
      },
    );
  }

  String _initialHint(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'zh':
        return '输入标题或备注关键词搜索全部任务';
      case 'ko':
        return '제목 또는 메모 키워드로 모든 작업을 검색하세요';
      default:
        return 'Type a title or note keyword to search all tasks';
    }
  }

  String _emptyHint(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'zh':
        return '没有找到任务';
      case 'ko':
        return '작업을 찾을 수 없습니다';
      default:
        return 'No tasks found';
    }
  }
}

class _HintState extends StatelessWidget {
  const _HintState({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 36,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
            ),
            const SizedBox(height: 12),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.query,
    required this.onTap,
  });

  final TaskSearchResult result;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final event = result.event;
    final l10n = AppLocalizations.of(context);
    final dateLine = _dateLine(event, result, l10n);

    return Material(
      color: theme.cardTheme.color ?? scheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 40,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(
                      alpha: event.isCompleted ? 0.35 : 1,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HighlightedText(
                        text: event.title,
                        query: result.titleMatched ? query : '',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          decoration: event.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: event.isCompleted
                              ? scheme.onSurface.withValues(alpha: 0.45)
                              : null,
                        ),
                      ),
                      if (dateLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          dateLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                      if (result.noteSnippet != null) ...[
                        const SizedBox(height: 2),
                        _HighlightedText(
                          text: result.noteSnippet!,
                          query: result.noteMatched ? query : '',
                          maxLines: 2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: scheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateLine(Event event, TaskSearchResult result, AppLocalizations l10n) {
    final target = DateTimeFormats.dateOnly(result.targetDate);
    final datePart = DateTimeFormats.formatSectionDate(target, l10n);
    final timePart = eventTimeLabel(event, l10n);
    if (timePart.isEmpty) return datePart;
    return '$datePart · $timePart';
  }
}

/// Lightweight keyword highlight that follows the current theme.
///
/// Splits on the first case-insensitive occurrence only; intentionally cheap
/// so typing stays smooth. Falls back to plain text when there is no match.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();
    if (q.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final idx = text.toLowerCase().indexOf(q.toLowerCase());
    if (idx < 0) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + q.length),
            style: TextStyle(
              backgroundColor: scheme.primary.withValues(alpha: 0.22),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (idx + q.length < text.length)
            TextSpan(text: text.substring(idx + q.length)),
        ],
        style: style,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

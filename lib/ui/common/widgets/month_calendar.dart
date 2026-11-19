import 'package:flutter/material.dart';

import 'app_section.dart';

/// A month grid with a dot on the days that have something on them.
///
/// Shared by both sides of booking: the doctor publishes times on it and the
/// patient picks from them, and the two must agree about which day a slot falls
/// on or the calendar lies to one of them.
///
/// # Why not a calendar package
///
/// Month and weekday names come from [MaterialLocalizations], which
/// `flutter_localizations` already provides in both languages this app ships.
/// `intl`'s `DateFormat` would need `initializeDateFormatting` called at
/// startup — which nothing in this app does — and would silently fall back to
/// English until it was. A package would add a dependency for a grid that is
/// this much code.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onMonthChanged,
    this.markerCount,
    this.markerColor,
    this.isSelectable,
    this.firstMonth,
    this.lastMonth,
  });

  /// Any date inside the month being shown.
  final DateTime month;

  /// The day currently picked out, or null for none.
  final DateTime? selectedDay;

  final ValueChanged<DateTime> onSelectDay;

  /// Called with the first of the month to move to.
  final ValueChanged<DateTime> onMonthChanged;

  /// How many things sit on a given day. Zero draws no dot.
  final int Function(DateTime day)? markerCount;

  /// What the dot on a given day should mean, by colour. Defaults to the
  /// primary colour. Used by the doctor's calendar to tell a day that has a
  /// booking on it from one offering only free times — never as the sole
  /// signal, since the day's slots are listed underneath either way.
  final Color? Function(DateTime day)? markerColor;

  /// Whether a day can be picked at all. Defaults to every day.
  final bool Function(DateTime day)? isSelectable;

  final DateTime? firstMonth;
  final DateTime? lastMonth;

  static DateTime _firstOf(DateTime date) => DateTime(date.year, date.month);

  /// Midnight local, which is how a day is compared everywhere here.
  static DateTime dayOf(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final shown = _firstOf(month);

    final canGoBack =
        firstMonth == null || shown.isAfter(_firstOf(firstMonth!));
    final canGoForward =
        lastMonth == null || shown.isBefore(_firstOf(lastMonth!));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: localizations.previousMonthTooltip,
              onPressed: canGoBack
                  ? () => onMonthChanged(DateTime(shown.year, shown.month - 1))
                  : null,
            ),
            Expanded(
              child: Text(
                localizations.formatMonthYear(shown),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: localizations.nextMonthTooltip,
              onPressed: canGoForward
                  ? () => onMonthChanged(DateTime(shown.year, shown.month + 1))
                  : null,
            ),
          ],
        ),
        _WeekdayHeader(localizations: localizations),
        const AppGap.xs(),
        _DayGrid(
          month: shown,
          selectedDay: selectedDay == null ? null : dayOf(selectedDay!),
          onSelectDay: onSelectDay,
          markerCount: markerCount,
          markerColor: markerColor,
          isSelectable: isSelectable,
          firstDayOfWeekIndex: localizations.firstDayOfWeekIndex,
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.localizations});

  final MaterialLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = localizations.firstDayOfWeekIndex;

    return Row(
      children: [
        for (var offset = 0; offset < 7; offset++)
          Expanded(
            child: Center(
              child: Text(
                localizations.narrowWeekdays[(first + offset) % 7],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.selectedDay,
    required this.onSelectDay,
    required this.markerCount,
    required this.markerColor,
    required this.isSelectable,
    required this.firstDayOfWeekIndex,
  });

  final DateTime month;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final int Function(DateTime day)? markerCount;
  final Color? Function(DateTime day)? markerColor;
  final bool Function(DateTime day)? isSelectable;

  /// 0 is Sunday, as [MaterialLocalizations] counts it.
  final int firstDayOfWeekIndex;

  /// How many blank cells come before the 1st.
  ///
  /// `DateTime.weekday` counts Monday as 1; `firstDayOfWeekIndex` counts Sunday
  /// as 0. Both are shifted to Monday-as-0 before subtracting, which is what
  /// keeps the grid right in locales that start the week on Sunday.
  int get _leadingBlanks {
    final weekdayFromMonday = month.weekday - 1;
    final firstFromMonday = (firstDayOfWeekIndex - 1) % 7;
    return (weekdayFromMonday - firstFromMonday) % 7;
  }

  /// Day 0 of the next month is the last day of this one.
  int get _daysInMonth => DateTime(month.year, month.month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final today = MonthCalendar.dayOf(DateTime.now());
    final cells = <Widget>[
      for (var i = 0; i < _leadingBlanks; i++) const SizedBox.shrink(),
      for (var day = 1; day <= _daysInMonth; day++)
        _DayCell(
          date: DateTime(month.year, month.month, day),
          today: today,
          selectedDay: selectedDay,
          markerCount: markerCount,
          markerColor: markerColor,
          isSelectable: isSelectable,
          onSelectDay: onSelectDay,
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      // Slightly taller than wide, to leave room under the number for the dot
      // without squeezing the tap target.
      childAspectRatio: 0.85,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.today,
    required this.selectedDay,
    required this.markerCount,
    required this.markerColor,
    required this.isSelectable,
    required this.onSelectDay,
  });

  final DateTime date;
  final DateTime today;
  final DateTime? selectedDay;
  final int Function(DateTime day)? markerCount;
  final Color? Function(DateTime day)? markerColor;
  final bool Function(DateTime day)? isSelectable;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final selectable = isSelectable?.call(date) ?? true;
    final selected = selectedDay != null && selectedDay == date;
    final isToday = date == today;
    final markers = markerCount?.call(date) ?? 0;

    final Color foreground;
    if (selected) {
      foreground = scheme.onPrimary;
    } else if (!selectable) {
      foreground = scheme.onSurface.withValues(alpha: 0.38);
    } else {
      foreground = scheme.onSurface;
    }

    return Center(
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: selectable ? () => onSelectDay(date) : null,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.primary : null,
            border: isToday && !selected
                ? Border.all(color: scheme.primary, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${date.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: selected || isToday ? FontWeight.w600 : null,
                ),
              ),
              // A dot, not colour alone: the difference between a day with
              // times on it and one without has to survive both a colour
              // deficiency and a greyscale screen. Where the dot is *also*
              // coloured it carries a second meaning, but never the only one —
              // the day's contents are listed below the calendar regardless.
              SizedBox(
                height: 6,
                child: markers > 0
                    ? Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? scheme.onPrimary
                              : (markerColor?.call(date) ?? scheme.primary),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

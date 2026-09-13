import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

enum _Day { now, today, tomorrow }

const _dayLabels = {
  _Day.now: 'Nyt',
  _Day.today: 'Tänään',
  _Day.tomorrow: 'Huomenna',
};

const _minuteStep = 5;

/// Result of the departure-time sheet. [departAt] is null for "leave now".
typedef DepartureChoice = ({DateTime? departAt});

/// Asks for a departure time: now, or a clock time today or tomorrow.
/// Returns null when the user dismisses the sheet.
///
/// A time wheel and day buttons instead of the Material pickers: the app has
/// no Finnish Material localizations, and those pickers would show English.
Future<DepartureChoice?> showDepartureTimeSheet(
  BuildContext context, {
  DateTime? current,
}) {
  return showModalBottomSheet<DepartureChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (_) => _DepartureTimeSheet(current: current),
  );
}

/// First selectable departure: the next full step of [_minuteStep] minutes
/// after now.
DateTime _earliest() {
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  return base.add(Duration(minutes: _minuteStep - base.minute % _minuteStep));
}

class _DepartureTimeSheet extends StatefulWidget {
  final DateTime? current;
  const _DepartureTimeSheet({this.current});

  @override
  State<_DepartureTimeSheet> createState() => _DepartureTimeSheetState();
}

class _DepartureTimeSheetState extends State<_DepartureTimeSheet> {
  late _Day _day;
  // Clock part of the choice. The day comes from [_day].
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    final earliest = _earliest();
    if (current == null || current.isBefore(earliest)) {
      _day = _Day.now;
      _hour = earliest.hour;
      _minute = earliest.minute;
    } else {
      final now = DateTime.now();
      final isToday = current.year == now.year &&
          current.month == now.month &&
          current.day == now.day;
      _day = isToday ? _Day.today : _Day.tomorrow;
      _hour = current.hour;
      _minute = current.minute - current.minute % _minuteStep;
    }
  }

  /// The chosen departure, never earlier than [earliest].
  DateTime _selected(DateTime earliest) {
    final now = DateTime.now();
    final offset = _day == _Day.tomorrow ? 1 : 0;
    final picked =
        DateTime(now.year, now.month, now.day + offset, _hour, _minute);
    return picked.isBefore(earliest) ? earliest : picked;
  }

  @override
  Widget build(BuildContext context) {
    // One value per build, so that the wheel's initial and minimum times
    // always agree.
    final earliest = _earliest();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lähtöaika',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                for (final (i, day) in _Day.values.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DayButton(
                      label: _dayLabels[day]!,
                      active: _day == day,
                      onTap: () => setState(() => _day = day),
                    ),
                  ),
                ],
              ],
            ),
            if (_day != _Day.now) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 180,
                child: CupertinoDatePicker(
                  // New picker per day: it reads initialDateTime and
                  // minimumDate only when it is created.
                  key: ValueKey(_day),
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  minuteInterval: _minuteStep,
                  initialDateTime: _selected(earliest),
                  minimumDate: _day == _Day.today ? earliest : null,
                  onDateTimeChanged: (t) => setState(() {
                    _hour = t.hour;
                    _minute = t.minute;
                  }),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
              onPressed: () => Navigator.pop<DepartureChoice>(
                context,
                (departAt: _day == _Day.now ? null : _selected(_earliest())),
              ),
              child: Text(
                'Valmis',
                style:
                    AppTextStyles.screenTitle.copyWith(color: AppColors.textWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DayButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryLight : AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.itemTitle.copyWith(
              color: active ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

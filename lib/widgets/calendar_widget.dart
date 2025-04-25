import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calenapp/models/event.dart'; //

class CalendarWidget extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final Map<DateTime, List<Event>> events;
  final Function(DateTime) onDaySelected;
  final Function(DateTime) onAddEvent;

  const CalendarWidget({
    Key? key,
    required this.selectedDay,
    required this.focusedDay,
    required this.events,
    required this.onDaySelected,
    required this.onAddEvent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TableCalendar<Event>(
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      eventLoader:
          (day) => events[DateTime.utc(day.year, day.month, day.day)] ?? [],
      onDaySelected: (selectedDay, focusedDay) {
        onDaySelected(selectedDay);
      },
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true),
    );
  }
}

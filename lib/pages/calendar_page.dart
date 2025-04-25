import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calenapp/models/event.dart'; // Asegúrate de importar la clase Event

class CalendarPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const CalendarPage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final Map<DateTime, List<Event>> _events = {};
  DateTime? _lastTappedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _focusedDay = _selectedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      final decoded = jsonDecode(eventsJson) as List;
      setState(() {
        _events.clear();
        for (var dayData in decoded) {
          final day = DateTime.parse(dayData['day']);
          final events =
              (dayData['events'] as List).map((e) => Event.fromMap(e)).toList();
          _events[day] = events;
        }
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsList =
        _events.entries
            .map(
              (entry) => {
                'day': entry.key.toIso8601String(),
                'events': entry.value.map((e) => e.toMap()).toList(),
              },
            )
            .toList();
    await prefs.setString('events', jsonEncode(eventsList));
  }

  void _deleteEvent(Event event) async {
    final key = DateTime.utc(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    setState(() => _events[key]?.remove(event));
    await _saveEvents();
  }

  Future<void> _addEventDialog(DateTime day) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Añadir evento"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Título'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Descripción'),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Hora: ${selectedTime.format(context)}'),
                      Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setState(() => selectedTime = picked);
                          }
                        },
                        child: Text('Seleccionar hora'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancelar'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text('Añadir'),
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('El título es obligatorio')),
                    );
                    return;
                  }
                  final event = Event(
                    title: titleController.text,
                    description: descriptionController.text,
                    time: selectedTime,
                  );
                  final key = DateTime.utc(day.year, day.month, day.day);
                  setState(() => _events[key] = [..._events[key] ?? [], event]);
                  await _saveEvents();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final currentMonthColor = widget.isDarkMode ? Colors.white : Colors.black;
    final otherMonthColor = widget.isDarkMode ? Colors.white54 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text("Calendario"),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader:
                (day) =>
                    _events[DateTime.utc(day.year, day.month, day.day)] ?? [],
            onDaySelected: (selectedDay, focusedDay) {
              final normalizedDay = DateTime.utc(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              final isDifferentMonth = !isSameMonth(_focusedDay, selectedDay);

              setState(() {
                if (isDifferentMonth) {
                  _focusedDay = selectedDay;
                }

                // Si es el mismo día seleccionado previamente, abre diálogo
                if (isSameDay(_selectedDay, normalizedDay)) {
                  _addEventDialog(normalizedDay);
                } else {
                  // Si es un día diferente, solo selecciona
                  _selectedDay = normalizedDay;
                }
              });
            },
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: currentMonthColor),
              weekendTextStyle: TextStyle(color: currentMonthColor),
              outsideTextStyle: TextStyle(color: otherMonthColor),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: textColor),
              leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
              rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: textColor),
              weekendStyle: TextStyle(color: textColor),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount:
                  _events[DateTime.utc(
                        _selectedDay.year,
                        _selectedDay.month,
                        _selectedDay.day,
                      )]
                      ?.length ??
                  0,
              itemBuilder: (context, index) {
                final event =
                    _events[DateTime.utc(
                      _selectedDay.year,
                      _selectedDay.month,
                      _selectedDay.day,
                    )]![index];
                return ListTile(
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.description} • ${event.time.format(context)}',
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEvent(event),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEventDialog(_selectedDay),
        child: Icon(Icons.add),
      ),
    );
  }

  bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(MyApp());
}

class Event {
  final String title;
  final String description;
  final TimeOfDay time;

  Event({required this.title, required this.description, required this.time});

  Map<String, dynamic> toMap(BuildContext context) {
    return {
      'title': title,
      'description': description,
      'time': time.format(context),
    };
  }

  static Event fromMap(Map<String, dynamic> map, BuildContext context) {
    final timeParts = map['time'].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final time = TimeOfDay(hour: hour, minute: minute);

    return Event(
      title: map['title'],
      description: map['description'],
      time: time,
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: CalendarPage(
        toggleTheme: () {
          setState(() {
            isDarkMode = !isDarkMode;
          });
        },
        isDarkMode: isDarkMode,
      ),
    );
  }
}

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
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final Map<DateTime, List<Event>> _events = {};

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _addEventDialog(DateTime day) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                          setState(() {
                            selectedTime =
                                picked; // Actualiza la hora cuando el usuario selecciona
                          });
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
              onPressed: () {
                final event = Event(
                  title: titleController.text,
                  description: descriptionController.text,
                  time: selectedTime,
                );
                final key = DateTime.utc(day.year, day.month, day.day);
                if (_events.containsKey(key)) {
                  _events[key]!.add(event);
                } else {
                  _events[key] = [event];
                }

                // Guardar los eventos y luego recargarlos
                _saveEvents(); // Guardar
                _loadEvents(); // Recargar para reflejar cambios

                setState(() {});
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsList =
        _events.entries
            .map((entry) {
              final eventDay = entry.key;
              return entry.value
                  .map(
                    (event) => {
                      'day': eventDay.toIso8601String(),
                      ...event.toMap(context),
                    },
                  )
                  .toList();
            })
            .expand((x) => x) // Flatten the list of events
            .toList();
    final eventsJson = jsonEncode(eventsList);

    // Depuración: Verificar que los eventos se están guardando correctamente
    print("Eventos a guardar: $eventsJson");

    await prefs.setString('events', eventsJson);
  }

  void _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      final List<dynamic> decodedEvents = jsonDecode(eventsJson);
      final Map<DateTime, List<Event>> loadedEvents = {};
      for (var eventData in decodedEvents) {
        final day = DateTime.parse(eventData['day']);
        final event = Event.fromMap(eventData, context);
        if (loadedEvents.containsKey(day)) {
          loadedEvents[day]!.add(event);
        } else {
          loadedEvents[day] = [event];
        }
      }

      // Depuración: Verificar que los eventos se están cargando correctamente
      print("Eventos cargados: $loadedEvents");

      setState(() {
        _events.addAll(loadedEvents);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEvents(); // Cargar eventos al iniciar
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;

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
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              final sameDay = isSameDay(_selectedDay, selectedDay);
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = selectedDay;
              });
              if (sameDay) {
                _addEventDialog(selectedDay);
              }
            },
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: textColor),
              weekendTextStyle: TextStyle(color: textColor),
              outsideTextStyle: TextStyle(color: textColor.withOpacity(0.5)),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
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
          const SizedBox(height: 8),
          ..._getEventsForDay(_selectedDay).map(
            (event) => ListTile(
              title: Text(event.title),
              subtitle: Text(
                '${event.description} • ${event.time.format(context)}',
              ),
              leading: Icon(Icons.event),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEventDialog(_selectedDay),
        tooltip: 'Añadir evento',
        child: Icon(Icons.add),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calenapp/models/event.dart';
import 'package:calenapp/services/notifications_service.dart';
import 'package:calenapp/utils/shared_prefs.dart'; // Para SharedPrefs // Asegúrate de importar la clase Event

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

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

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

    // Cancelar notificación si existe
    final notificationsEnabled = await SharedPrefs.getNotificationsEnabled();
    if (notificationsEnabled) {
      await NotificationService().cancelNotification(key.hashCode);
    }
  }

  Future<void> _addEventDialog(DateTime day) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              // ... (contenido existente del AlertDialog)
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
                    setState(() {
                      _events[key] = [..._events[key] ?? [], event];
                      _focusedDay = _selectedDay;
                    });
                    await _saveEvents();

                    // Notificación silenciosa de confirmación
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ Evento guardado')),
                    );

                    // Verificar preferencias antes de programar notificación
                    final notificationsEnabled =
                        await SharedPrefs.getNotificationsEnabled();
                    if (notificationsEnabled) {
                      await NotificationService().scheduleEventNotification(
                        'Evento Programado', // Título de la notificación
                        'Recuerda tu evento importante', // Cuerpo de la notificación
                        DateTime(
                          2025,
                          5,
                          1,
                          10,
                          0,
                        ), // Fecha y hora programada para la notificación
                      );
                    }

                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final currentMonthColor = widget.isDarkMode ? Colors.white : Colors.black;
    final otherMonthColor = widget.isDarkMode ? Colors.white54 : Colors.black54;

    return FutureBuilder<bool>(
      // Obtenemos el estado de las notificaciones
      future: SharedPrefs.getNotificationsEnabled(),
      builder: (context, snapshot) {
        final notificationsEnabled = snapshot.data ?? true;

        return Scaffold(
          appBar: AppBar(
            title: Text("Calendario"),
            actions: [
              // Botón de notificaciones (con color dinámico)
              IconButton(
                icon: Icon(Icons.notifications),
                color: notificationsEnabled ? Colors.blue : Colors.grey,
                onPressed: () async {
                  final newStatus = !notificationsEnabled;
                  await SharedPrefs.setNotificationsEnabled(newStatus);
                  setState(() {}); // Actualiza la UI

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newStatus
                            ? 'Notificaciones activadas'
                            : 'Notificaciones desactivadas',
                      ),
                    ),
                  );
                },
              ),
              // Botón de tema oscuro (existente)
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
                  outsideTextStyle: TextStyle(
                    color: textColor.withOpacity(0.5),
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1, // ¡Aquí está el cambio clave!
                  markerDecoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      0,
                      40,
                      75,
                    ), // Color del punto
                    shape: BoxShape.circle,
                    boxShadow: [
                      // ¡Efecto de glow!
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          0,
                          40,
                          75,
                        ), // Color del brillo
                        blurRadius: 3.0, // Intensidad del difuminado
                        spreadRadius: 1.0, // Expansión del efecto
                      ),
                    ],
                  ),
                  markerMargin: EdgeInsets.only(bottom: 4),
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
      },
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

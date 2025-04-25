import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';

class EventService {
  static Future<Map<DateTime, List<Event>>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      final decoded = jsonDecode(eventsJson) as List;
      final events = <DateTime, List<Event>>{};
      for (var dayData in decoded) {
        final day = DateTime.parse(dayData['day']);
        final eventList =
            (dayData['events'] as List).map((e) => Event.fromMap(e)).toList();
        events[day] = eventList;
      }
      return events;
    }
    return {};
  }

  static Future<void> saveEvents(Map<DateTime, List<Event>> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsList =
        events.entries.map((entry) {
          return {
            'day': entry.key.toIso8601String(),
            'events': entry.value.map((e) => e.toMap()).toList(),
          };
        }).toList();
    await prefs.setString('events', jsonEncode(eventsList));
  }
}

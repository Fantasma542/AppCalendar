import 'package:flutter/material.dart';

class Event {
  final String title;
  final String description;
  final TimeOfDay time;

  Event({
    required this.title,
    this.description = '', // Valor predeterminado para description
    required this.time,
  });

  // Método para convertir un evento a un mapa (usado para almacenar en SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'time': _timeToString(time),
    };
  }

  // Método para crear un evento a partir de un mapa (usado para cargar desde SharedPreferences)
  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      title: map['title'] ?? '',
      description:
          map['description'] ?? '', // Aseguramos que description nunca sea null
      time: _parseTime(map['time']),
    );
  }

  // Método para analizar la hora almacenada como una cadena
  static TimeOfDay _parseTime(String timeString) {
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Método para convertir TimeOfDay a string
  static String _timeToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

import 'package:flutter/material.dart';
import '../models/event.dart';

Future<void> showEventDialog(
  BuildContext context,
  DateTime day,
  Function(Event) onAddEvent,
) async {
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
                          selectedTime = picked;
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
                onAddEvent(event);
                Navigator.pop(context);
              },
            ),
          ],
        ),
  );
}

import 'package:flutter/material.dart';
import 'package:calenapp/models/event.dart'; //

class EventListWidget extends StatelessWidget {
  final List<Event> events;
  final Function(Event) onDeleteEvent;

  const EventListWidget({
    Key? key,
    required this.events,
    required this.onDeleteEvent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            title: Text(event.title),
            subtitle: Text(
              '${event.description} • ${event.time.format(context)}',
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDeleteEvent(event),
            ),
          );
        },
      ),
    );
  }
}

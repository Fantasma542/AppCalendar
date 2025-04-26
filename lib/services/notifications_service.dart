import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> cancelNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  // Método para programar una notificación para un evento
  Future<void> scheduleEventNotification(
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'event_channel_id', // ID del canal
          'Event Notifications', // Nombre del canal
          channelDescription:
              'Notifications for scheduled events', // Descripción del canal
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'event_ticker',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Configura la hora para la notificación utilizando la fecha y hora programadas
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    // Llama a zonedSchedule para programar la notificación
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID de la notificación
      title, // Título de la notificación
      body, // Cuerpo de la notificación
      scheduledDate, // Hora de la notificación
      platformDetails, // Detalles de la notificación
      androidScheduleMode: AndroidScheduleMode.exact, // Programación exacta
      matchDateTimeComponents: DateTimeComponents.time, // Coincidir con la hora
    );
  }

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    // Se elimina la llamada a requestPermission ya que no es necesaria en Android
    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> scheduleNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          channelDescription: 'Your channel description',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Configura la hora para la notificación, por ejemplo, dentro de 10 segundos.
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: 10));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID de la notificación
      'Scheduled Notification', // Título de la notificación
      'This is a scheduled notification', // Cuerpo de la notificación
      scheduledDate, // Hora de la notificación
      platformDetails, // Detalles de la notificación
      androidScheduleMode:
          AndroidScheduleMode.exact, // Este es el parámetro requerido
      matchDateTimeComponents: DateTimeComponents.time, // Coincidir con la hora
    );
  }

  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print("Notification permission granted");
    } else {
      print("Notification permission denied");
    }
  }
}

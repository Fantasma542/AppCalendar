import 'package:flutter/material.dart';
import 'pages/calendar_page.dart';
import 'package:calenapp/services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para async en main()

  // Inicializa el servicio de notificaciones
  await NotificationService().initialize();
  runApp(MyApp());
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
        toggleTheme: () => setState(() => isDarkMode = !isDarkMode),
        isDarkMode: isDarkMode,
      ),
    );
  }
}

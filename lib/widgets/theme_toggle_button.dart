import 'package:flutter/material.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const ThemeToggleButton({
    Key? key,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
        color: isDarkMode ? Colors.yellow : Colors.blue,
      ),
      onPressed: toggleTheme,
    );
  }
}

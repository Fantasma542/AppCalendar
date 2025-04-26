import 'package:flutter/material.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const ThemeToggleButton({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

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

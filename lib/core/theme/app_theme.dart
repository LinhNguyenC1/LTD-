import 'package:flutter/material.dart';
import '../models/food.dart';

const Color primaryGreen = Color(0xFF1E533B);
const Color canvasBg = Color(0xFFF8F8F2);
const Color cardBorder = Color(0xFFE0E6DF);
const Color inkText = Color(0xFF1F3329);
const Color subText = Color(0xFF6D7F77);

Color getResultColor(Result result) {
  switch (result) {
    case Result.good:
      return const Color(0xFF1E533B);
    case Result.warn:
      return const Color(0xFF8C600F);
    case Result.bad:
      return const Color(0xFFB23A2B);
    case Result.unknown:
      return const Color(0xFF4A6075);
  }
}

Color getResultBg(Result result) {
  switch (result) {
    case Result.good:
      return const Color(0xFFE4F1E5);
    case Result.warn:
      return const Color(0xFFFDF5E2);
    case Result.bad:
      return const Color(0xFFFCEAE6);
    case Result.unknown:
      return const Color(0xFFEAF0F6);
  }
}

IconData getResultIcon(Result result) {
  switch (result) {
    case Result.good:
      return Icons.check_circle_outline;
    case Result.warn:
      return Icons.warning_amber_rounded;
    case Result.bad:
      return Icons.cancel_outlined;
    case Result.unknown:
      return Icons.help_outline;
  }
}

String getResultText(Result result) {
  switch (result) {
    case Result.good:
      return 'Phù hợp';
    case Result.warn:
      return 'Cần cân nhắc';
    case Result.bad:
      return 'Không phù hợp';
    case Result.unknown:
      return 'Chưa đủ dữ liệu';
  }
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: canvasBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      surface: canvasBg,
    ),
    fontFamily: 'sans',
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: inkText, height: 1.4),
      titleLarge: TextStyle(color: inkText, fontWeight: FontWeight.bold),
    ),
  );
}

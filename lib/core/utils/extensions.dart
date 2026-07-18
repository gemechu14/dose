import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'responsive.dart';

extension StringExtensions on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ').map((w) => w.capitalized).join(' ');

  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);
}

extension DateTimeExtensions on DateTime {
  String get formattedDate => DateFormat('MMM d, y').format(this);

  String get formattedDateTime => DateFormat('MMM d, y • h:mm a').format(this);

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

extension DoubleExtensions on double {
  String get grams => '${toStringAsFixed(1)}g';
  String get ml => '${toStringAsFixed(1)}ml';
  String get currency => '\$${toStringAsFixed(2)}';
  String get percent => '${toStringAsFixed(1)}%';
}

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  ScreenSize get responsiveSize => Responsive.screenSizeOf(this);
  bool get isCompactScreen => Responsive.isCompact(this);
  bool get isExpandedScreen => Responsive.isExpandedOrWider(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

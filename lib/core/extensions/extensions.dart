import 'package:intl/intl.dart';

/// String extensions
extension StringExtension on String {
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  bool get isValidPhone {
    final phoneRegex = RegExp(r'^[0-9]{10,}$');
    return phoneRegex.hasMatch(replaceAll(RegExp(r'[^\d]'), ''));
  }

  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
}

/// DateTime extensions
extension DateTimeExtension on DateTime {
  String formatShort() {
    return DateFormat.yMd().format(this);
  }

  String formatMedium() {
    return DateFormat.yMMMMd().format(this);
  }

  String formatTime() {
    return DateFormat.Hm().format(this);
  }

  String formatFull() {
    return DateFormat.yMMMMd('en_US').add_jm().format(this);
  }

  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  String formattedTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatMedium();
    }
  }
}

/// Number extensions
extension NumExtension on num {
  String toCurrency({String symbol = 'R'}) {
    return '$symbol ${toStringAsFixed(2)}';
  }

  String toFormattedString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

/// List extensions
extension ListExtension<T> on List<T> {
  List<T> unique() {
    return toSet().toList();
  }

  void insertOrUpdate(T item, bool Function(T) condition) {
    final index = indexWhere(condition);
    if (index >= 0) {
      this[index] = item;
    } else {
      add(item);
    }
  }
}

/// Map extensions
extension MapExtension<K, V> on Map<K, V> {
  V? getOrNull(K key) => this[key];

  Map<K, V> filterByValue(bool Function(V) condition) {
    return Map.fromEntries(
      entries.where((entry) => condition(entry.value)),
    );
  }
}

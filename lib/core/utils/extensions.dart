import 'package:intl/intl.dart';

extension StringExtensions on String {
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String get titleCase {
    return split(' ').map((word) => word.capitalized).join(' ');
  }

  bool get isValidEmail {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(this);
  }

  bool get isValidPhone {
    final phoneRegex = RegExp(r'^\+?[\d\s\-]{7,15}$');
    return phoneRegex.hasMatch(this);
  }

  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  String get whatsAppUrl {
    final clean = replaceAll(RegExp(r'[\s\-\+]'), '');
    return 'https://wa.me/$clean';
  }
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String get orEmpty => this ?? '';
}

extension DateTimeExtensions on DateTime {
  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  String get formattedDateTime {
    return DateFormat('dd/MM/yyyy HH:mm').format(this);
  }

  String get monthYear {
    return DateFormat('MMMM yyyy', 'es_CO').format(this);
  }

  String get dayMonthYear {
    return DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_CO').format(this);
  }

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 365) {
      return 'hace ${(diff.inDays / 365).floor()} años';
    } else if (diff.inDays > 30) {
      return 'hace ${(diff.inDays / 30).floor()} meses';
    } else if (diff.inDays > 0) {
      return 'hace ${diff.inDays} días';
    } else if (diff.inHours > 0) {
      return 'hace ${diff.inHours} horas';
    } else if (diff.inMinutes > 0) {
      return 'hace ${diff.inMinutes} minutos';
    } else {
      return 'hace un momento';
    }
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isPast => isBefore(DateTime.now());
  bool get isFuture => isAfter(DateTime.now());

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}

extension NumExtensions on num {
  String get copFormatted {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(this);
  }

  String get compactFormatted {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(0)}K';
    }
    return toString();
  }

  String get percentFormatted => '${toStringAsFixed(0)}%';

  String starsDisplay({int maxStars = 5}) {
    final filled = toInt().clamp(0, maxStars);
    return List.generate(maxStars, (i) => i < filled ? '★' : '☆').join();
  }
}

extension DoubleExtensions on double {
  String get ratingFormatted => toStringAsFixed(1);
}

extension ListExtensions<T> on List<T> {
  List<T> get withoutDuplicates => toSet().toList();

  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;

  List<T> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length)));
    }
    return chunks as List<T>;
  }
}

extension ContextExtensions on Object {
  bool get isNotEmpty => toString().isNotEmpty;
}

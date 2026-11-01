/// Bangla number and date helpers. Pure Dart.
class Bn {
  Bn._();

  static const List<String> _digits = [
    '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯',
  ];

  static const List<String> _months = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];

  /// Converts every Latin digit in [value] to a Bangla digit.
  static String digits(Object value) {
    final s = value.toString();
    final out = StringBuffer();
    for (final unit in s.codeUnits) {
      if (unit >= 48 && unit <= 57) {
        out.write(_digits[unit - 48]);
      } else {
        out.writeCharCode(unit);
      }
    }
    return out.toString();
  }

  /// Converts Bangla digits back to Latin digits.
  static String toLatin(String s) {
    final out = StringBuffer();
    for (final ch in s.split('')) {
      final i = _digits.indexOf(ch);
      out.write(i >= 0 ? i.toString() : ch);
    }
    return out.toString();
  }

  /// Parses user input that may contain Bangla or Latin digits.
  /// Returns null for empty or invalid input.
  static double? parse(String? input) {
    if (input == null) return null;
    final s = toLatin(input.trim()).replaceAll(',', '').replaceAll(' ', '');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  static int? parseInt(String? input) {
    final v = parse(input);
    if (v == null || v != v.roundToDouble()) return null;
    return v.round();
  }

  /// A number in Bangla digits with trailing zeros removed: 2.50 -> ২.৫
  static String number(double value, {int maxDecimals = 1}) {
    var s = value.toStringAsFixed(maxDecimals);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    if (s == '-0') s = '0';
    return digits(s);
  }

  /// Whole number with thousands separators: 12000 -> ১২,০০০
  static String count(int value) {
    final raw = value.abs().toString();
    final out = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) out.write(',');
      out.write(raw[i]);
    }
    return digits('${value < 0 ? '-' : ''}$out');
  }

  /// Weight for farmers: under 1 kg is shown in grams.
  static String weight(double kg) {
    if (kg < 1) return '${number(kg * 1000, maxDecimals: 0)} গ্রাম';
    return '${number(kg, maxDecimals: kg < 10 ? 2 : 1)} কেজি';
  }

  static String date(DateTime d) =>
      '${digits(d.day)} ${_months[d.month - 1]} ${digits(d.year)}';

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// আজ / গতকাল / full date
  static String relativeDate(DateTime d, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final diff = today.difference(dateOnly(d)).inDays;
    if (diff == 0) return 'আজ';
    if (diff == 1) return 'গতকাল';
    return date(d);
  }
}

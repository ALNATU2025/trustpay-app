/// Currency symbol shown before every amount (new leone, SLE).
const String kCurrencySymbol = 'Le ';

/// Formats a number as Sierra Leone leones (SLE), e.g. `Le 12,450.00`.
String formatLeone(num value, {bool showSign = false, int decimals = 2}) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  final sign = negative ? '-' : (showSign ? '+' : '');
  final fraction = decimals > 0 ? '.${parts[1]}' : '';
  return '$sign$kCurrencySymbol$whole$fraction';
}

const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const kMonthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String two(int n) => n.toString().padLeft(2, '0');

/// `11 Oct 2026 · 12:50`
String formatDateTime(DateTime d) =>
    '${d.day} ${_monthsShort[d.month - 1]} ${d.year} · ${two(d.hour)}:${two(d.minute)}';

/// `11 Oct`
String formatShortDate(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';

/// Reads an amount typed by the user, ignoring commas and the Le sign.
double parseAmount(String text) =>
    double.tryParse(text.replaceAll(',', '').replaceAll('Le', '').trim()) ?? 0;

/// `12:50`
String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// `1,234` for whole numbers such as user counts.
String formatInt(num value) => formatLeone(value, decimals: 0).replaceFirst(kCurrencySymbol, '');

/// Parses an ISO 8601 string from the API into local time, or null.
DateTime? tryParseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

/// Like [tryParseDate] but falls back to now.
DateTime parseDate(Object? value) => tryParseDate(value) ?? DateTime.now();

/// `11 Oct, 12:50`
String formatShortDateTime(DateTime d) => '${formatShortDate(d)}, ${formatTime(d)}';

/// Digits only, for comparing phone numbers typed in different formats.
String digitsOf(String text) => text.replaceAll(RegExp(r'\D'), '');

/// True when two phone numbers match on their last 8 digits.
bool samePhone(String a, String b) {
  final x = digitsOf(a);
  final y = digitsOf(b);
  if (x.length < 8 || y.length < 8) return false;
  return x.substring(x.length - 8) == y.substring(y.length - 8);
}

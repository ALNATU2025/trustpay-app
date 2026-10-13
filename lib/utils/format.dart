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

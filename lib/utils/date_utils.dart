import 'package:intl/intl.dart';

class DateHelper {
  static String formatDate(DateTime date) {
    // Convert to dd-MMM-yyyy
    return DateFormat("dd-MMM-yyyy").format(date);
  }

  static DateTime? tryParseDate(String input) {
    final possibleFormats = [
      DateFormat("dd-MM-yyyy"),
      DateFormat("dd/MM/yyyy"),
      DateFormat("dd/MMM/yyyy"),
      DateFormat("yyyy-MM-dd"), // fallback (Flutter default toString split)
    ];
    for (var fmt in possibleFormats) {
      try {
        return fmt.parseStrict(input);
      } catch (_) {}
    }
    return null;
  }
}

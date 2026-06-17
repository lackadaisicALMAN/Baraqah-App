import 'package:intl/intl.dart';

class DateUtils {
  static String formatDateTime(DateTime value) {
    return DateFormat('MMM d, yyyy · h:mm a').format(value.toLocal());
  }
}

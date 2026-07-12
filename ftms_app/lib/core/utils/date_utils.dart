
import 'package:intl/intl.dart';

class FTMSDateUtils {

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatDate(DateTime date) =>
    DateFormat('MMM d, yyyy').format(date);

  static String formatDateTime(DateTime date) =>
    DateFormat('MMM d, yyyy • h:mm a').format(date);
}

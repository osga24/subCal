import 'package:intl/intl.dart';
import 'billing_cycle.dart';

class Subscription {
  final String id;
  final String name;
  final double cost;
  final String currency;
  final BillingCycle cycle;
  final DateTime startDate;
  final String categoryId;
  final String? note;
  final int remindDaysBefore; // [新增] 提早幾天通知 (0=當天, -1=不通知)

  Subscription({
    required this.id,
    required this.name,
    required this.cost,
    required this.currency,
    required this.cycle,
    required this.startDate,
    required this.categoryId,
    this.note,
    this.remindDaysBefore = -1, // 預設不通知
  });

  DateTime get nextPaymentDate {
    DateTime now = DateTime.now();
    DateTime nextDate = startDate;
    now = DateTime(now.year, now.month, now.day);

    while (nextDate.isBefore(now)) {
      if (cycle == BillingCycle.monthly) {
        nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
      } else {
        nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
      }
    }
    return nextDate;
  }

  /// 取得通知顯示的文字
  String get reminderText {
    if (remindDaysBefore == -1) return '不通知';
    if (remindDaysBefore == 0) return '付款當天';
    return '提早 $remindDaysBefore 天';
  }

  List<DateTime> getAllUpcomingPaymentDates() {
    List<DateTime> dates = [];
    DateTime current = nextPaymentDate;
    DateTime limit = DateTime.now().add(const Duration(days: 365));

    while (current.isBefore(limit)) {
      dates.add(current);
      if (cycle == BillingCycle.monthly) {
        current = DateTime(current.year, current.month + 1, current.day);
      } else {
        current = DateTime(current.year + 1, current.month, current.day);
      }
    }
    return dates;
  }

  String get formattedNextPaymentDate {
    return DateFormat('yyyy/MM/dd').format(nextPaymentDate);
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 1. 分類模型
class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  // 預設分類
  static List<CategoryModel> defaultCategories() {
    return [
      CategoryModel(
        id: 'ent',
        name: '娛樂',
        icon: Icons.movie_creation_outlined,
        color: const Color(0xffeb6f92),
      ),
      CategoryModel(
        id: 'prod',
        name: '生產力',
        icon: Icons.work_outline,
        color: const Color(0xff31748f),
      ),
      CategoryModel(
        id: 'util',
        name: '工具',
        icon: Icons.build_circle_outlined,
        color: const Color(0xff9ccfd8),
      ),
      CategoryModel(
        id: 'life',
        name: '生活',
        icon: Icons.coffee_outlined,
        color: const Color(0xfff6c177),
      ),
      CategoryModel(
        id: 'music',
        name: '音樂',
        icon: Icons.music_note_outlined,
        color: const Color(0xffc4a7e7),
      ),
      CategoryModel(
        id: 'other',
        name: '其他',
        icon: Icons.grid_view,
        color: Colors.grey,
      ),
    ];
  }
}

// 2. 繳費週期 Enum
enum BillingCycle { monthly, annually }

extension BillingCycleExtension on BillingCycle {
  String get displayName {
    switch (this) {
      case BillingCycle.monthly:
        return '月繳';
      case BillingCycle.annually:
        return '年繳';
    }
  }
}

// 3. 訂閱項目模型
class Subscription {
  final String id;
  final String name;
  final double cost;
  final String currency;
  final BillingCycle cycle;
  final DateTime startDate;
  final String categoryId;
  final String? note;
  final int remindDaysBefore;

  Subscription({
    required this.id,
    required this.name,
    required this.cost,
    required this.currency,
    required this.cycle,
    required this.startDate,
    required this.categoryId,
    this.note,
    this.remindDaysBefore = -1,
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

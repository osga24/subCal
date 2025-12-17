import 'package:flutter/material.dart';
// [重要] 引用剛剛建立的模型檔案
// 假設這個檔案在 lib/widgets/ 資料夾，而 models.dart 在 lib/ 資料夾
import '../models/models.dart';

class SubscriptionList extends StatelessWidget {
  final List<Subscription> subscriptions;
  final List<CategoryModel> categories;
  final Function(String) onDelete;
  final Function(Subscription) onTap;

  const SubscriptionList({
    super.key,
    required this.subscriptions,
    required this.categories,
    required this.onDelete,
    required this.onTap,
  });

  CategoryModel _getCategory(String id) {
    return categories.firstWhere(
      (c) => c.id == id,
      orElse: () => categories.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(40), child: Text('無符合條件的訂閱項目')),
      );
    }

    return ListView.builder(
      itemCount: subscriptions.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final sub = subscriptions[index];
        final category = _getCategory(sub.categoryId);

        return Dismissible(
          key: ValueKey(sub.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('確認刪除'),
                content: Text('確定要刪除「${sub.name}」嗎？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      '刪除',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) => onDelete(sub.id),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: () => onTap(sub),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 左側圖示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 中間資訊 (使用 Expanded 解決溢出問題)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 使用 Wrap 自動換行日期與通知
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 2,
                            children: [
                              Text(
                                '${sub.cycle.displayName} • ${sub.formattedNextPaymentDate}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              if (sub.remindDaysBefore != -1)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.notifications_active,
                                      size: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      sub.reminderText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 右側金額
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${sub.currency} ${sub.cost.toStringAsFixed(sub.cost.truncateToDouble() == sub.cost ? 0 : 2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (sub.note != null && sub.note!.isNotEmpty)
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

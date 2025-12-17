import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import 'calendar_view.dart';
import 'category_management_screen.dart';
import 'subscription_form_screen.dart';
import '../providers/providers.dart';

enum SortType { date, costDesc, name }

class SubscriptionHomePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const SubscriptionHomePage({super.key, required this.themeProvider});

  @override
  State<SubscriptionHomePage> createState() => _SubscriptionHomePageState();
}

class _SubscriptionHomePageState extends State<SubscriptionHomePage> {
  int _selectedIndex = 0;
  SortType _currentSort = SortType.date;

  String? _selectedFilterCategoryId;
  List<CategoryModel> _categories = CategoryModel.defaultCategories();
  List<Subscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    // 範例資料 (僅作初始演示，實際使用會新增自己的)
    _subscriptions = [
      Subscription(
        id: '1',
        name: 'Netflix',
        cost: 330.0,
        currency: 'TWD',
        cycle: BillingCycle.monthly,
        startDate: DateTime(2024, 10, 15),
        categoryId: 'ent',
        remindDaysBefore: 1,
      ),
    ];
    _rescheduleAllNotifications(); // 初始化時重新排程確認
    _sortSubscriptions();
  }

  // Helper: 重新排程所有通知 (簡單實作)
  void _rescheduleAllNotifications() {
    // 這裡只是示範，實際應用應該在新增/修改時做即可，避免每次開 App 都跑迴圈
    // 但為了確保通知正確，這裡可以檢查一遍
  }

  // 核心邏輯：設定通知
  void _setupNotification(Subscription sub) {
    // 1. 先取消舊的，避免重複
    final notificationId = sub.id.hashCode;
    NotificationService().cancelNotification(notificationId);

    // 2. 如果使用者設定「不通知」，則直接結束
    if (sub.remindDaysBefore == -1) return;

    // 3. 計算通知時間 (變數宣告)
    DateTime reminderDate;
    String bodyText;

    // ==========================================
    // [模式 A] 測試模式 (TEST MODE)
    // 功能：不管設定哪天，按下儲存後 10 秒鐘通知
    // ==========================================

    reminderDate = DateTime.now().add(const Duration(seconds: 10));
    bodyText = '[測試] 扣費通知：${sub.name} 金額 ${sub.cost}';

    // ==========================================

    // ==========================================
    // [模式 B] 正常模式 (PRODUCTION MODE)
    // 功能：根據付款日與提早天數，於當天早上 9:00 通知
    // ==========================================
    /*
    final nextPayment = sub.nextPaymentDate;
    reminderDate = nextPayment.subtract(Duration(days: sub.remindDaysBefore));

    // 設定通知時間為早上 9:00 (可自行修改，例如 20, 0 代表晚上 8 點)
    reminderDate = DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9, 0);

    bodyText = '即將於 ${DateFormat('MM/dd').format(nextPayment)} 扣款 ${sub.currency} ${sub.cost.toStringAsFixed(0)}';

    // 防呆：如果計算出來的時間已經是「過去」了 (例如今天早上9點已過)，就不排程
    if (reminderDate.isBefore(DateTime.now())) {
       print("⚠️ [正常模式] 通知時間已過，略過排程: $reminderDate");
       return;
    }
    */
    // ==========================================

    // 4. 發送排程請求
    NotificationService().scheduleNotification(
      notificationId,
      '訂閱繳費提醒：${sub.name}',
      bodyText,
      reminderDate,
    );
  }

  CategoryModel _getCategoryById(String id) {
    return _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => _categories.firstWhere(
        (c) => c.id == 'other',
        orElse: () => _categories.last,
      ),
    );
  }

  List<Subscription> get _filteredSubscriptions {
    if (_selectedFilterCategoryId == null) {
      return _subscriptions;
    }
    return _subscriptions
        .where((s) => s.categoryId == _selectedFilterCategoryId)
        .toList();
  }

  double get totalMonthlyCost {
    double total = 0.0;
    for (var sub in _subscriptions) {
      if (sub.cycle == BillingCycle.monthly) {
        total += sub.cost;
      } else {
        total += sub.cost / 12.0;
      }
    }
    return total;
  }

  double get totalAnnualCost {
    double total = 0.0;
    for (var sub in _subscriptions) {
      if (sub.cycle == BillingCycle.annually) {
        total += sub.cost;
      } else {
        total += sub.cost * 12.0;
      }
    }
    return total;
  }

  void _sortSubscriptions() {
    setState(() {
      switch (_currentSort) {
        case SortType.date:
          _subscriptions.sort(
            (a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate),
          );
          break;
        case SortType.costDesc:
          _subscriptions.sort((a, b) => b.cost.compareTo(a.cost));
          break;
        case SortType.name:
          _subscriptions.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    });
  }

  void _openCategoryManager() async {
    final updatedCategories = await Navigator.push<List<CategoryModel>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoryManagementScreen(currentCategories: _categories),
      ),
    );

    if (updatedCategories != null) {
      setState(() {
        _categories = updatedCategories;
      });
    }
  }

  void _openSubscriptionForm({Subscription? existingSub}) async {
    final result = await Navigator.push<Subscription>(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionFormScreen(
          initialSubscription: existingSub,
          categories: _categories,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (existingSub != null) {
          final index = _subscriptions.indexWhere(
            (sub) => sub.id == existingSub.id,
          );
          if (index != -1) {
            _subscriptions[index] = result;
          }
        } else {
          _subscriptions.add(result);
        }
        _sortSubscriptions();

        // [新增] 設定或更新通知
        _setupNotification(result);
      });
    }
  }

  void _deleteSubscription(String id) {
    setState(() {
      // [新增] 刪除時取消通知
      NotificationService().cancelNotification(id.hashCode);
      _subscriptions.removeWhere((sub) => sub.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildListView(),
      CalendarView(
        subscriptions: _subscriptions,
        categories: _categories,
        onEdit: (sub) => _openSubscriptionForm(existingSub: sub),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SubCal',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: '管理分類',
            onPressed: _openCategoryManager,
          ),
          PopupMenuButton<SortType>(
            icon: const Icon(Icons.sort),
            tooltip: '排序',
            onSelected: (SortType result) {
              _currentSort = result;
              _sortSubscriptions();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortType>>[
              const PopupMenuItem(value: SortType.date, child: Text('依付款日期')),
              const PopupMenuItem(
                value: SortType.costDesc,
                child: Text('依費用 (高到低)'),
              ),
              const PopupMenuItem(value: SortType.name, child: Text('依名稱')),
            ],
          ),
          IconButton(
            icon: Icon(
              widget.themeProvider.themeMode == ThemeMode.dark
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
            ),
            onPressed: widget.themeProvider.toggleTheme,
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '總覽',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '日曆',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openSubscriptionForm(),
              label: const Text('新增'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildListView() {
    final displayList = _filteredSubscriptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TotalSummaryCard(
          totalMonthlyCost: totalMonthlyCost,
          totalAnnualCost: totalAnnualCost,
        ),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('全部'),
                  selected: _selectedFilterCategoryId == null,
                  onSelected: (bool selected) {
                    setState(() => _selectedFilterCategoryId = null);
                  },
                ),
              ),
              ..._categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.name),
                    avatar: Icon(cat.icon, size: 16, color: cat.color),
                    selected: _selectedFilterCategoryId == cat.id,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilterCategoryId = selected ? cat.id : null;
                      });
                    },
                    backgroundColor: Theme.of(context).cardColor,
                    selectedColor: cat.color.withOpacity(0.2),
                    side: BorderSide(
                      color: _selectedFilterCategoryId == cat.id
                          ? cat.color
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedFilterCategoryId == null
                    ? '所有訂閱 (${displayList.length})'
                    : '${_getCategoryById(_selectedFilterCategoryId!).name} (${displayList.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SubscriptionList(
            subscriptions: displayList,
            categories: _categories,
            onDelete: _deleteSubscription,
            onTap: (sub) => _openSubscriptionForm(existingSub: sub),
          ),
        ),
      ],
    );
  }
}

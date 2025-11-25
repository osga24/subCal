import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 資料模型 (Data Model) ---

/// 訂閱項目的資料結構
class Subscription {
  final String id;
  final String name;
  final double cost;
  final String currency;
  final BillingCycle cycle;
  final DateTime startDate; // 第一筆付款的日期

  Subscription({
    required this.id,
    required this.name,
    required this.cost,
    required this.currency,
    required this.cycle,
    required this.startDate,
  });

  /// 根據當前日期計算下一次付款日期
  DateTime get nextPaymentDate {
    DateTime now = DateTime.now();
    DateTime nextDate = startDate;

    // 讓 nextDate 往後推移，直到它超過或等於今天
    while (nextDate.isBefore(now)) {
      if (cycle == BillingCycle.monthly) {
        // 月繳：加一個月
        nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
      } else {
        // 年繳：加一年
        nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
      }
    }
    return nextDate;
  }

  /// 獲取未來12個月的所有付款日期
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

  /// 格式化下次付款日期，顯示為 YYYY/MM/DD
  String get formattedNextPaymentDate {
    return DateFormat('yyyy/MM/dd').format(nextPaymentDate);
  }
}

/// 帳單週期
enum BillingCycle { monthly, annually }

// 擴充 Enum 來提供更友好的顯示名稱
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

// --- Theme Provider ---

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}

// --- 主要應用程式 (Main Application) ---

void main() {
  runApp(SubscriptionTrackerApp());
}

class SubscriptionTrackerApp extends StatefulWidget {
  const SubscriptionTrackerApp({super.key});

  @override
  State<SubscriptionTrackerApp> createState() => _SubscriptionTrackerAppState();
}

class _SubscriptionTrackerAppState extends State<SubscriptionTrackerApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'subCal',
      themeMode: _themeProvider.themeMode,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xfffaf4ed), // Rosé Pine Dawn base
        colorScheme: const ColorScheme.light(
          primary: Color(0xffd7827e), // rose
          secondary: Color(0xffea9d34), // gold
          surface: Color(0xfffffaf3), // surface
          background: Color(0xfffaf4ed), // base
          error: Color(0xffb4637a), // love
          onPrimary: Color(0xff575279), // text
          onSecondary: Color(0xff575279), // text
          onSurface: Color(0xff575279), // text
          onBackground: Color(0xff575279), // text
          onError: Color(0xfffaf4ed), // base
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfffffaf3), // surface
          foregroundColor: Color(0xff575279), // text
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xff575279)), // text
        ),
        cardTheme: CardThemeData(
          color: const Color(0xfffffaf3), // surface
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xffdfdad9),
              width: 2,
            ), // highlightMed
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xffd7827e), // rose
          foregroundColor: Color(0xfffaf4ed), // base
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xfffffaf3), // surface
          indicatorColor: const Color(0xffd7827e), // rose
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(color: Color(0xff575279), fontSize: 12), // text
          ),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Color(0xfffaf4ed)); // base
            }
            return const IconThemeData(color: Color(0xff575279)); // text
          }),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffd7827e), // rose
            foregroundColor: const Color(0xfffaf4ed), // base
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color(0xffdfdad9),
              width: 2,
            ), // highlightMed
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color(0xffdfdad9),
              width: 2,
            ), // highlightMed
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color(0xffd7827e),
              width: 3,
            ), // rose
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: const Color(0xff191724), // Rosé Pine base
        colorScheme: const ColorScheme.dark(
          primary: Color(0xffebbcba), // rose
          secondary: Color(0xfff6c177), // gold
          surface: Color(0xff1f1d2e), // surface
          background: Color(0xff191724), // base
          error: Color(0xffeb6f92), // love
          onPrimary: Color(0xff191724), // base
          onSecondary: Color(0xff191724), // base
          onSurface: Color(0xffe0def4), // text
          onBackground: Color(0xffe0def4), // text
          onError: Color(0xff191724), // base
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff1f1d2e), // surface
          foregroundColor: Color(0xffe0def4), // text
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xffe0def4)), // text
        ),
        cardTheme: CardThemeData(
          color: const Color(0xff1f1d2e), // surface
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xff403d52),
              width: 2,
            ), // highlightMed
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xffebbcba), // rose
          foregroundColor: Color(0xff191724), // base
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xff1f1d2e), // surface
          indicatorColor: const Color(0xffebbcba), // rose
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(color: Color(0xffe0def4), fontSize: 12), // text
          ),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Color(0xff191724)); // base
            }
            return const IconThemeData(color: Color(0xffe0def4)); // text
          }),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffebbcba), // rose
            foregroundColor: const Color(0xff191724), // base
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color(0xff403d52),
              width: 2,
            ), // highlightMed
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color(0xff403d52),
              width: 2,
            ), // highlightMed
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color(0xffebbcba),
              width: 3,
            ), // rose
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        useMaterial3: true,
      ),
      home: SubscriptionHomePage(themeProvider: _themeProvider),
    );
  }
}

// --- 應用程式主頁面 (Home Page) ---

class SubscriptionHomePage extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SubscriptionHomePage({super.key, required this.themeProvider});

  @override
  State<SubscriptionHomePage> createState() => _SubscriptionHomePageState();
}

class _SubscriptionHomePageState extends State<SubscriptionHomePage> {
  int _selectedIndex = 0;

  // 示範用的初始數據
  List<Subscription> _subscriptions = [
    Subscription(
      id: '1',
      name: 'Netflix',
      cost: 330.0,
      currency: 'TWD',
      cycle: BillingCycle.monthly,
      startDate: DateTime(2024, 10, 15),
    ),
    Subscription(
      id: '2',
      name: 'Google One (2TB)',
      cost: 3300.0,
      currency: 'TWD',
      cycle: BillingCycle.annually,
      startDate: DateTime(2024, 7, 1),
    ),
  ];

  /// 計算所有訂閱的總月費（已轉換成年繳/12）
  double get totalMonthlyCost {
    double total = 0.0;
    for (var sub in _subscriptions) {
      if (sub.cycle == BillingCycle.monthly) {
        total += sub.cost;
      } else {
        // 年繳平均到每月
        total += sub.cost / 12.0;
      }
    }
    return total;
  }

  /// 計算所有訂閱的總年費
  double get totalAnnualCost {
    double total = 0.0;
    for (var sub in _subscriptions) {
      if (sub.cycle == BillingCycle.annually) {
        total += sub.cost;
      } else {
        // 月繳乘以 12
        total += sub.cost * 12.0;
      }
    }
    return total;
  }

  /// 導航到新增訂閱頁面
  void _navigateToAddSubscription() async {
    final newSubscription = await Navigator.push<Subscription>(
      context,
      MaterialPageRoute(builder: (context) => const AddSubscriptionScreen()),
    );

    if (newSubscription != null) {
      setState(() {
        _subscriptions.add(newSubscription);
        // 排序：按下次付款日期升序排列
        _subscriptions.sort(
          (a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate),
        );
      });
    }
  }

  /// 刪除訂閱項目
  void _deleteSubscription(String id) {
    setState(() {
      _subscriptions.removeWhere((sub) => sub.id == id);
    });
  }

  @override
  void initState() {
    super.initState();
    // 初始化時排序
    _subscriptions.sort(
      (a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      _buildListView(),
      CalendarView(subscriptions: _subscriptions),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'subCal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                widget.themeProvider.themeMode == ThemeMode.dark
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
              ),
              onPressed: () {
                widget.themeProvider.toggleTheme();
              },
              tooltip: '切換主題',
            ),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.onSurface,
              width: 2,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.list_alt), label: '列表'),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: '日曆',
            ),
          ],
        ),
      ),
      // 新增按鈕
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                borderRadius: BorderRadius.circular(30),
              ),
              child: FloatingActionButton.extended(
                onPressed: _navigateToAddSubscription,
                label: const Text(
                  '新增訂閱',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                icon: const Icon(Icons.add, size: 24),
              ),
            )
          : null,
    );
  }

  Widget _buildListView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 總覽卡片
          TotalSummaryCard(
            totalMonthlyCost: totalMonthlyCost,
            totalAnnualCost: totalAnnualCost,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '我的訂閱項目',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),

          // 訂閱列表
          SubscriptionList(
            subscriptions: _subscriptions,
            onDelete: _deleteSubscription,
          ),
        ],
      ),
    );
  }
}

// --- Calendar View ---

class CalendarView extends StatefulWidget {
  final List<Subscription> subscriptions;

  const CalendarView({super.key, required this.subscriptions});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  /// 獲取某天的所有付款事件
  List<Subscription> _getEventsForDay(DateTime day) {
    return widget.subscriptions.where((sub) {
      return sub.getAllUpcomingPaymentDates().any(
        (date) =>
            date.year == day.year &&
            date.month == day.month &&
            date.day == day.day,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(
                0xff403d52,
              ), // Rosé Pine highlightMed (dark) / highlightMed (light)
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: true,
              defaultTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              weekendTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              selectedTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              formatButtonTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              formatButtonDecoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              weekendStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildEventList()),
      ],
    );
  }

  Widget _buildEventList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_selectedDay == null) {
      return const Center(child: Text('請選擇日期'));
    }

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '這天沒有付款項目',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final sub = events[index];
        final currencyFormat = NumberFormat.currency(
          locale: 'zh_TW',
          symbol: sub.currency,
          decimalDigits: sub.cost.round() == sub.cost ? 0 : 2,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    sub.cycle == BillingCycle.monthly
                        ? Icons.autorenew
                        : Icons.event_repeat,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
                      Text(
                        '週期: ${sub.cycle.displayName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(sub.cost),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- 總覽卡片 (Total Summary Card) ---

class TotalSummaryCard extends StatelessWidget {
  final double totalMonthlyCost;
  final double totalAnnualCost;

  const TotalSummaryCard({
    super.key,
    required this.totalMonthlyCost,
    required this.totalAnnualCost,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      locale: 'zh_TW',
      symbol: 'NT\$',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCostItem(
              context,
              '總月均花費',
              currencyFormat.format(totalMonthlyCost.round()),
              Icons.calendar_month_outlined,
              isDark,
            ),
            Container(
              width: 2,
              height: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            _buildCostItem(
              context,
              '總年花費',
              currencyFormat.format(totalAnnualCost.round()),
              Icons.calendar_today_outlined,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostItem(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// --- 訂閱列表 (Subscription List) ---

class SubscriptionList extends StatelessWidget {
  final List<Subscription> subscriptions;
  final Function(String) onDelete;

  const SubscriptionList({
    super.key,
    required this.subscriptions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (subscriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                '目前沒有訂閱項目',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '點擊右下角新增！',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 使用 ListView.builder 建立可滾動列表
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final sub = subscriptions[index];
        final currencyFormat = NumberFormat.currency(
          locale: 'zh_TW',
          symbol: sub.currency,
          decimalDigits: sub.cost.round() == sub.cost ? 0 : 2,
        );

        return Dismissible(
          key: ValueKey(sub.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onError,
              size: 32,
            ),
          ),
          confirmDismiss: (direction) {
            return showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 2,
                  ),
                ),
                title: Text(
                  '確認刪除',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  '確定要刪除訂閱項目「${sub.name}」嗎？',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('刪除'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            onDelete(sub.id);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      sub.cycle == BillingCycle.monthly
                          ? Icons.autorenew
                          : Icons.event_repeat,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        Text(
                          '週期: ${sub.cycle.displayName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(sub.cost),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '下次: ${sub.formattedNextPaymentDate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- 新增訂閱頁面 (Add Subscription Screen) ---

class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  BillingCycle _selectedCycle = BillingCycle.monthly;
  DateTime _selectedStartDate = DateTime.now();

  // 貨幣選擇列表
  final List<String> _currencies = ['TWD', 'USD', 'JPY', 'EUR'];
  String _selectedCurrency = 'TWD';

  // 選擇日期
  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: firstDate,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
            dialogBackgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedStartDate = pickedDate;
      });
    }
  }

  // 儲存表單
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newSub = Subscription(
        id: DateTime.now().toString(),
        name: _nameController.text.trim(),
        cost: double.tryParse(_costController.text) ?? 0.0,
        currency: _selectedCurrency,
        cycle: _selectedCycle,
        startDate: _selectedStartDate,
      );

      Navigator.pop(context, newSub);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '新增訂閱項目',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: '訂閱名稱',
                  hintText: '例如: YouTube Premium',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.label_outline,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入訂閱項目名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _costController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '費用金額',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return '請輸入有效的費用金額';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: InputDecoration(
                  labelText: '貨幣單位',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  prefixIcon: Icon(
                    Icons.monetization_on_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                items: _currencies.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCurrency = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<BillingCycle>(
                value: _selectedCycle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: InputDecoration(
                  labelText: '繳費週期',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  prefixIcon: Icon(
                    Icons.calendar_month_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                items: BillingCycle.values.map((BillingCycle cycle) {
                  return DropdownMenuItem<BillingCycle>(
                    value: cycle,
                    child: Text(cycle.displayName),
                  );
                }).toList(),
                onChanged: (BillingCycle? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCycle = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '首次付款日期',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy年MM月dd日').format(_selectedStartDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _presentDatePicker,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('選擇日期'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save_outlined, size: 24),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    '儲存訂閱',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

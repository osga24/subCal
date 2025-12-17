import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io'; // 用於判斷平台

// ==========================================
// 0. 通知服務 (Notification Service)
// ==========================================

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 初始化時區資料
    tz.initializeTimeZones();

    // Android 設定 (使用 App 預設圖示)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 設定
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  /// 排程通知
  /// [id] 使用 Subscription 的 hashCode
  /// [title] 通知標題
  /// [body] 通知內容
  /// [scheduledDate] 預計通知的時間
  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
  ) async {
    // 如果時間已經過了，就不排程 (避免立刻跳出通知)
    if (scheduledDate.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'subcal_channel', // Channel ID
          '訂閱提醒', // Channel Name
          channelDescription: '通知你即將到來的扣款',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    print("已排程通知: $title 於 $scheduledDate (ID: $id)");
  }

  /// 取消特定通知
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

// ==========================================
// 1. 資料模型 (Data Models)
// ==========================================

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

// ==========================================
// 2. 狀態管理 (Providers)
// ==========================================

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

// ==========================================
// 3. 主程式入口 (Main App)
// ==========================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服務
  await NotificationService().init();

  runApp(const SubscriptionTrackerApp());
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
    // 請求通知權限
    NotificationService().requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SubCal',
      themeMode: _themeProvider.themeMode,
      theme: _buildThemeData(false),
      darkTheme: _buildThemeData(true),
      home: SubscriptionHomePage(themeProvider: _themeProvider),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildThemeData(bool isDark) {
    final base = isDark ? const Color(0xff191724) : const Color(0xfffaf4ed);
    final surface = isDark ? const Color(0xff1f1d2e) : const Color(0xfffffaf3);
    final text = isDark ? const Color(0xffe0def4) : const Color(0xff575279);
    final rose = isDark ? const Color(0xffebbcba) : const Color(0xffd7827e);
    final highlight = isDark
        ? const Color(0xff403d52)
        : const Color(0xffdfdad9);

    return ThemeData(
      scaffoldBackgroundColor: base,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: rose,
        onPrimary: isDark ? base : const Color(0xfffaf4ed),
        secondary: const Color(0xfff6c177),
        onSecondary: base,
        error: const Color(0xffeb6f92),
        onError: base,
        surface: surface,
        onSurface: text,
        outline: highlight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: highlight, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: rose,
        foregroundColor: isDark ? base : const Color(0xfffaf4ed),
      ),
      useMaterial3: true,
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: BorderSide(color: highlight),
        labelStyle: TextStyle(color: text),
        selectedColor: rose.withOpacity(0.2),
        checkmarkColor: rose,
      ),
    );
  }
}

// ==========================================
// 4. 首頁 (Home Page)
// ==========================================

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

// ==========================================
// 5. 分類管理頁面
// ==========================================

class CategoryManagementScreen extends StatefulWidget {
  final List<CategoryModel> currentCategories;

  const CategoryManagementScreen({super.key, required this.currentCategories});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late List<CategoryModel> _categories;

  final List<IconData> _availableIcons = [
    Icons.movie,
    Icons.music_note,
    Icons.games,
    Icons.tv,
    Icons.headset,
    Icons.book,
    Icons.newspaper,
    Icons.palette,
    Icons.camera_alt,
    Icons.image,
    Icons.home,
    Icons.shopping_cart,
    Icons.local_dining,
    Icons.coffee,
    Icons.local_bar,
    Icons.chair,
    Icons.bed,
    Icons.lightbulb,
    Icons.pets,
    Icons.child_care,
    Icons.directions_car,
    Icons.directions_bus,
    Icons.directions_bike,
    Icons.train,
    Icons.flight,
    Icons.local_gas_station,
    Icons.map,
    Icons.hotel,
    Icons.phone_android,
    Icons.computer,
    Icons.wifi,
    Icons.cloud,
    Icons.security,
    Icons.email,
    Icons.chat,
    Icons.smart_toy,
    Icons.work,
    Icons.school,
    Icons.edit,
    Icons.folder,
    Icons.calendar_today,
    Icons.attach_money,
    Icons.account_balance,
    Icons.credit_card,
    Icons.fitness_center,
    Icons.pool,
    Icons.spa,
    Icons.local_hospital,
    Icons.medication,
    Icons.build,
    Icons.settings,
    Icons.cleaning_services,
    Icons.local_laundry_service,
    Icons.checkroom,
    Icons.content_cut,
    Icons.card_giftcard,
    Icons.favorite,
    Icons.star,
    Icons.bolt,
    Icons.category,
    Icons.grid_view,
  ];

  final List<Color> _availableColors = [
    const Color(0xffeb6f92),
    const Color(0xffebbcba),
    const Color(0xfff6c177),
    const Color(0xffebcb8b),
    const Color(0xffa3be8c),
    const Color(0xff31748f),
    const Color(0xff9ccfd8),
    const Color(0xffc4a7e7),
    Colors.brown,
    Colors.grey,
    const Color(0xff26233a),
    Colors.redAccent,
    Colors.blueAccent,
  ];

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.currentCategories);
  }

  void _onBack() {
    Navigator.pop(context, _categories);
  }

  void _showAddEditDialog({CategoryModel? existingCategory}) {
    final isEditing = existingCategory != null;
    final nameController = TextEditingController(
      text: existingCategory?.name ?? '',
    );
    IconData selectedIcon = existingCategory?.icon ?? _availableIcons[0];
    Color selectedColor = existingCategory?.color ?? _availableColors[0];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? '編輯分類' : '新增分類'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '分類名稱',
                          hintText: '例如：交通...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '標籤顏色',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _availableColors.map((color) {
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedColor = color),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 20,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '選擇圖示',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: _availableIcons.length,
                            itemBuilder: (ctx, index) {
                              final icon = _availableIcons[index];
                              final isSelected = selectedIcon == icon;
                              return GestureDetector(
                                onTap: () =>
                                    setDialogState(() => selectedIcon = icon),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          )
                                        : null,
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 24,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    this.setState(() {
                      if (isEditing) {
                        final index = _categories.indexWhere(
                          (c) => c.id == existingCategory.id,
                        );
                        if (index != -1) {
                          _categories[index] = CategoryModel(
                            id: existingCategory.id,
                            name: nameController.text.trim(),
                            icon: selectedIcon,
                            color: selectedColor,
                          );
                        }
                      } else {
                        _categories.add(
                          CategoryModel(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: nameController.text.trim(),
                            icon: selectedIcon,
                            color: selectedColor,
                          ),
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('儲存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('分類管理'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBack,
          ),
          actions: [
            TextButton(
              onPressed: _onBack,
              child: const Text(
                '完成',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isDeletable = cat.id != 'other';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cat.icon, color: cat.color),
                ),
                title: Text(
                  cat.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showAddEditDialog(existingCategory: cat),
                    ),
                    if (isDeletable)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('刪除分類'),
                              content: Text('確定要刪除「${cat.name}」嗎？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _categories.removeAt(index);
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text(
                                    '刪除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(),
          label: const Text('新增分類'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// ==========================================
// 6. 日曆視圖
// ==========================================

class CalendarView extends StatefulWidget {
  final List<Subscription> subscriptions;
  final List<CategoryModel> categories;
  final Function(Subscription) onEdit;

  const CalendarView({
    super.key,
    required this.subscriptions,
    required this.categories,
    required this.onEdit,
  });

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

  CategoryModel _getCategory(String id) {
    return widget.categories.firstWhere(
      (c) => c.id == id,
      orElse: () => widget.categories.last,
    );
  }

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
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) =>
                setState(() => _calendarFormat = format),
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildEventList()),
      ],
    );
  }

  Widget _buildEventList() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Text(
          '今日無待付款項目',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final sub = events[index];
        final category = _getCategory(sub.categoryId);

        return InkWell(
          onTap: () => widget.onEdit(sub),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: category.color.withOpacity(0.2),
                child: Icon(category.icon, color: category.color),
              ),
              title: Text(
                sub.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(sub.currency + ' ' + sub.cost.toString()),
              trailing: const Icon(Icons.chevron_right, size: 16),
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 7. 元件
// ==========================================

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
    final currencyFormat = NumberFormat.currency(
      locale: 'zh_TW',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(context, '月均支出', currencyFormat.format(totalMonthlyCost)),
          Container(width: 1, height: 50, color: Colors.white30),
          _buildItem(context, '年總支出', currencyFormat.format(totalAnnualCost)),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, String amount) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

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
                          // [更新] 這裡顯示通知設定資訊
                          Row(
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
                              if (sub.remindDaysBefore != -1) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.notifications_active,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.primary,
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
                            ],
                          ),
                        ],
                      ),
                    ),
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

// ==========================================
// 8. 表單頁面 (新增/編輯) - 含通知設定
// ==========================================

class SubscriptionFormScreen extends StatefulWidget {
  final Subscription? initialSubscription;
  final List<CategoryModel> categories;

  const SubscriptionFormScreen({
    super.key,
    this.initialSubscription,
    required this.categories,
  });

  @override
  State<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends State<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _noteController;
  late BillingCycle _selectedCycle;
  late DateTime _selectedStartDate;
  late String _selectedCurrency;
  late String _selectedCategoryId;

  // [新增] 通知設定變數
  late int _remindDaysBefore;

  final List<String> _currencies = ['TWD', 'USD', 'JPY', 'EUR', 'CNY'];

  // [新增] 通知選項
  final Map<int, String> _reminderOptions = {
    -1: '不通知',
    0: '付款當天',
    1: '提早 1 天',
    3: '提早 3 天',
    7: '提早 1 週',
  };

  bool get isEditing => widget.initialSubscription != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSubscription;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _costController = TextEditingController(
      text: initial?.cost.toString() ?? '',
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
    _selectedCycle = initial?.cycle ?? BillingCycle.monthly;
    _selectedStartDate = initial?.startDate ?? DateTime.now();
    _selectedCurrency = initial?.currency ?? 'TWD';
    _remindDaysBefore = initial?.remindDaysBefore ?? -1;

    if (initial != null &&
        widget.categories.any((c) => c.id == initial.categoryId)) {
      _selectedCategoryId = initial.categoryId;
    } else {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final subscription = Subscription(
        id: isEditing
            ? widget.initialSubscription!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        cost: double.parse(_costController.text),
        currency: _selectedCurrency,
        cycle: _selectedCycle,
        startDate: _selectedStartDate,
        categoryId: _selectedCategoryId,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        remindDaysBefore: _remindDaysBefore, // 儲存通知設定
      );
      Navigator.pop(context, subscription);
    }
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) setState(() => _selectedStartDate = pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '編輯訂閱' : '新增訂閱'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('基本資訊'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '訂閱名稱',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => v!.isEmpty ? '請輸入名稱' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: '分類',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: widget.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Row(
                      children: [
                        Icon(cat.icon, size: 18, color: cat.color),
                        const SizedBox(width: 8),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v!),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('費用與週期'),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '金額',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) =>
                          (double.tryParse(v ?? '') ?? 0) <= 0 ? '無效金額' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: '幣別',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: _currencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCurrency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<BillingCycle>(
                      value: _selectedCycle,
                      decoration: const InputDecoration(
                        labelText: '繳費週期',
                        prefixIcon: Icon(Icons.update),
                      ),
                      items: BillingCycle.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCycle = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('日期與提醒'),
              InkWell(
                onTap: _presentDatePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '首次付款日期',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'yyyy/MM/dd',
                                ).format(_selectedStartDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Text(
                        '變更',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // [新增] 通知設定下拉選單
              DropdownButtonFormField<int>(
                value: _remindDaysBefore,
                decoration: const InputDecoration(
                  labelText: '付款提醒',
                  prefixIcon: Icon(Icons.notifications_outlined),
                ),
                items: _reminderOptions.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _remindDaysBefore = v!),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('備註 (選填)'),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: '例如：透過信用卡付款、家庭方案...',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? '儲存變更' : '新增訂閱',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'services/services.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';

// ==========================================
// Main App Entry Point
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

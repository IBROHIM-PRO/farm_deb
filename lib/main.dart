import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/app_provider.dart';
import 'providers/history_provider.dart';
import 'providers/cattle_registry_provider.dart';
import 'providers/cotton_registry_provider.dart';
import 'providers/cotton_warehouse_provider.dart';
import 'screens/home_screen.dart';
import 'database/database_helper.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for multiple locales
  try {
    await initializeDateFormatting('tg', null);
    await initializeDateFormatting('tg_TJ', null);
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('ru', null);
    await initializeDateFormatting('ru_RU', null);
  } catch (e) {
    // Fallback to basic locales if specific ones fail
    await initializeDateFormatting('en', null);
    await initializeDateFormatting();
  }
  
  await DatabaseHelper.instance.database;
  runApp(const FarmDebtManagerApp());
}

class FarmDebtManagerApp extends StatelessWidget {
  const FarmDebtManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => CattleRegistryProvider()),
        ChangeNotifierProvider(create: (_) => CottonRegistryProvider()),
        ChangeNotifierProvider(create: (_) => CottonWarehouseProvider()),
      ],
      child: MaterialApp(
        locale: const Locale('tg', ''),
        title: 'Farm & Debt Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.light,
        home: const HomeScreen(),
      ),
    );
  }
}

/* Old theme code - now using AppTheme
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(44, 44), // Minimum touch target
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(44, 44), // Minimum touch target
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44), // Minimum touch target
              padding: const EdgeInsets.all(8),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            height: 64,
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const IconThemeData(size: 26);
              }
              return const IconThemeData(size: 24);
            }),
          ),
          tabBarTheme: const TabBarTheme(
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontSize: 11),
            indicatorSize: TabBarIndicatorSize.label,
          ),
          listTileTheme: const ListTileThemeData(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            dense: true,
            minVerticalPadding: 8,
            minLeadingWidth: 40,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
        ),
*/

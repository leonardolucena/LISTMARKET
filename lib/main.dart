import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/shopping_list_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShoppingListRepository.instance.init();
  runApp(const ListMarketApp());
}

class ListMarketApp extends StatefulWidget {
  const ListMarketApp({super.key});

  @override
  State<ListMarketApp> createState() => _ListMarketAppState();
}

class _ListMarketAppState extends State<ListMarketApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fresh Sprout',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: HomeScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

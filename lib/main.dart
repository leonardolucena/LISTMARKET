import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/shopping_list_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShoppingListRepository.instance.init();
  runApp(const ListMarketApp());
}

class ListMarketApp extends StatelessWidget {
  const ListMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ListMarket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

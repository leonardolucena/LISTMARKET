import 'package:flutter/material.dart';

import '../theme/fresh_sprout_tokens.dart';
import '../widgets/fresh_sprout_bottom_nav.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _navIndex = 0;

  int get _pageIndex {
    return switch (_navIndex) {
      0 => 0,
      1 => 1,
      3 => 2,
      _ => 0,
    };
  }

  void _onNavChanged(int index) {
    if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Em breve')),
      );
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.isDarkMode
        ? FreshSproutColors.darkBackground
        : FreshSproutColors.background;

    return Scaffold(
      backgroundColor: background,
      body: IndexedStack(
        index: _pageIndex,
        children: [
          HomeScreen(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
          ),
          HistoryScreen(isDarkMode: widget.isDarkMode),
          ProfileScreen(
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
          ),
        ],
      ),
      bottomNavigationBar: FreshSproutBottomNav(
        isDarkMode: widget.isDarkMode,
        currentIndex: _navIndex,
        onChanged: _onNavChanged,
      ),
    );
  }
}

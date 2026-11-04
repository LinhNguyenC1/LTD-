import 'package:flutter/material.dart';
import 'core/models/food.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';
import 'features/scan/scan_page.dart';
import 'features/history/history_page.dart';
import 'features/profile/profile_page.dart';
import 'features/product/detail_page.dart';
import 'features/compare/compare_select_page.dart';

void main() => runApp(const AnLanhApp());

class AnLanhApp extends StatelessWidget {
  const AnLanhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ăn Lành',
      theme: buildAppTheme(),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  void openFoodDetail(Food food) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(food: food)),
    );
  }

  void openCompareSelect() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CompareSelectPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onScan: () => setState(() => tab = 1),
        onOpenFood: openFoodDetail,
        onEditProfile: () => setState(() => tab = 3),
        onCompare: openCompareSelect,
      ),
      ScanPage(onOpenFood: openFoodDetail),
      HistoryPage(onOpenFood: openFoodDetail),
      const ProfilePage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE4F1E5),
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: primaryGreen),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner, color: primaryGreen),
            label: 'Quét',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: primaryGreen),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: primaryGreen),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

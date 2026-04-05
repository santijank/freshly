import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/fridge_store.dart';
import 'models/health_store.dart';
import 'models/meal_store.dart';
import 'screens/coach_screen.dart';
import 'screens/health_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/log_meal_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/today_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FridgeStore.instance.load();
  await MealStore.instance.load();
  await HealthStore.instance.load();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NourishApp());
}

class NourishApp extends StatefulWidget {
  const NourishApp({super.key});

  static _NourishAppState of(BuildContext context) {
    return context.findAncestorStateOfType<_NourishAppState>()!;
  }

  @override
  State<NourishApp> createState() => _NourishAppState();
}

class _NourishAppState extends State<NourishApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _themeMode == ThemeMode.dark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  bool get isDark => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MealStore.instance,
      builder: (context, _) {
        final hasProfile = MealStore.instance.hasProfile;
        return MaterialApp(
          title: 'Nourish',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeMode,
          routes: {
            '/main': (context) => const MainShell(),
            '/health': (context) => const HealthScreen(),
          },
          home: hasProfile
              ? const MainShell()
              : const OnboardingScreen(),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 0=Today, 1=Insights, 3=Fridge, 4=Coach
  // Index 2 is center button (not a real tab)
  int _currentIndex = 0;

  // Screens mapped to tab indices (skip center button at visual index 2)
  static const List<Widget> _screens = [
    TodayScreen(),
    InsightsScreen(),
    HomeScreen(),   // Fridge
    CoachScreen(),
  ];

  void _onNavTap(int visualIndex) {
    if (visualIndex == 2) {
      // Center button — open log meal sheet
      showLogMealSheet(context);
      return;
    }
    // Map visual indices to screen indices
    // Visual: 0=วันนี้, 1=สถิติ, 2=+(center), 3=ตู้เย็น, 4=โค้ช
    // Screen: 0, 1, -, 2, 3
    final screenIndex = visualIndex < 2 ? visualIndex : visualIndex - 1;
    setState(() => _currentIndex = screenIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _NourishNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _NourishNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NourishNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = NourishApp.of(context).isDark;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'วันนี้',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'สถิติ',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _LogButton(onTap: () => onTap(2)),
              _NavItem(
                icon: Icons.kitchen_outlined,
                activeIcon: Icons.kitchen_rounded,
                label: 'ตู้เย็น',
                isActive: currentIndex == 2,
                onTap: () => onTap(3),
              ),
              _NavItemWithTheme(
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy_rounded,
                label: 'โค้ช',
                isActive: currentIndex == 3,
                onTap: () => onTap(4),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nav item that also acts as a theme toggle (for the Coach tab with a secondary action)
class _NavItemWithTheme extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItemWithTheme({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => NourishApp.of(context).toggleTheme(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

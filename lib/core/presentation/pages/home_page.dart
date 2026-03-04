import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/wellness_goals/presentation/pages/wellness_goals_page.dart'
    as home;
import '../../../features/diet/presentation/pages/nourish_page.dart';
import '../../../features/meditation/presentation/pages/meditation_page.dart';
import '../../../features/knowledge/presentation/pages/learn_page.dart';
import '../../../features/profile/presentation/pages/profile_page.dart';
import '../../theme/theme_bloc.dart';
import '../../theme/app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    home.HomePage(),      // 0 -- Home
    NourishPage(),        // 1 -- Nourish (Diet)
    MeditationPage(),     // 2 -- Meditate
    LearnPage(),          // 3 -- Learn (Knowledge)
    ProfilePage(),        // 4 -- Profile
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isVintage = themeState.isVintage;

        // Dynamic colors
        final bgColor = ThemeColors.background(mode);
        final activeColor = isVintage ? Colors.black : Colors.white;
        final inactiveColor =
            isVintage ? ThemeColors.vintageTan : Colors.white54;

        return Scaffold(
          backgroundColor: bgColor,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          extendBody: true,
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: isVintage
                      ? Colors.white.withOpacity(0.97)
                      : Colors.black.withOpacity(0.88),
                  border: Border(
                    top: BorderSide(
                      color: isVintage
                          ? ThemeColors.vintageBorder
                          : Colors.white.withOpacity(0.06),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          index: 0,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildNavItem(
                          icon: Icons.restaurant_menu_rounded,
                          label: 'Nourish',
                          index: 1,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildNavItem(
                          icon: Icons.self_improvement_rounded,
                          label: 'Meditate',
                          index: 2,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildNavItem(
                          icon: Icons.auto_stories_rounded,
                          label: 'Learn',
                          index: 3,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildProfileItem(
                          index: 4,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          isVintage: isVintage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required int index,
    required Color activeColor,
    required Color inactiveColor,
    required bool isVintage,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? (isVintage ? Colors.black : Colors.white)
                    : (isVintage
                        ? Colors.black.withOpacity(0.08)
                        : Colors.white.withOpacity(0.12)),
                border: isActive
                    ? null
                    : Border.all(
                        color: inactiveColor.withOpacity(0.3),
                        width: 1.5,
                      ),
              ),
              child: Center(
                child: Text(
                  'JD',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? (isVintage ? Colors.white : Colors.black)
                        : inactiveColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Profile',
              style: GoogleFonts.inter(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

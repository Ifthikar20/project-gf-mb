import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/wellness_goals/presentation/pages/wellness_goals_page.dart'
    as home;
import '../../../features/diet/presentation/pages/calories_page.dart';
import '../../../features/explore/presentation/pages/explore_for_you_page.dart';
import '../../../features/explore/presentation/pages/explore_page.dart';
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

  // Build pages lazily — only the active page is in the widget tree.
  // IndexedStack kept ALL 5 pages alive causing OOM.
  Widget _buildPage() {
    switch (_currentIndex) {
      case 0:
        return const home.HomePage();
      case 1:
        return const CaloriesPage();
      case 2:
        return const ExploreForYouPage();
      case 3:
        return const ExplorePage();
      case 4:
        return const ProfilePage();
      default:
        return const home.HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;

        // Dynamic colors
        final bgColor = ThemeColors.background(mode);
        final activeColor = isLight ? Colors.black : Colors.white;
        final inactiveColor =
            isLight ? ThemeColors.lightTextSecondary : Colors.white54;

        return Scaffold(
          backgroundColor: bgColor,
          body: _buildPage(),
          extendBody: true,
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: isLight
                      ? Colors.white.withOpacity(0.97)
                      : Colors.black.withOpacity(0.88),
                  border: Border(
                    top: BorderSide(
                      color: isLight
                          ? ThemeColors.lightBorder
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
                          icon: Icons.local_fire_department_rounded,
                          label: 'Calories',
                          index: 1,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildNavItem(
                          icon: Icons.explore_rounded,
                          label: 'Explore',
                          index: 2,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildNavItem(
                          icon: Icons.event_note_rounded,
                          label: 'Classes',
                          index: 3,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        _buildProfileItem(
                          index: 4,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          isLight: isLight,
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
    required bool isLight,
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
                    ? (isLight ? Colors.black : Colors.white)
                    : (isLight
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
                        ? (isLight ? Colors.white : Colors.black)
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

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/wellness_goals/presentation/pages/wellness_goals_page.dart'
    as home;
import '../../../features/explore/presentation/pages/explore_page.dart';
import '../../../features/wellness_goals/presentation/pages/goal_management_page.dart';
import '../../../features/wellness_goals/presentation/pages/wellness_checkin_page.dart';
import '../../../features/workouts/presentation/bloc/workout_bloc.dart';
import '../../../features/workouts/presentation/bloc/workout_state.dart';
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
    home.HomePage(),           // 0 -- Home
    GoalManagementPage(),      // 1 -- Goals (was Progress)
    ExplorePage(),             // 2 -- Groups / Explore
    ProfilePage(),             // 3 -- Profile
  ];

  void _onFabTap() {
    // Quick-action: open wellness check-in
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WellnessCheckInPage(),
        fullscreenDialog: true,
      ),
    );
  }

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
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Home
                        _buildNavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          index: 0,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        // Goals (was Progress)
                        _buildNavItem(
                          icon: Icons.flag_rounded,
                          label: 'Goals',
                          index: 1,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),

                        // Center FAB
                        _buildCenterFab(isVintage),

                        // Groups
                        _buildNavItem(
                          icon: Icons.people_rounded,
                          label: 'Groups',
                          index: 2,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                        // Profile — uses avatar circle
                        _buildProfileItem(
                          index: 3,
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
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
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

  Widget _buildCenterFab(bool isVintage) {
    return GestureDetector(
      onTap: _onFabTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isVintage ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isVintage ? Colors.black : Colors.white)
                  .withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: isVintage ? Colors.white : Colors.black,
          size: 28,
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
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar circle
            Container(
              width: 28,
              height: 28,
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
                    fontSize: 10,
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
                fontSize: 10,
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

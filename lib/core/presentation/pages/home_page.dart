import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/wellness_goals/presentation/pages/wellness_goals_page.dart' as home;
import '../../../features/explore/presentation/pages/explore_page.dart';
import '../../../features/meditation/presentation/pages/meditation_page.dart';
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
    home.HomePage(),
    MeditationPage(),
    ExplorePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isVintage = themeState.isVintage;
        
        // Dynamic colors based on theme
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final primaryColor = ThemeColors.primary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        
        return Scaffold(
          backgroundColor: bgColor,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          extendBody: true,
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isVintage 
                      ? Colors.white.withOpacity(0.98) // Clean white for vintage
                      : Colors.black.withOpacity(0.85),
                  border: Border(
                    top: BorderSide(
                      color: isVintage 
                          ? ThemeColors.vintageBorder // Light gray border
                          : Colors.white.withOpacity(0.08),
                      width: isVintage ? 1.0 : 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          index: 0,
                          isVintage: isVintage,
                          primaryColor: primaryColor,
                          textSecondary: textSecondary,
                        ),
                        _buildNavItem(
                          icon: Icons.explore_rounded,
                          label: 'Explore',
                          index: 2,
                          isVintage: isVintage,
                          primaryColor: primaryColor,
                          textSecondary: textSecondary,
                        ),
                        _buildNavItem(
                          icon: Icons.self_improvement_rounded,
                          label: 'Meditate',
                          index: 1,
                          isVintage: isVintage,
                          primaryColor: primaryColor,
                          textSecondary: textSecondary,
                        ),
                        _buildNavItem(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          index: 3,
                          isVintage: isVintage,
                          primaryColor: primaryColor,
                          textSecondary: textSecondary,
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
    required bool isVintage,
    required Color primaryColor,
    required Color textSecondary,
  }) {
    final isActive = _currentIndex == index;
    
    // Theme-aware colors - vintage uses black on white, classic uses white on black
    final activeColor = isVintage ? Colors.black : Colors.white;
    final inactiveColor = isVintage ? ThemeColors.vintageTan : Colors.white54;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

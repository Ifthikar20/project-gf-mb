import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
        final secondaryColor = ThemeColors.secondary(mode);
        final accentColor = ThemeColors.accent(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final errorColor = ThemeColors.error(mode);
        
        // Theme-specific gradients and fonts
        final headerGradient = isVintage
            ? [ThemeColors.vintageBrass.withOpacity(0.3), bgColor]
            : [ThemeColors.classicPrimary.withOpacity(0.3), bgColor];
        
        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: headerGradient,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        children: [
                          // Top bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profile',
                                style: isVintage
                                    ? GoogleFonts.playfairDisplay(
                                        color: textColor,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      )
                                    : TextStyle(
                                        color: textColor,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                              ),
                              Row(
                                children: [
                                  _buildIconButton(Icons.share_outlined, surfaceColor, textSecondary, isVintage ? primaryColor : null),
                                  const SizedBox(width: 8),
                                  _buildIconButton(Icons.settings_outlined, surfaceColor, textSecondary, isVintage ? primaryColor : null),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Profile section - Auth aware
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, authState) {
                              final isLoggedIn = authState is AuthAuthenticated;
                              final user = isLoggedIn ? authState.user : null;
                              final initials = user?.name?.isNotEmpty == true
                                  ? user!.name![0].toUpperCase()
                                  : (user?.email.isNotEmpty == true ? user!.email[0].toUpperCase() : 'G');
                              
                              return Row(
                                children: [
                                  // Avatar with theme-aware styling
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: isVintage ? BorderRadius.circular(12) : null,
                                      shape: isVintage ? BoxShape.rectangle : BoxShape.circle,
                                      border: Border.all(
                                        color: isLoggedIn ? primaryColor : textSecondary.withOpacity(0.5),
                                        width: 2,
                                      ),
                                      boxShadow: isLoggedIn ? [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ] : null,
                                    ),
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: isVintage ? BorderRadius.circular(8) : null,
                                        shape: isVintage ? BoxShape.rectangle : BoxShape.circle,
                                        gradient: isLoggedIn
                                            ? LinearGradient(colors: [primaryColor, isVintage ? ThemeColors.vintageBrass : ThemeColors.classicSecondary])
                                            : null,
                                        color: isLoggedIn ? null : surfaceColor,
                                      ),
                                      child: Center(
                                        child: isLoggedIn
                                            ? Text(
                                                initials,
                                                style: isVintage
                                                    ? GoogleFonts.playfairDisplay(
                                                        color: Colors.white,
                                                        fontSize: 28,
                                                        fontWeight: FontWeight.bold,
                                                      )
                                                    : const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 28,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                              )
                                            : Icon(Icons.person_outline, color: textSecondary, size: 36),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // User info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isLoggedIn ? (user?.name ?? 'User') : 'Guest',
                                          style: isVintage
                                              ? GoogleFonts.playfairDisplay(
                                                  color: textColor,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                )
                                              : TextStyle(
                                                  color: textColor,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isLoggedIn ? user!.email : 'Sign in to sync your progress',
                                          style: isVintage
                                              ? GoogleFonts.lora(
                                                  color: textSecondary.withOpacity(0.8),
                                                  fontSize: 14,
                                                )
                                              : TextStyle(
                                                  color: textSecondary.withOpacity(0.8),
                                                  fontSize: 14,
                                                ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Login/Logout button
                                        isLoggedIn
                                            ? GestureDetector(
                                                onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: errorColor.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(isVintage ? 6 : 20),
                                                    border: Border.all(color: errorColor.withOpacity(0.3)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.logout, color: errorColor, size: 14),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Sign Out',
                                                        style: TextStyle(
                                                          color: errorColor,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : GestureDetector(
                                                onTap: () => context.go('/login'),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [primaryColor, isVintage ? ThemeColors.vintageBrass : ThemeColors.classicSecondary],
                                                    ),
                                                    borderRadius: BorderRadius.circular(isVintage ? 6 : 20),
                                                  ),
                                                  child: Text(
                                                    'Sign In',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          // Stats row
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(isVintage ? 12 : 16),
                              border: isVintage ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('7', 'Day Streak', Icons.local_fire_department, 
                                    isVintage ? ThemeColors.dustyRose : ThemeColors.classicOrange, isVintage, textColor, textSecondary),
                                Container(width: 1, height: 40, color: textSecondary.withOpacity(0.2)),
                                _buildStatItem('23', 'Sessions', Icons.headphones, 
                                    primaryColor, isVintage, textColor, textSecondary),
                                Container(width: 1, height: 40, color: textSecondary.withOpacity(0.2)),
                                _buildStatItem('156', 'Minutes', Icons.timer_outlined, 
                                    isVintage ? ThemeColors.sageGreen : ThemeColors.classicBlue, isVintage, textColor, textSecondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // THEME TOGGLE SECTION
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.read<ThemeBloc>().add(ToggleTheme()),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isVintage
                              ? [ThemeColors.vintageGold.withOpacity(0.2), ThemeColors.vintageBrass.withOpacity(0.1)]
                              : [ThemeColors.classicSecondary.withOpacity(0.2), ThemeColors.classicPrimary.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(isVintage ? 12 : 16),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(isVintage ? 8 : 12),
                            ),
                            child: Icon(
                              isVintage ? Icons.auto_awesome : Icons.dark_mode,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isVintage ? 'Vintage Theme' : 'Classic Dark Theme',
                                  style: isVintage
                                      ? GoogleFonts.playfairDisplay(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isVintage 
                                      ? 'Tap to switch to Classic Dark' 
                                      : 'Tap to switch to Vintage',
                                  style: TextStyle(
                                    color: textSecondary.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.swap_horiz,
                            color: primaryColor,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Membership Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Membership', textColor, primaryColor, isVintage),
                      const SizedBox(height: 12),
                      // Premium Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isVintage
                                ? [ThemeColors.vintageGold, ThemeColors.vintageBrass, const Color(0xFF8B6914)]
                                : [const Color(0xFFFFD700), const Color(0xFFFFA500), const Color(0xFFFF8C00)],
                          ),
                          borderRadius: BorderRadius.circular(isVintage ? 12 : 20),
                          boxShadow: [
                            BoxShadow(
                              color: (isVintage ? ThemeColors.vintageGold : const Color(0xFFFFD700)).withOpacity(0.3),
                              blurRadius: isVintage ? 16 : 20,
                              offset: Offset(0, isVintage ? 8 : 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(isVintage ? 8 : 12),
                                  ),
                                  child: const Icon(Icons.star, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Free Plan',
                                        style: isVintage
                                            ? GoogleFonts.playfairDisplay(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              )
                                            : const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                      ),
                                      Text(
                                        'Limited access to content',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.white.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Upgrade to unlock all content, exclusive features & ad-free experience',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isVintage ? 6 : 24),
                                  ),
                                  child: Text(
                                    'Upgrade',
                                    style: TextStyle(
                                      color: isVintage ? ThemeColors.vintageGold : const Color(0xFFFFA500),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Library Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.push(AppRouter.library),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(isVintage ? 12 : 16),
                        border: isVintage ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isVintage ? ThemeColors.dustyRose : ThemeColors.classicRed).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(isVintage ? 8 : 12),
                            ),
                            child: Icon(Icons.favorite, color: isVintage ? ThemeColors.dustyRose : ThemeColors.classicRed, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Library',
                                  style: isVintage
                                      ? GoogleFonts.playfairDisplay(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Liked videos and saved content',
                                  style: TextStyle(
                                    color: textSecondary.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: textSecondary.withOpacity(0.5), size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Watch History Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.push(AppRouter.watchHistory),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(isVintage ? 12 : 16),
                        border: isVintage ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isVintage ? ThemeColors.vintageGold : ThemeColors.classicBlue).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(isVintage ? 8 : 12),
                            ),
                            child: Icon(Icons.history, color: isVintage ? ThemeColors.vintageGold : ThemeColors.classicBlue, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Watch History',
                                  style: isVintage
                                      ? GoogleFonts.playfairDisplay(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Recently viewed videos and audio',
                                  style: TextStyle(
                                    color: textSecondary.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: textSecondary.withOpacity(0.5), size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Account Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildSection('Account', [
                    _MenuItem(Icons.person_outline, 'Personal Information', 'Name, email, phone'),
                    _MenuItem(Icons.lock_outline, 'Password & Security', 'Password, 2FA'),
                    _MenuItem(Icons.payment_outlined, 'Payment Methods', 'Cards, subscriptions'),
                  ], surfaceColor, textColor, textSecondary, primaryColor, isVintage),
                ),
              ),

              // Preferences Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildSection('Preferences', [
                    _MenuItem(Icons.notifications_outlined, 'Notifications', 'Push, email alerts'),
                    _MenuItem(Icons.language_outlined, 'Language', 'English (US)'),
                    _MenuItem(Icons.download_outlined, 'Downloads', 'Offline content'),
                  ], surfaceColor, textColor, textSecondary, primaryColor, isVintage),
                ),
              ),

              // Support Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildSection('Support', [
                    _MenuItem(Icons.help_outline, 'Help Center', 'FAQs, tutorials'),
                    _MenuItem(Icons.chat_bubble_outline, 'Contact Us', 'Get in touch'),
                    _MenuItem(Icons.bug_report_outlined, 'Report a Problem', 'Send feedback'),
                    _MenuItem(Icons.info_outline, 'About', 'Version, legal'),
                  ], surfaceColor, textColor, textSecondary, primaryColor, isVintage),
                ),
              ),

              // Sign Out
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isVintage ? 12 : 16),
                        border: Border.all(color: errorColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: errorColor),
                          const SizedBox(width: 12),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: errorColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // App version
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Wellness App v1.0.0',
                      style: TextStyle(
                        color: textSecondary.withOpacity(0.5),
                        fontSize: 12,
                        fontStyle: isVintage ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, Color surfaceColor, Color iconColor, Color? borderColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null ? Border.all(color: borderColor.withOpacity(0.2)) : null,
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor, Color primaryColor, bool isVintage) {
    return Row(
      children: [
        Text(
          title,
          style: isVintage
              ? GoogleFonts.playfairDisplay(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )
              : TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
        ),
        if (isVintage) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.4), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color, bool isVintage, Color textColor, Color textSecondary) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: isVintage
                  ? GoogleFonts.playfairDisplay(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    )
                  : TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textSecondary.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<_MenuItem> items, Color surfaceColor, Color textColor, Color textSecondary, Color primaryColor, bool isVintage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, textColor, primaryColor, isVintage),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(isVintage ? 12 : 16),
            border: isVintage ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return Column(
                children: [
                  GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isVintage 
                                  ? primaryColor.withOpacity(0.1) 
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(isVintage ? 8 : 10),
                            ),
                            child: Icon(item.icon, color: isVintage ? primaryColor : Colors.white70, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    color: textSecondary.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: textSecondary.withOpacity(0.4), size: 20),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 58),
                      child: Divider(color: textSecondary.withOpacity(0.15), height: 1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  
  const _MenuItem(this.icon, this.title, this.subtitle);
}

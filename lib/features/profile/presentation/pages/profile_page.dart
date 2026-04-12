import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/auth/auth_bloc.dart';

import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../wellness_goals/presentation/bloc/goals_bloc.dart';
import '../../../wellness_goals/presentation/bloc/goals_state.dart';

import '../../../wellness_goals/domain/entities/goal_entity.dart';
import '../../../wellness_goals/presentation/widgets/goal_picker_sheet.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../../core/services/workout_plan_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;
        
        // Dynamic colors based on theme
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final primaryColor = ThemeColors.primary(mode);

        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final errorColor = ThemeColors.error(mode);
        
        
        
        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Profile Header with background image
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Background image
                    SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: Image.asset(
                        'assets/images/bk-1.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            bgColor.withValues(alpha: 0.5),
                            bgColor,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                    // Content on top of image
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          children: [
                            // Top bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Profile',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                    // Avatar
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          width: 2,
                                        ),
                                        boxShadow: isLoggedIn ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ] : null,
                                      ),
                                      child: Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: isLoggedIn
                                              ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)])
                                              : null,
                                          color: isLoggedIn ? null : surfaceColor,
                                        ),
                                        child: Center(
                                          child: isLoggedIn
                                              ? Text(
                                                  initials,
                                                  style: GoogleFonts.inter(
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
                                            style: GoogleFonts.inter(
                                              color: textColor,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isLoggedIn ? user!.email : 'Sign in to sync your progress',
                                            style: GoogleFonts.inter(
                                              color: textSecondary.withValues(alpha: 0.8),
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
                                                      color: errorColor.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: errorColor.withValues(alpha: 0.3)),
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
                                                        colors: [primaryColor, isLight ? ThemeColors.lightTextSecondary : ThemeColors.darkSecondary],
                                                      ),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Text(
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
                            // Goals Stats Row
                            BlocBuilder<GoalsBloc, GoalsState>(
                              builder: (context, goalsState) {
                                if (goalsState is! GoalsLoaded) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Loading goals...',
                                        style: TextStyle(color: textSecondary, fontSize: 14),
                                      ),
                                    ),
                                  );
                                }
                                
                                final activeGoals = goalsState.goals
                                    .where((g) => !g.isCompleted)
                                    .take(3)
                                    .toList();
                                
                                if (activeGoals.isEmpty) {
                                  return GestureDetector(
                                    onTap: () => _showGoalPicker(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: surfaceColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: primaryColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_circle_outline, color: textSecondary, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Set Your First Goal',
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      for (int i = 0; i < activeGoals.length; i++) ...[
                                        if (i > 0)
                                          Container(width: 1, height: 45, color: textSecondary.withValues(alpha: 0.2)),
                                        Expanded(
                                          child: _buildGoalStatItem(
                                            activeGoals[i],
                                            isLight,
                                            textColor,
                                            textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                          colors: isLight
                              ? [ThemeColors.lightPrimary.withOpacity(0.2), ThemeColors.lightTextSecondary.withOpacity(0.1)]
                              : [Colors.grey.shade800.withOpacity(0.3), Colors.grey.shade700.withOpacity(0.2)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: textSecondary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: textSecondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isLight ? Icons.light_mode : Icons.dark_mode,
                              color: textColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLight ? 'Light Theme' : 'Dark Theme',
                                  style: isLight
                                      ? GoogleFonts.inter(
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
                                  isLight 
                                      ? 'Tap to switch to Classic Dark' 
                                      : 'Tap to switch to Light mode',
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
                            color: textSecondary,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Membership Section (dynamic based on subscription)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Membership', textColor, primaryColor, isLight),
                      const SizedBox(height: 12),
                      BlocBuilder<SubscriptionBloc, SubscriptionState>(
                        builder: (context, subState) {
                          final sub = context.read<SubscriptionBloc>().lastStatus;
                          final tier = sub?.tier ?? 'free';
                          final isFree = tier == 'free';
                          final planName = '${tier[0].toUpperCase()}${tier.substring(1)} Plan';
                          final planDescription = isFree
                              ? 'Limited access to content'
                              : tier == 'basic'
                                  ? '720p streaming, food scanner, 1 coaching session/mo'
                                  : 'Full HD, wearable sync, unlimited coaching';

                          return GestureDetector(
                            onTap: () => context.push(AppRouter.subscriptionPlans),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isFree
                                      ? (isLight
                                          ? [const Color(0xFF3D3D3D), const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)]
                                          : [const Color(0xFF404040), const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)])
                                      : tier == 'basic'
                                          ? [const Color(0xFF1E40AF), const Color(0xFF1D4ED8)]
                                          : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
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
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isFree ? Icons.star : Icons.workspace_premium,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              planName,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              planDescription,
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
                                          isFree
                                              ? 'Upgrade to unlock all content, exclusive features & ad-free experience'
                                              : 'Manage your subscription, upgrade, or view billing',
                                          style: const TextStyle(
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
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isFree ? 'Upgrade' : 'Manage',
                                          style: const TextStyle(
                                            color: Color(0xFF1A1A1A),
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
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Marketplace & Coaching Quick Access
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push(AppRouter.marketplace),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.storefront_outlined, color: Color(0xFFF59E0B), size: 24),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Marketplace',
                                  style: GoogleFonts.inter(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Browse programs',
                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push(AppRouter.coaches),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.video_camera_front_outlined, color: Color(0xFF8B5CF6), size: 24),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Live Coaching',
                                  style: GoogleFonts.inter(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '1:1 video sessions',
                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // My Workout Plan — Premium only
              SliverToBoxAdapter(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final user = authState is AuthAuthenticated ? authState.user : null;
                    if (user == null || !user.isPremium) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: GestureDetector(
                        onTap: () => context.push(AppRouter.myWorkoutPlan),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF22C55E), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'My Workout Plan',
                                      style: GoogleFonts.inter(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Your personalised plan from your coach',
                                      style: TextStyle(color: textSecondary.withOpacity(0.7), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: textSecondary.withOpacity(0.5), size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isLight ? ThemeColors.lightSecondary : ThemeColors.darkError).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.favorite, color: isLight ? ThemeColors.lightSecondary : ThemeColors.darkError, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Library',
                                  style: isLight
                                      ? GoogleFonts.inter(
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isLight ? ThemeColors.lightPrimary : ThemeColors.darkPrimary).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.history, color: isLight ? ThemeColors.lightPrimary : ThemeColors.darkPrimary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Watch History',
                                  style: isLight
                                      ? GoogleFonts.inter(
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

              // Wellness Journal Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.push(AppRouter.journal),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.withOpacity(0.15),
                            Colors.indigo.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.auto_awesome, color: Colors.deepPurple.shade200, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wellness Journal',
                                  style: isLight
                                      ? GoogleFonts.inter(
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
                                  'Mood tracking & AI wellness insights',
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

              // Wellness Score & Sleep Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push(AppRouter.wellnessScore),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF22C55E).withOpacity(0.12),
                                  const Color(0xFF16A34A).withOpacity(0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.15)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.speed, color: Color(0xFF22C55E), size: 24),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Wellness Score',
                                  style: isLight
                                      ? GoogleFonts.inter(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)
                                      : TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Daily health score',
                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push(AppRouter.sleepDashboard),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF8B5CF6).withOpacity(0.12),
                                  const Color(0xFF7C3AED).withOpacity(0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.15)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.nightlight_round, color: Color(0xFF8B5CF6), size: 24),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Sleep Insights',
                                  style: isLight
                                      ? GoogleFonts.inter(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)
                                      : TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Quality & trends',
                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Account Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildSection(context, 'Account', [
                    _MenuItem(Icons.person_outline, 'Personal Information', 'Name, email, phone', route: '/account-settings'),
                    _MenuItem(Icons.lock_outline, 'Password & Security', 'Password, 2FA', route: '/change-password'),
                    _MenuItem(Icons.payment_outlined, 'Payment Methods', 'Cards, subscriptions'),
                  ], surfaceColor, textColor, textSecondary, primaryColor, isLight),
                ),
              ),

              // Preferences Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildSection(context, 'Preferences', [
                    _MenuItem(Icons.notifications_outlined, 'Notifications', 'Push, email alerts'),
                    _MenuItem(Icons.language_outlined, 'Language', 'English (US)'),
                    _MenuItem(Icons.download_outlined, 'Downloads', 'Offline content'),
                  ], surfaceColor, textColor, textSecondary, primaryColor, isLight),
                ),
              ),

              // Food Sharing Toggle — Premium only
              SliverToBoxAdapter(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final user = authState is AuthAuthenticated ? authState.user : null;
                    if (user == null || !user.isPremium) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _FoodSharingTile(
                        initialValue: user.shareFoodDataWithCoach,
                        isLight: isLight,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        textSecondary: textSecondary,
                        borderColor: isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder,
                        primaryColor: primaryColor,
                      ),
                    );
                  },
                ),
              ),

              // Wellness Setup Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.push(AppRouter.onboarding),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.tune, color: Color(0xFF8B5CF6), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Redo Wellness Setup',
                                  style: isLight
                                      ? GoogleFonts.inter(
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
                                  'Update your goals and preferences',
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

              // Support Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildSection(context, 'Support', [
                    _MenuItem(Icons.help_outline, 'Help Center', 'FAQs, tutorials'),
                    _MenuItem(Icons.chat_bubble_outline, 'Contact Us', 'Get in touch', route: AppRouter.antigravityChat),
                    _MenuItem(Icons.bug_report_outlined, 'Report a Problem', 'Send feedback'),
                    _MenuItem(Icons.info_outline, 'About', 'Version, legal'),
                  ], surfaceColor, textColor, textSecondary, primaryColor, isLight),
                ),
              ),

              // Sign Out
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
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
                        fontStyle: FontStyle.normal,
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

  Widget _buildSectionTitle(String title, Color textColor, Color primaryColor, bool isLight) {
    return Row(
      children: [
        Text(
          title,
          style: isLight
              ? GoogleFonts.inter(
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
        if (isLight) ...[
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

  Widget _buildSection(BuildContext context, String title, List<_MenuItem> items, Color surfaceColor, Color textColor, Color textSecondary, Color primaryColor, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, textColor, primaryColor, isLight),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isLight ? ThemeColors.lightBorder : ThemeColors.darkBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return Column(
                children: [
                  GestureDetector(
                    onTap: item.route != null ? () => context.push(item.route!) : null,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLight 
                                  ? primaryColor.withOpacity(0.1) 
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(isLight ? 8 : 10),
                            ),
                            child: Icon(item.icon, color: isLight ? primaryColor : Colors.white70, size: 20),
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



  Color _getGoalColor(GoalType type, Color defaultColor) {
    switch (type) {
      case GoalType.videoCompletion:
        return const Color(0xFF7C3AED);
      case GoalType.audioCompletion:
        return const Color(0xFF8B5CF6);
      case GoalType.dailyStreak:
        return const Color(0xFFEF4444);
      case GoalType.weeklyUsage:
        return const Color(0xFF3B82F6);
      case GoalType.categoryExplore:
        return const Color(0xFF06B6D4);
      case GoalType.watchTime:
        return const Color(0xFF14B8A6);
      case GoalType.manual:
        return defaultColor;
    }
  }

  void _showGoalPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GoalPickerSheet(),
    );
  }

  Widget _buildGoalStatItem(
    GoalEntity goal,
    bool isLight,
    Color textColor,
    Color textSecondary,
  ) {
    final color = _getGoalColor(goal.type, const Color(0xFF7C3AED));
    final icon = _getGoalIcon(goal.type);
    final progressPercent = (goal.progress * 100).toInt();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular progress with icon
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: goal.progress,
                strokeWidth: 3,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Icon(icon, color: color, size: 18),
          ],
        ),
        const SizedBox(height: 6),
        // Progress text
        Text(
          '$progressPercent%',
          style: isLight
              ? GoogleFonts.inter(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                )
              : TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
        ),
        const SizedBox(height: 2),
        // Goal label (truncated)
        SizedBox(
          width: 80,
          child: Text(
            _getGoalLabel(goal),
            style: TextStyle(
              color: textSecondary.withOpacity(0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getGoalIcon(GoalType type) {
    switch (type) {
      case GoalType.videoCompletion:
        return Icons.play_circle_filled;
      case GoalType.audioCompletion:
        return Icons.headphones;
      case GoalType.dailyStreak:
        return Icons.local_fire_department;
      case GoalType.weeklyUsage:
        return Icons.calendar_today;
      case GoalType.categoryExplore:
        return Icons.explore;
      case GoalType.watchTime:
        return Icons.timer;
      case GoalType.manual:
        return Icons.flag;
    }
  }

  String _getGoalLabel(GoalEntity goal) {
    switch (goal.type) {
      case GoalType.dailyStreak:
        return '${goal.currentValue}/${goal.targetValue} Days';
      case GoalType.watchTime:
        return '${goal.currentValue}/${goal.targetValue} Min';
      case GoalType.videoCompletion:
        return '${goal.currentValue}/${goal.targetValue} Videos';
      case GoalType.audioCompletion:
        return '${goal.currentValue}/${goal.targetValue} Sessions';
      case GoalType.weeklyUsage:
        return '${goal.currentValue}/${goal.targetValue} Days';
      case GoalType.categoryExplore:
        return '${goal.currentValue}/${goal.targetValue} Categories';
      case GoalType.manual:
        return '${goal.currentValue}/${goal.targetValue}';
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;

  const _MenuItem(this.icon, this.title, this.subtitle, {this.route});
}

/// Self-contained toggle for sharing food data with a coach.
/// Manages its own API call and optimistic UI update.
class _FoodSharingTile extends StatefulWidget {
  final bool initialValue;
  final bool isLight;
  final Color surfaceColor;
  final Color textColor;
  final Color textSecondary;
  final Color borderColor;
  final Color primaryColor;

  const _FoodSharingTile({
    required this.initialValue,
    required this.isLight,
    required this.surfaceColor,
    required this.textColor,
    required this.textSecondary,
    required this.borderColor,
    required this.primaryColor,
  });

  @override
  State<_FoodSharingTile> createState() => _FoodSharingTileState();
}

class _FoodSharingTileState extends State<_FoodSharingTile> {
  late bool _enabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialValue;
  }

  Future<void> _toggle(bool value) async {
    setState(() { _enabled = value; _saving = true; });
    try {
      final result = await WorkoutPlanService.instance.setFoodSharing(enabled: value);
      if (mounted) setState(() { _enabled = result; _saving = false; });
    } catch (_) {
      // Revert on failure
      if (mounted) setState(() { _enabled = !value; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isLight
                    ? widget.primaryColor.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(widget.isLight ? 8 : 10),
              ),
              child: Icon(Icons.restaurant_outlined,
                  color: widget.isLight ? widget.primaryColor : Colors.white70, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share food data with coach',
                    style: TextStyle(
                        color: widget.textColor, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Let your coach see your food scan history for better meal recommendations.',
                    style: TextStyle(color: widget.textSecondary.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: widget.primaryColor, strokeWidth: 2),
                  )
                : Switch.adaptive(
                    value: _enabled,
                    onChanged: _toggle,
                    activeColor: widget.primaryColor,
                  ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/subscription_bloc.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(LoadSubscriptionStatus());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final primaryColor = ThemeColors.primary(mode);
        final borderColor = ThemeColors.border(mode);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Choose Your Plan',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
            listener: (context, state) {
              if (state is SubscriptionCheckoutReady) {
                _openCheckout(state.checkoutUrl);
              } else if (state is SubscriptionPortalReady) {
                _openPortal(state.portalUrl);
              } else if (state is SubscriptionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              final currentTier =
                  context.read<SubscriptionBloc>().lastStatus?.tier ?? 'free';
              final isLoading = state is SubscriptionLoading;

              if (state is SubscriptionLoaded) {
                // Use latest status
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  children: [
                    // Current plan indicator
                    if (currentTier != 'free') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF22C55E).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF22C55E),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'You\'re on the ${currentTier[0].toUpperCase()}${currentTier.substring(1)} plan',
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context
                                  .read<SubscriptionBloc>()
                                  .add(OpenBillingPortal()),
                              child: Text(
                                'Manage',
                                style: GoogleFonts.inter(
                                  color: primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Free Plan
                    _buildPlanCard(
                      tier: 'free',
                      name: 'Free',
                      price: '\$0',
                      period: '/month',
                      features: [
                        'Browse content library',
                        'Limited food scanner',
                        'Basic wellness tracking',
                      ],
                      currentTier: currentTier,
                      isLight: isLight,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      primaryColor: primaryColor,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Basic Plan
                    _buildPlanCard(
                      tier: 'basic',
                      name: 'Basic',
                      price: '\$9.99',
                      period: '/month',
                      features: [
                        'Stream in 720p',
                        'Full food scanner access',
                        '1 coaching session/month',
                        'All content categories',
                      ],
                      currentTier: currentTier,
                      isLight: isLight,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      primaryColor: primaryColor,
                      isLoading: isLoading,
                      isPopular: true,
                    ),
                    const SizedBox(height: 16),

                    // Premium Plan
                    _buildPlanCard(
                      tier: 'premium',
                      name: 'Premium',
                      price: '\$19.99',
                      period: '/month',
                      features: [
                        'Stream in 1080p HD',
                        'Wearable sync (Apple Health)',
                        'Unlimited coaching sessions',
                        'Offline downloads',
                        '20% coaching discount',
                      ],
                      currentTier: currentTier,
                      isLight: isLight,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      primaryColor: primaryColor,
                      isLoading: isLoading,
                      isPremium: true,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlanCard({
    required String tier,
    required String name,
    required String price,
    required String period,
    required List<String> features,
    required String currentTier,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
    required bool isLoading,
    bool isPopular = false,
    bool isPremium = false,
  }) {
    final isCurrentPlan = tier == currentTier;
    const tierOrder = ['free', 'basic', 'premium'];
    final isDowngrade =
        tierOrder.indexOf(tier) < tierOrder.indexOf(currentTier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPremium
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFF1A1A2E), const Color(0xFF0F3460)],
              )
            : null,
        color: isPremium ? null : surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: primaryColor, width: 2)
            : (isPremium
                ? null
                : Border.all(color: borderColor)),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  color: isPremium ? Colors.white : textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (isPopular)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Popular',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (isCurrentPlan)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    'Current',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF22C55E),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.inter(
                  color: isPremium ? Colors.white : textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  period,
                  style: GoogleFonts.inter(
                    color: isPremium
                        ? Colors.white.withOpacity(0.7)
                        : textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_rounded,
                    color: isPremium
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF22C55E),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: GoogleFonts.inter(
                        color: isPremium
                            ? Colors.white.withOpacity(0.9)
                            : textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!isCurrentPlan && tier != 'free')
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: isLoading || isDowngrade
                    ? null
                    : () {
                        if (currentTier != 'free') {
                          // Already subscribed — open billing portal to change
                          context
                              .read<SubscriptionBloc>()
                              .add(OpenBillingPortal());
                        } else {
                          context
                              .read<SubscriptionBloc>()
                              .add(CreateCheckout(tier: tier));
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? Colors.white
                        : (isLoading ? primaryColor.withOpacity(0.5) : primaryColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isPremium ? Colors.black : Colors.white,
                            ),
                          )
                        : Text(
                            isDowngrade ? 'Manage Plan' : 'Get Started',
                            style: GoogleFonts.inter(
                              color: isPremium ? Colors.black : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openCheckout(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // After returning, refresh subscription status
      if (mounted) {
        context.read<SubscriptionBloc>().add(RefreshSubscription());
      }
    }
  }

  Future<void> _openPortal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        context.read<SubscriptionBloc>().add(RefreshSubscription());
      }
    }
  }
}

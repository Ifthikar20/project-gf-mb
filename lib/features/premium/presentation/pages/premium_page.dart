import 'package:flutter/material.dart';
import 'dart:math' as math;

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> with SingleTickerProviderStateMixin {
  int _selectedPlan = 1; // 0 = monthly, 1 = yearly
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _GradientPainter(_controller.value),
                size: Size.infinite,
              );
            },
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Premium badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Headline
                    const Text(
                      'Unlock Your\nFull Potential',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Start your journey to inner peace',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Features in glass cards
                    _buildFeatureRow(
                      Icons.all_inclusive,
                      'Unlimited Access',
                      '500+ meditations',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      Icons.cloud_download_outlined,
                      'Offline Mode',
                      'Download & listen anywhere',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      Icons.music_note_outlined,
                      'Exclusive Content',
                      'New sessions daily',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      Icons.schedule_outlined,
                      'Sleep Stories',
                      'Drift off peacefully',
                    ),

                    const SizedBox(height: 40),

                    // Plan selection
                    Row(
                      children: [
                        Expanded(
                          child: _buildPlanCard(
                            index: 0,
                            title: 'Monthly',
                            price: '\$9.99',
                            period: '/month',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPlanCard(
                            index: 1,
                            title: 'Yearly',
                            price: '\$59.99',
                            period: '/year',
                            badge: 'SAVE 50%',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // CTA Button
                    GestureDetector(
                      onTap: () {
                        // Handle subscription
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1DB954).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Start 7-Day Free Trial',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Cancel anytime • No commitment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Trust badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTrustBadge(Icons.verified_user_outlined, 'Secure'),
                        const SizedBox(width: 24),
                        _buildTrustBadge(Icons.lock_outline, 'Private'),
                        const SizedBox(width: 24),
                        _buildTrustBadge(Icons.star_outline, '4.9 Rating'),
                      ],
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1DB954).withOpacity(0.2),
                  const Color(0xFF7C3AED).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1DB954), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF1DB954), size: 22),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String period,
    String? badge,
  }) {
    final isSelected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1DB954).withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF1DB954)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1DB954) : Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              period,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF1DB954) : Colors.transparent,
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF1DB954)
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white38, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _GradientPainter extends CustomPainter {
  final double animation;
  _GradientPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Moving gradient circles
    final center1 = Offset(
      size.width * (0.3 + 0.2 * math.sin(animation * 2 * math.pi)),
      size.height * (0.2 + 0.1 * math.cos(animation * 2 * math.pi)),
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF1DB954).withOpacity(0.3),
        const Color(0xFF1DB954).withOpacity(0.0),
      ],
    ).createShader(Rect.fromCenter(center: center1, width: 400, height: 400));
    canvas.drawCircle(center1, 200, paint);

    final center2 = Offset(
      size.width * (0.7 + 0.15 * math.cos(animation * 2 * math.pi + 1)),
      size.height * (0.6 + 0.15 * math.sin(animation * 2 * math.pi + 1)),
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF7C3AED).withOpacity(0.25),
        const Color(0xFF7C3AED).withOpacity(0.0),
      ],
    ).createShader(Rect.fromCenter(center: center2, width: 350, height: 350));
    canvas.drawCircle(center2, 175, paint);

    final center3 = Offset(
      size.width * (0.2 + 0.1 * math.sin(animation * 2 * math.pi + 2)),
      size.height * (0.8 + 0.1 * math.cos(animation * 2 * math.pi + 2)),
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFEC4899).withOpacity(0.2),
        const Color(0xFFEC4899).withOpacity(0.0),
      ],
    ).createShader(Rect.fromCenter(center: center3, width: 300, height: 300));
    canvas.drawCircle(center3, 150, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}

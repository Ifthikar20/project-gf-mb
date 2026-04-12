import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/wellness_score_bloc.dart';
import '../bloc/wellness_score_event.dart';
import '../bloc/wellness_score_state.dart';
import '../../domain/entities/wellness_score.dart';
import '../widgets/score_ring_widget.dart';
import '../widgets/sub_score_bar.dart';
import '../widgets/score_trend_chart.dart';

/// Full Wellness Score page with animated ring, sub-score bars, and trend chart.
class WellnessScorePage extends StatefulWidget {
  const WellnessScorePage({super.key});

  @override
  State<WellnessScorePage> createState() => _WellnessScorePageState();
}

class _WellnessScorePageState extends State<WellnessScorePage> {
  @override
  void initState() {
    super.initState();
    context.read<WellnessScoreBloc>().add(const WellnessScoreLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: BlocBuilder<WellnessScoreBloc, WellnessScoreState>(
        builder: (context, state) {
          if (state is WellnessScoreLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF22C55E)),
            );
          }

          if (state is WellnessScoreError) {
            return _buildErrorState(state.message);
          }

          if (state is WellnessScoreLoaded) {
            return _buildLoadedState(context, state);
          }

          // Initial state — trigger load
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF22C55E)),
          );
        },
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, WellnessScoreLoaded state) {
    final score = state.score;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<WellnessScoreBloc>().add(const WellnessScoreLoadRequested());
      },
      color: const Color(0xFF22C55E),
      child: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Wellness Score',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white54, size: 22),
                onPressed: () {
                  context.read<WellnessScoreBloc>().add(const WellnessScoreLoadRequested());
                },
              ),
            ],
          ),

          // Score Ring Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  // Main score ring
                  ScoreRingWidget(
                    score: score.totalScore,
                    size: 200,
                    strokeWidth: 16,
                    label: score.label,
                  ),
                  const SizedBox(height: 16),
                  // Trend indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          score.trend.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          score.trend == ScoreTrend.up
                              ? 'Trending up from yesterday'
                              : score.trend == ScoreTrend.down
                                  ? 'Trending down from yesterday'
                                  : 'Holding steady',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sub-scores Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Score Breakdown',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Weight',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...score.allSubScores.map((sub) => SubScoreBar(subScore: sub)),
                  ],
                ),
              ),
            ),
          ),

          // Weakest Area Nudge
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Text(
                      score.weakestArea.category.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus Area: ${score.weakestArea.category.label}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getNudgeText(score.weakestArea),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Trend Chart Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7-Day Trend',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ScoreTrendChart(
                      history: state.history,
                      daysToShow: 7,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Improve Your Score',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuickAction(
                        '😴',
                        'Sleep',
                        'View insights',
                        () => context.push('/sleep-dashboard'),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        '📓',
                        'Journal',
                        'Log mood',
                        () => context.push('/journal'),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        '🍎',
                        'Nutrition',
                        'Scan food',
                        () => context.push('/diet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String emoji, String title, String subtitle, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNudgeText(SubScore sub) {
    switch (sub.category) {
      case ScoreCategory.sleep:
        return 'Try improving your sleep quality for a big score boost.';
      case ScoreCategory.activity:
        return 'A short walk today could raise your activity score.';
      case ScoreCategory.nutrition:
        return 'Log your meals to improve your nutrition score.';
      case ScoreCategory.workout:
        return 'Even 15 minutes of exercise counts toward your score.';
      case ScoreCategory.mood:
        return 'Check in with your mood to track how you\'re feeling.';
      case ScoreCategory.streak:
        return 'Keep your streak going by completing a daily goal.';
    }
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<WellnessScoreBloc>().add(const WellnessScoreLoadRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

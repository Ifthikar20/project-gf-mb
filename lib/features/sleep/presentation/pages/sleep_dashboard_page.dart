import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../wellness_score/presentation/widgets/score_ring_widget.dart';
import '../bloc/sleep_bloc.dart';
import '../bloc/sleep_event.dart';
import '../bloc/sleep_state.dart';
import '../../domain/entities/sleep_data.dart';
import '../widgets/sleep_quality_chart.dart';
import '../widgets/bedtime_consistency_widget.dart';

/// Full Sleep Insights Dashboard with score, weekly chart, and tips.
class SleepDashboardPage extends StatefulWidget {
  const SleepDashboardPage({super.key});

  @override
  State<SleepDashboardPage> createState() => _SleepDashboardPageState();
}

class _SleepDashboardPageState extends State<SleepDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<SleepBloc>().add(const SleepLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: BlocBuilder<SleepBloc, SleepState>(
        builder: (context, state) {
          if (state is SleepLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            );
          }

          if (state is SleepError) {
            return _buildErrorState(state.message);
          }

          if (state is SleepLoaded) {
            return _buildLoadedState(context, state);
          }

          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
          );
        },
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, SleepLoaded state) {
    final score = state.sleepScore;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SleepBloc>().add(const SleepLoadRequested());
      },
      color: const Color(0xFF8B5CF6),
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
              'Sleep Insights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),

          // Sleep Score Ring
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  ScoreRingWidget(
                    score: score.score,
                    size: 180,
                    strokeWidth: 14,
                    label: score.label,
                  ),
                  const SizedBox(height: 12),
                  // Trend badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTrendColor(score.trend).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getTrendColor(score.trend).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(score.trend.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          score.trend.label,
                          style: TextStyle(
                            color: _getTrendColor(score.trend),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Consistency & Quality Metrics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: BedtimeConsistencyWidget(
                consistency: score.consistency,
                avgQuality: score.avgQuality,
              ),
            ),
          ),

          // Weekly Sleep Quality Chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                        const Text(
                          '🌙',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Weekly Sleep Quality',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SleepQualityChart(weeklyData: score.weeklyData),
                  ],
                ),
              ),
            ),
          ),

          // Sleep Insights & Tips
          if (state.insights.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Sleep Tips',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...state.insights.map((insight) => _buildInsightCard(insight)),
                  ],
                ),
              ),
            ),

          // Quality Legend
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quality Scale',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLegendItem(1, 'Awful', const Color(0xFFEF4444)),
                        _buildLegendItem(2, 'Poor', const Color(0xFFF97316)),
                        _buildLegendItem(3, 'Okay', const Color(0xFFEAB308)),
                        _buildLegendItem(4, 'Good', const Color(0xFF84CC16)),
                        _buildLegendItem(5, 'Great', const Color(0xFF22C55E)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(SleepInsight insight) {
    Color borderColor;
    Color bgColor;
    switch (insight.category) {
      case 'celebration':
        borderColor = const Color(0xFF22C55E).withOpacity(0.2);
        bgColor = const Color(0xFF22C55E).withOpacity(0.06);
        break;
      case 'warning':
        borderColor = const Color(0xFFF97316).withOpacity(0.2);
        bgColor = const Color(0xFFF97316).withOpacity(0.06);
        break;
      default:
        borderColor = const Color(0xFF8B5CF6).withOpacity(0.2);
        bgColor = const Color(0xFF8B5CF6).withOpacity(0.06);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(insight.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.body,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(int value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getTrendColor(SleepTrend trend) {
    switch (trend) {
      case SleepTrend.improving: return const Color(0xFF22C55E);
      case SleepTrend.declining: return const Color(0xFFF97316);
      case SleepTrend.stable: return const Color(0xFF8B5CF6);
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
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<SleepBloc>().add(const SleepLoadRequested());
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

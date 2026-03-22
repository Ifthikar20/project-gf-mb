import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/knowledge_bloc.dart';
import '../bloc/knowledge_event.dart';
import '../bloc/knowledge_state.dart';
import '../widgets/tip_of_the_day_card.dart';
import '../widgets/article_card.dart';
import 'article_detail_page.dart';
import '../../../advisor/presentation/widgets/advisor_suggestion_section.dart';

/// Learn tab — knowledge hub with tips, articles, and category filters
class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<KnowledgeBloc>();
    if (bloc.state is KnowledgeInitial) {
      bloc.add(LoadKnowledge());
    }
  }

  static const _categories = [
    {'label': 'All', 'value': null, 'icon': Icons.auto_awesome_rounded},
    {'label': 'Nutrition', 'value': 'nutrition', 'icon': Icons.restaurant_rounded},
    {'label': 'Sleep', 'value': 'sleep', 'icon': Icons.nightlight_rounded},
    {'label': 'Mindfulness', 'value': 'mindfulness', 'icon': Icons.self_improvement_rounded},
    {'label': 'Movement', 'value': 'movement', 'icon': Icons.directions_run_rounded},
    {'label': 'Mental Health', 'value': 'mental-health', 'icon': Icons.psychology_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;

        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final subtleColor = ThemeColors.textSecondary(mode);
        final borderColor = ThemeColors.border(mode);


        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<KnowledgeBloc, KnowledgeState>(
              builder: (context, state) {
                return CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Learn',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Wellness knowledge at your fingertips',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: subtleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // Tip of the day
                    if (state is KnowledgeLoaded)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TipOfTheDayCard(tip: state.tipOfTheDay),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // AI suggestions for Learn tab
                    const SliverToBoxAdapter(
                      child: AdvisorSuggestionSection(tabFilter: 'learn'),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    // Category filters
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final activeFilter = state is KnowledgeLoaded
                                ? state.activeFilter
                                : null;
                            final isSelected = cat['value'] == activeFilter;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  context.read<KnowledgeBloc>().add(
                                      FilterByCategory(
                                          category: cat['value'] as String?));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isLight ? Colors.black : Colors.white.withOpacity(0.12))
                                        : surfaceColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isLight ? Colors.black : Colors.white30)
                                          : borderColor,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        cat['icon'] as IconData,
                                        size: 14,
                                        color: isSelected
                                            ? (isLight ? Colors.white : Colors.white)
                                            : subtleColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat['label'] as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? Colors.white
                                              : subtleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // Section header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Articles',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Article list
                    if (state is KnowledgeLoaded &&
                        state.filteredArticles.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final article = state.filteredArticles[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ArticleCard(
                                  article: article,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ArticleDetailPage(
                                            article: article),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: state.filteredArticles.length,
                          ),
                        ),
                      ),

                    // Loading state
                    if (state is KnowledgeLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: subtleColor,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),

                    // Empty state
                    if (state is KnowledgeLoaded &&
                        state.filteredArticles.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.article_outlined,
                                    size: 40, color: subtleColor),
                                const SizedBox(height: 8),
                                Text(
                                  'No articles in this category yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: subtleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Bottom padding for nav bar
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

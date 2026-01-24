import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/meditation_bloc.dart';
import '../bloc/meditation_event.dart';
import '../bloc/meditation_state.dart';
import '../widgets/meditation_type_card.dart';
import '../widgets/horizontal_section.dart';
import '../../domain/entities/meditation_type.dart';

class MeditationPage extends StatefulWidget {
  const MeditationPage({super.key});

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<MeditationBloc>().state;
    if (state is MeditationInitial) {
      context.read<MeditationBloc>().add(LoadMeditationAudios());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isVintage = themeState.isVintage;
        
        // Dynamic colors
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final primaryColor = ThemeColors.primary(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        
        return Scaffold(
          backgroundColor: bgColor,
          body: BlocBuilder<MeditationBloc, MeditationState>(
            builder: (context, state) {
              if (state is MeditationLoading) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (state is MeditationError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: ThemeColors.error(mode)),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${state.message}',
                        style: TextStyle(color: textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<MeditationBloc>().add(LoadMeditationAudios());
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: Text('Retry', style: TextStyle(color: textColor)),
                      ),
                    ],
                  ),
                );
              }

              if (state is MeditationLoaded) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<MeditationBloc>().add(RefreshMeditationAudios());
                  },
                  color: primaryColor,
                  backgroundColor: surfaceColor,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Meditate',
                                  style: isVintage
                                      ? GoogleFonts.playfairDisplay(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)
                                      : TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _buildChip('All', state.selectedCategory == 'All', () {
                                        context.read<MeditationBloc>().add(const SelectCategory('All'));
                                      }, isVintage, primaryColor, textColor, textSecondary, bgColor),
                                      _buildChip('Calm', state.selectedCategory == 'Calm', () {
                                        context.read<MeditationBloc>().add(const SelectCategory('Calm'));
                                      }, isVintage, primaryColor, textColor, textSecondary, bgColor),
                                      _buildChip('Focus', state.selectedCategory == 'Focus', () {
                                        context.read<MeditationBloc>().add(const SelectCategory('Focus'));
                                      }, isVintage, primaryColor, textColor, textSecondary, bgColor),
                                      _buildChip('Sleep', state.selectedCategory == 'Sleep', () {
                                        context.read<MeditationBloc>().add(const SelectCategory('Sleep'));
                                      }, isVintage, primaryColor, textColor, textSecondary, bgColor),
                                      _buildChip('Breathe', state.selectedCategory == 'Breathe', () {
                                        context.read<MeditationBloc>().add(const SelectCategory('Breathe'));
                                      }, isVintage, primaryColor, textColor, textSecondary, bgColor),
                                      _buildChip('Anxiety', state.selectedCategory == 'Anxiety', () {
                                        context.read<MeditationBloc>().add(const SelectCategory('Anxiety'));
                                      }, isVintage, primaryColor, textColor, textSecondary, bgColor),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Featured Section
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              state.selectedCategory == 'All' 
                                  ? 'Featured Meditations'
                                  : '${state.selectedCategory} Meditations',
                              Icons.spa,
                              isVintage, primaryColor, textColor,
                            ),
                            if (state.filteredAudios.isEmpty)
                              Container(
                                height: 200,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(isVintage ? 12 : 16),
                                  border: isVintage ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off, color: textSecondary.withOpacity(0.5), size: 48),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No ${state.selectedCategory} meditations yet',
                                        style: TextStyle(color: textSecondary.withOpacity(0.7), fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: 240,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: state.filteredAudios.length > 5 ? 5 : state.filteredAudios.length,
                                  itemBuilder: (context, index) {
                                    final audio = state.filteredAudios[index];
                                    return _buildFeaturedCard(
                                      context: context,
                                      title: audio.title,
                                      subtitle: audio.description,
                                      category: audio.category.toUpperCase(),
                                      imageUrl: audio.imageUrl,
                                      onTap: () {
                                        context.push('${AppRouter.audioPlayer}?id=${audio.id}');
                                      },
                                      isVintage: isVintage,
                                      primaryColor: primaryColor,
                                      surfaceColor: surfaceColor,
                                      textColor: textColor,
                                      textSecondary: textSecondary,
                                      bgColor: bgColor,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Horizontal sections
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: HorizontalSection<MeditationType>(
                            title: 'Recommended Stations',
                            items: state.meditationTypes,
                            height: 200,
                            itemBuilder: (type) => MeditationTypeCard(
                              meditationType: type,
                              onTap: () {
                                context.push(
                                  '${AppRouter.meditationCategory}?id=${type.id}&name=${Uri.encodeComponent(type.name)}',
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: HorizontalSection<MeditationType>(
                            title: 'Based on your mood',
                            items: state.moodBasedTypes,
                            height: 200,
                            itemBuilder: (type) => MeditationTypeCard(
                              meditationType: type,
                              onTap: () {
                                context.push(
                                  '${AppRouter.meditationCategory}?id=${type.id}&name=${Uri.encodeComponent(type.name)}',
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                );
              }

              return Center(child: Text('Unknown state', style: TextStyle(color: textSecondary)));
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isVintage, Color primaryColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: isVintage
                ? GoogleFonts.playfairDisplay(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold)
                : TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (isVintage) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor.withOpacity(0.4), Colors.transparent]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, bool isVintage, Color primaryColor, Color textColor, Color textSecondary, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(isVintage ? 6 : 20),
            border: Border.all(
              color: isSelected ? primaryColor : textSecondary.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? (isVintage ? bgColor : Colors.white) : textColor,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String category,
    required String imageUrl,
    required VoidCallback onTap,
    required bool isVintage,
    required Color primaryColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: TextStyle(color: textSecondary.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: isVintage
                  ? GoogleFonts.playfairDisplay(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
                  : TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: textSecondary.withOpacity(0.7), fontSize: 14, fontStyle: isVintage ? FontStyle.italic : FontStyle.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isVintage ? 8 : 12),
                  border: isVintage ? Border.all(color: primaryColor.withOpacity(0.3)) : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isVintage ? 7 : 12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: surfaceColor,
                          child: Icon(Icons.self_improvement, color: textSecondary.withOpacity(0.5), size: 48),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isVintage
                                ? [ThemeColors.vintageBrass.withOpacity(0.1), Colors.transparent, bgColor.withOpacity(0.6)]
                                : [Colors.transparent, bgColor.withOpacity(0.6)],
                            stops: isVintage ? const [0.0, 0.4, 1.0] : const [0.4, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(isVintage ? 4 : 12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.headphones, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text('FEATURED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
                              child: Icon(Icons.play_arrow, color: bgColor, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

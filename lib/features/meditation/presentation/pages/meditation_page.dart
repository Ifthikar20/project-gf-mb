import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/meditation_bloc.dart';
import '../bloc/meditation_event.dart';
import '../bloc/meditation_state.dart';
import '../widgets/meditation_type_card.dart';
import '../widgets/horizontal_section.dart';
import '../../domain/entities/meditation_type.dart';

class MeditationPage extends StatelessWidget {
  const MeditationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: BlocBuilder<MeditationBloc, MeditationState>(
        builder: (context, state) {
          if (state is MeditationLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1DB954),
              ),
            );
          }

          if (state is MeditationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MeditationBloc>().add(LoadMeditationAudios());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                    ),
                    child: const Text('Retry'),
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
              color: const Color(0xFF1DB954),
              backgroundColor: const Color(0xFF282828),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Custom App Bar with filter chips
                  SliverToBoxAdapter(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meditate',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildChip('All', state.selectedCategory == 'All', () {
                                    context.read<MeditationBloc>().add(const SelectCategory('All'));
                                  }),
                                  _buildChip('Calm', state.selectedCategory == 'Calm', () {
                                    context.read<MeditationBloc>().add(const SelectCategory('Calm'));
                                  }),
                                  _buildChip('Focus', state.selectedCategory == 'Focus', () {
                                    context.read<MeditationBloc>().add(const SelectCategory('Focus'));
                                  }),
                                  _buildChip('Sleep', state.selectedCategory == 'Sleep', () {
                                    context.read<MeditationBloc>().add(const SelectCategory('Sleep'));
                                  }),
                                  _buildChip('Breathe', state.selectedCategory == 'Breathe', () {
                                    context.read<MeditationBloc>().add(const SelectCategory('Breathe'));
                                  }),
                                  _buildChip('Anxiety', state.selectedCategory == 'Anxiety', () {
                                    context.read<MeditationBloc>().add(const SelectCategory('Anxiety'));
                                  }),
                                  _buildChip('Work Stress', state.selectedCategory == 'Work Stress', () {
                                    context.read<MeditationBloc>().add(const SelectCategory('Work Stress'));
                                  }),
                                  _buildChip('Morning', state.selectedCategory == 'Morning', () {
                                    context.read<MeditationBloc>().add(const SelectCategory('Morning'));
                                  }),
                                  _buildChip('Relax', state.selectedCategory == 'Relax', () {
                                    context.read<MeditationBloc>().add(const SelectCategory('Relax'));
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Featured Meditations - Large horizontal cards
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Text(
                            state.selectedCategory == 'All' 
                                ? 'Featured Meditations'
                                : '${state.selectedCategory} Meditations',
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),  // Purple
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (state.filteredAudios.isEmpty)
                          Container(
                            height: 200,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off, color: Colors.white38, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No ${state.selectedCategory} meditations yet',
                                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Check back soon!',
                                    style: TextStyle(color: Colors.white38, fontSize: 14),
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
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Recommended Stations section
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

                  // Based on your mood section
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

                  // Popular Artists / Best meditations section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: HorizontalSection<MeditationType>(
                        title: 'Best of artists',
                        items: state.meditationTypes.reversed.toList(),
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

                  // Bottom spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text(
              'Unknown state',
              style: TextStyle(color: Colors.white70),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF7C3AED)  // Purple
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF7C3AED)  // Purple
                  : Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category label
            Text(
              category,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Artist/Subtitle
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Large image card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF282828),
                          child: const Icon(
                            Icons.self_improvement,
                            color: Colors.white24,
                            size: 48,
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                      // Bottom info overlay
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1DB954),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.headphones, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.black,
                                size: 20,
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
          ],
        ),
      ),
    );
  }
}

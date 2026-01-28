import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_event.dart';
import '../../../videos/presentation/bloc/videos_state.dart';
import '../../../meditation/presentation/bloc/meditation_bloc.dart';
import '../../../meditation/presentation/bloc/meditation_event.dart';
import '../../../meditation/presentation/bloc/meditation_state.dart';
import '../widgets/goals_section.dart';
import '../../../../core/presentation/widgets/mood_selector_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedMoodId;

  @override
  void initState() {
    super.initState();
    _loadSavedMood();
    
    // Load videos if not already loaded
    final videosState = context.read<VideosBloc>().state;
    if (videosState is VideosInitial) {
      context.read<VideosBloc>().add(const LoadVideos());
    }
    
    // Load meditations if not already loaded
    final meditationState = context.read<MeditationBloc>().state;
    if (meditationState is MeditationInitial) {
      context.read<MeditationBloc>().add(LoadMeditationAudios());
    }
  }

  Future<void> _loadSavedMood() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMoodId = prefs.getString('current_mood');
    });
  }

  Future<void> _saveMood(MoodOption mood) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_mood', mood.id);
    setState(() {
      _selectedMoodId = mood.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isVintage = themeState.isVintage;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final primaryColor = ThemeColors.primary(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);

        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header with greeting
              SliverToBoxAdapter(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Great Feel',
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
                      ],
                    ),
                  ),
                ),
              ),

              // Mood Selector Widget
              SliverToBoxAdapter(
                child: MoodSelectorWidget(
                  selectedMoodId: _selectedMoodId,
                  onMoodSelected: _saveMood,
                ),
              ),

              // Featured Content Section
              _buildSectionHeader('Featured', Icons.star, textColor, primaryColor, isVintage),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: _buildFeaturedSection(context, isVintage, primaryColor, surfaceColor, textColor, textSecondary, bgColor),
                ),
              ),

              // Continue Watching Section
              _buildSectionHeader('Continue Watching', Icons.play_circle_outline, textColor, primaryColor, isVintage),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: _buildContinueWatchingSection(context, isVintage, primaryColor, surfaceColor, textColor, textSecondary),
                ),
              ),

              // Recommended Meditations
              _buildSectionHeader('Recommended for You', Icons.self_improvement, textColor, primaryColor, isVintage),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: _buildMeditationSection(context, isVintage, primaryColor, surfaceColor, textColor, textSecondary),
                ),
              ),

              // My Goals Section (at bottom)
              const SliverToBoxAdapter(
                child: GoalsSection(),
              ),

              // Bottom spacing for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textColor, Color primaryColor, bool isVintage) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            if (!isVintage) ...[
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: isVintage
                  ? GoogleFonts.playfairDisplay(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )
                  : TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(BuildContext context, bool isVintage, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondary, Color bgColor) {
    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoaded && state.videos.isNotEmpty) {
          final featured = state.videos.take(5).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length,
            itemBuilder: (context, index) {
              final video = featured[index];
              return GestureDetector(
                onTap: () => context.push('${AppRouter.videoPlayer}?id=${video.id}'),
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isVintage ? 8 : 16),
                    border: isVintage ? Border.all(color: primaryColor.withOpacity(0.3)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isVintage ? 7 : 16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: video.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: surfaceColor),
                          errorWidget: (context, url, error) => Container(
                            color: surfaceColor,
                            child: Icon(Icons.play_circle, color: textSecondary, size: 48),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, bgColor.withOpacity(0.8)],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                video.instructor,
                                style: TextStyle(color: textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(isVintage ? 4 : 12),
                            ),
                            child: const Text(
                              'FEATURED',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
        // Loading or empty state
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _buildContinueWatchingSection(BuildContext context, bool isVintage, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondary) {
    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoaded && state.videos.isNotEmpty) {
          final videos = state.videos.skip(2).take(5).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return GestureDetector(
                onTap: () => context.push('${AppRouter.videoPlayer}?id=${video.id}'),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(isVintage ? 6 : 10),
                          border: isVintage ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isVintage ? 5 : 10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: video.thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: surfaceColor),
                                errorWidget: (context, url, error) => Container(color: surfaceColor),
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video.title,
                        style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _buildMeditationSection(BuildContext context, bool isVintage, Color primaryColor, Color surfaceColor, Color textColor, Color textSecondary) {
    return BlocBuilder<MeditationBloc, MeditationState>(
      builder: (context, state) {
        if (state is MeditationLoaded && state.audios.isNotEmpty) {
          final audios = state.audios.take(5).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: audios.length,
            itemBuilder: (context, index) {
              final audio = audios[index];
              return GestureDetector(
                onTap: () => context.push('${AppRouter.audioPlayer}?id=${audio.id}'),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(isVintage ? 6 : 10),
                          border: isVintage ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isVintage ? 5 : 10),
                          child: CachedNetworkImage(
                            imageUrl: audio.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: surfaceColor),
                            errorWidget: (context, url, error) => Container(
                              color: surfaceColor,
                              child: Icon(Icons.self_improvement, color: textSecondary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        audio.title,
                        style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
          ),
        );
      },
    );
  }
}

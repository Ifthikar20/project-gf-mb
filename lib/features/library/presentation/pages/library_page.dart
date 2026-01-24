import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/library_state.dart';
import '../../../videos/presentation/bloc/videos_bloc.dart';
import '../../../videos/presentation/bloc/videos_state.dart';

/// My Library page - shows saved/liked content only
/// (Recently Viewed is now handled by Watch History)
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isVintage = themeState.isVintage;
        final mode = themeState.mode;
        
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final primaryColor = ThemeColors.primary(mode);
        final secondaryColor = ThemeColors.secondary(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final errorColor = ThemeColors.error(mode);
        
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Library',
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
            centerTitle: true,
          ),
          body: BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, libraryState) {
              if (libraryState is LibraryLoaded) {
                final savedIds = libraryState.savedIds;
                
                if (savedIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: textSecondary.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Saved Content',
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
                        const SizedBox(height: 8),
                        Text(
                          'Videos and audio you like will appear here',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(isVintage ? 6 : 24),
                            ),
                            child: Text(
                              'Browse Content',
                              style: TextStyle(
                                color: isVintage ? bgColor : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return BlocBuilder<VideosBloc, VideosState>(
                  builder: (context, videosState) {
                    if (videosState is VideosLoaded) {
                      final savedVideos = videosState.videos
                          .where((v) => savedIds.contains(v.id))
                          .toList();
                      
                      final audioIds = savedIds
                          .where((id) => id.startsWith('audio_'))
                          .toList();
                      
                      if (savedVideos.isEmpty && audioIds.isEmpty) {
                        return Center(
                          child: Text(
                            'No saved content found',
                            style: TextStyle(color: textSecondary),
                          ),
                        );
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Icon(Icons.favorite, color: secondaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${savedVideos.length + audioIds.length} saved items',
                                  style: TextStyle(color: textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: savedVideos.length + audioIds.length,
                              itemBuilder: (context, index) {
                                if (index < savedVideos.length) {
                                  final video = savedVideos[index];
                                  return _buildVideoCard(context, video, isVintage, surfaceColor, textColor, textSecondary, primaryColor, errorColor, bgColor);
                                } else {
                                  final audioId = audioIds[index - savedVideos.length];
                                  return _buildAudioCard(context, audioId, isVintage, surfaceColor, textColor, textSecondary, primaryColor, bgColor);
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  },
                );
              }
              
              return Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVideoCard(BuildContext context, dynamic video, bool isVintage, Color surfaceColor, Color textColor, Color textSecondary, Color primaryColor, Color errorColor, Color bgColor) {
    return GestureDetector(
      onTap: () {
        context.push('${AppRouter.videoPlayer}?id=${video.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(isVintage ? 8 : 16),
          border: isVintage ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isVintage ? 8 : 16),
                bottomLeft: Radius.circular(isVintage ? 8 : 16),
              ),
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                width: 120,
                height: 90,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 120,
                  height: 90,
                  color: surfaceColor,
                  child: Icon(Icons.play_circle, color: textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isVintage ? ThemeColors.dustyRose : ThemeColors.classicBlue,
                        borderRadius: BorderRadius.circular(isVintage ? 3 : 4),
                      ),
                      child: Text(
                        'VIDEO',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.title,
                      style: isVintage
                          ? GoogleFonts.playfairDisplay(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)
                          : TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
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
            ),
            IconButton(
              icon: Icon(Icons.favorite, color: errorColor),
              onPressed: () {
                context.read<LibraryBloc>().add(RemoveFromLibrary(contentId: video.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCard(BuildContext context, String contentId, bool isVintage, Color surfaceColor, Color textColor, Color textSecondary, Color primaryColor, Color bgColor) {
    final audioId = contentId.replaceFirst('audio_', '');
    
    return GestureDetector(
      onTap: () {
        context.push('${AppRouter.audioPlayer}?id=$audioId');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(isVintage ? 8 : 16),
          border: isVintage ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isVintage ? ThemeColors.sageGreen : ThemeColors.classicPrimary).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isVintage ? 8 : 12),
                ),
                child: Icon(
                  Icons.headphones,
                  color: isVintage ? ThemeColors.sageGreen : ThemeColors.classicPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isVintage ? ThemeColors.sageGreen : ThemeColors.classicPrimary,
                        borderRadius: BorderRadius.circular(isVintage ? 3 : 4),
                      ),
                      child: const Text(
                        'AUDIO',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Audio #$audioId',
                      style: isVintage
                          ? GoogleFonts.playfairDisplay(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)
                          : TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Meditation Audio',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.bookmark, color: primaryColor),
                onPressed: () {
                  context.read<LibraryBloc>().add(RemoveFromLibrary(contentId: contentId));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

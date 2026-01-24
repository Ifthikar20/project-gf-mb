import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/recently_viewed_service.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';

/// Watch History page - shows recently viewed content
class WatchHistoryPage extends StatelessWidget {
  const WatchHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isVintage = themeState.isVintage;
        final mode = themeState.mode;
        
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final primaryColor = ThemeColors.primary(mode);
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
              'Watch History',
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
          body: ListenableBuilder(
            listenable: RecentlyViewedService.instance,
            builder: (context, _) {
              final items = RecentlyViewedService.instance.items;
              
              if (items.isEmpty) {
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
                          Icons.history,
                          size: 64,
                          color: textSecondary.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Watch History',
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
                        'Videos and audio you watch will appear here',
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
                            'Start Watching',
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
              
              return Column(
                children: [
                  // Clear all button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history, color: primaryColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${items.length} items',
                              style: TextStyle(color: textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _showClearAllDialog(context, bgColor, textColor, textSecondary, errorColor, isVintage),
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: errorColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildRecentlyViewedCard(context, item, isVintage, surfaceColor, textColor, textSecondary, primaryColor, bgColor);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentlyViewedCard(BuildContext context, RecentlyViewedItem item, bool isVintage, Color surfaceColor, Color textColor, Color textSecondary, Color primaryColor, Color bgColor) {
    return GestureDetector(
      onTap: () {
        if (item.contentType == 'video') {
          context.push('${AppRouter.videoPlayer}?id=${item.contentId}');
        } else {
          context.push('${AppRouter.audioPlayer}?id=${item.contentId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(isVintage ? 8 : 16),
          border: isVintage ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isVintage ? 8 : 16),
                bottomLeft: Radius.circular(isVintage ? 8 : 16),
              ),
              child: item.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.thumbnailUrl!,
                      width: 100,
                      height: 75,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _buildPlaceholder(item.contentType, surfaceColor, textSecondary),
                    )
                  : _buildPlaceholder(item.contentType, surfaceColor, textSecondary),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.contentType == 'video' 
                            ? (isVintage ? ThemeColors.dustyRose : ThemeColors.classicBlue)
                            : (isVintage ? ThemeColors.sageGreen : ThemeColors.classicPrimary),
                        borderRadius: BorderRadius.circular(isVintage ? 3 : 4),
                      ),
                      child: Text(
                        item.contentType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 9, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: isVintage
                          ? GoogleFonts.playfairDisplay(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)
                          : TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(item.viewedAt),
                      style: TextStyle(
                        color: textSecondary.withOpacity(0.6),
                        fontSize: 11,
                        fontStyle: isVintage ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Play icon
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: primaryColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String contentType, Color surfaceColor, Color textSecondary) {
    return Container(
      width: 100,
      height: 75,
      color: surfaceColor,
      child: Icon(
        contentType == 'video' ? Icons.play_circle : Icons.headphones,
        color: textSecondary.withOpacity(0.4),
      ),
    );
  }

  String _formatTime(DateTime viewedAt) {
    final now = DateTime.now();
    final diff = now.difference(viewedAt);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${viewedAt.day}/${viewedAt.month}/${viewedAt.year}';
    }
  }

  void _showClearAllDialog(BuildContext context, Color bgColor, Color textColor, Color textSecondary, Color errorColor, bool isVintage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isVintage ? 8 : 16)),
        title: Text(
          'Clear History?',
          style: isVintage
              ? GoogleFonts.playfairDisplay(color: textColor, fontWeight: FontWeight.bold)
              : TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will remove all your watch history.',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () {
              RecentlyViewedService.instance.clearAll();
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }
}

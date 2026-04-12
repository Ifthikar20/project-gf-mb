import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/recently_viewed_service.dart';
import '../../../../core/navigation/app_router.dart';

/// Shows recently watched videos/audios on the Home page.
/// Only visible when the user has played content — hidden otherwise.
class RecentActivitySection extends StatefulWidget {
  const RecentActivitySection({super.key});

  @override
  State<RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<RecentActivitySection> {
  List<RecentlyViewedItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
    RecentlyViewedService.instance.addListener(_load);
  }

  @override
  void dispose() {
    RecentlyViewedService.instance.removeListener(_load);
    super.dispose();
  }

  void _load() {
    if (mounted) {
      setState(() {
        _items = RecentlyViewedService.instance.items.take(3).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide entirely if no content has been played
    if (_items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : Colors.black;
    final subtle = isDark ? Colors.white38 : Colors.black38;
    final surface = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8EC);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recently Played', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: text)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(AppRouter.watchHistory),
                child: Text('See all', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: subtle)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._items.map((item) => _tile(item, surface, text, subtle, border)),
        ],
      ),
    );
  }

  Widget _tile(RecentlyViewedItem item, Color surface, Color text, Color subtle, Color border) {
    final isVideo = item.contentType == 'video';
    final color = isVideo ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6);
    final icon = isVideo ? Icons.play_circle_filled : Icons.headphones_rounded;
    final timeAgo = _timeAgo(item.viewedAt);

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          context.push('${AppRouter.videoPlayer}?id=${item.contentId}');
        } else {
          context.push('${AppRouter.audioPlayer}?id=${item.contentId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      item.thumbnailUrl!,
                      width: 48, height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconBox(icon, color),
                    )
                  : _iconBox(icon, color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(isVideo ? 'Video' : 'Audio', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                      ),
                      const SizedBox(width: 6),
                      Text(timeAgo, style: GoogleFonts.inter(fontSize: 11, color: subtle)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtle, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}

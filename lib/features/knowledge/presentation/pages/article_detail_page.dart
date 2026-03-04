import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/knowledge_models.dart';

/// Full article detail page with reading progress indicator
class ArticleDetailPage extends StatefulWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final _scrollController = ScrollController();
  double _readProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _readProgress = (_scrollController.offset /
                _scrollController.position.maxScrollExtent)
            .clamp(0.0, 1.0);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App bar with category color
              SliverAppBar(
                backgroundColor: article.categoryColor.withOpacity(0.15),
                expandedHeight: 180,
                floating: false,
                pinned: true,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          article.categoryColor.withOpacity(0.3),
                          article.categoryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        article.categoryIcon,
                        size: 64,
                        color: article.categoryColor.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ),

              // Article content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + read time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: article.categoryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              article.category.toUpperCase().replaceAll('-', ' '),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: article.categoryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.white30),
                          const SizedBox(width: 4),
                          Text(
                            '${article.readTimeMinutes} min read',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white30),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        article.title,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Author
                      Text(
                        'By ${article.author}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Summary
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Text(
                          article.summary,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white54,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Body
                      ...article.body.split('\n\n').map((paragraph) {
                        if (paragraph.startsWith('**') &&
                            paragraph.endsWith('**')) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              paragraph.replaceAll('**', ''),
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            paragraph,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.75),
                              height: 1.7,
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Reading progress bar at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: LinearProgressIndicator(
                value: _readProgress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(article.categoryColor),
                minHeight: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

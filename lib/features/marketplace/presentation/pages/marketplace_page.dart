import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/marketplace_service.dart';
import '../bloc/marketplace_bloc.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MarketplaceBloc>().add(const LoadPrograms());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context
        .read<MarketplaceBloc>()
        .add(LoadPrograms(search: query.isNotEmpty ? query : null));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final primaryColor = ThemeColors.primary(mode);
        final borderColor = ThemeColors.border(mode);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Marketplace',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined,
                    color: textColor, size: 22),
                onPressed: () => context.push(AppRouter.myPurchases),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _onSearch,
                    style: GoogleFonts.inter(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search programs...',
                      hintStyle:
                          GoogleFonts.inter(color: textSecondary, fontSize: 14),
                      prefixIcon:
                          Icon(Icons.search, color: textSecondary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              // Programs list
              Expanded(
                child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
                  builder: (context, state) {
                    if (state is MarketplaceLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                            color: primaryColor, strokeWidth: 2),
                      );
                    }
                    if (state is MarketplaceError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: textSecondary, size: 48),
                            const SizedBox(height: 12),
                            Text(state.message,
                                style: GoogleFonts.inter(
                                    color: textSecondary, fontSize: 14)),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => context
                                  .read<MarketplaceBloc>()
                                  .add(const LoadPrograms()),
                              child: Text('Retry',
                                  style: GoogleFonts.inter(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state is MarketplaceProgramsLoaded) {
                      if (state.programs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storefront_outlined,
                                  color: textSecondary, size: 48),
                              const SizedBox(height: 12),
                              Text('No programs found',
                                  style: GoogleFonts.inter(
                                      color: textSecondary, fontSize: 14)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: state.programs.length,
                        itemBuilder: (context, index) => _buildProgramCard(
                          program: state.programs[index],
                          isLight: isLight,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          borderColor: borderColor,
                          primaryColor: primaryColor,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgramCard({
    required MarketplaceProgram program,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () =>
          context.push('${AppRouter.marketplaceDetail}?id=${program.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isLight ? 0.04 : 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: program.coverImageUrl ?? '',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                memCacheHeight: 320,
                placeholder: (_, __) => Container(
                  height: 160,
                  color: isLight
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFF2A2A2A),
                  child: Icon(Icons.image_outlined,
                      color: textSecondary, size: 40),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: isLight
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFF2A2A2A),
                  child: Icon(Icons.image_outlined,
                      color: textSecondary, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  if (program.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        program.category!.name,
                        style: GoogleFonts.inter(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // Title
                  Text(
                    program.title,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Creator
                  Text(
                    'By ${program.creator.displayName}',
                    style: GoogleFonts.inter(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bottom row: price, lessons, students
                  Row(
                    children: [
                      Text(
                        '\$${program.price}',
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.play_lesson_outlined,
                          color: textSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${program.contentCount} lessons',
                        style: GoogleFonts.inter(
                            color: textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people_outline,
                          color: textSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${program.purchaseCount}',
                        style: GoogleFonts.inter(
                            color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  if (program.isPurchased) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF22C55E), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Purchased',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF22C55E),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/marketplace_service.dart';
import '../bloc/marketplace_bloc.dart';

class ProgramDetailPage extends StatefulWidget {
  final String programId;
  const ProgramDetailPage({super.key, required this.programId});

  @override
  State<ProgramDetailPage> createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<MarketplaceBloc>()
        .add(LoadProgramDetail(programId: widget.programId));
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
          body: BlocConsumer<MarketplaceBloc, MarketplaceState>(
            listener: (context, state) {
              if (state is MarketplacePurchaseReady) {
                // In a real app, this would use flutter_stripe to present payment sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Payment sheet would open here (Stripe integration)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                // Refresh program detail after payment
                context
                    .read<MarketplaceBloc>()
                    .add(LoadProgramDetail(programId: widget.programId));
              }
              if (state is MarketplaceError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is MarketplaceLoading) {
                return Center(
                  child: CircularProgressIndicator(
                      color: primaryColor, strokeWidth: 2),
                );
              }
              if (state is MarketplaceProgramDetailLoaded) {
                final program = state.program;
                final content = state.content;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Cover image with back button
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: program.coverImageUrl ?? '',
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 240,
                              color: surfaceColor,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 240,
                              color: surfaceColor,
                              child: Icon(Icons.image_outlined,
                                  color: textSecondary, size: 48),
                            ),
                          ),
                          Container(
                            height: 240,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                  bgColor,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            left: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_back_ios_new,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Program info
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Text(
                              program.title,
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: primaryColor.withOpacity(0.2),
                                  backgroundImage:
                                      program.creator.avatarUrl != null
                                          ? CachedNetworkImageProvider(
                                              program.creator.avatarUrl!)
                                          : null,
                                  child: program.creator.avatarUrl == null
                                      ? Text(
                                          program.creator.displayName[0],
                                          style: GoogleFonts.inter(
                                            color: primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  program.creator.displayName,
                                  style: GoogleFonts.inter(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Stats row
                            Row(
                              children: [
                                _buildStat(
                                  Icons.play_lesson_outlined,
                                  '${program.contentCount} lessons',
                                  textSecondary,
                                ),
                                const SizedBox(width: 20),
                                _buildStat(
                                  Icons.people_outline,
                                  '${program.purchaseCount} students',
                                  textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              program.description,
                              style: GoogleFonts.inter(
                                color: textColor.withOpacity(0.8),
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Content list (if purchased)
                    if (program.isPurchased && content.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Text(
                            'Content',
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = content[index];
                            return Container(
                              margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      item.contentType == 'video'
                                          ? Icons.play_circle_outline
                                          : Icons.article_outlined,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: GoogleFonts.inter(
                                            color: textColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (item.formattedDuration.isNotEmpty)
                                          Text(
                                            item.formattedDuration,
                                            style: GoogleFonts.inter(
                                              color: textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right,
                                      color: textSecondary, size: 20),
                                ],
                              ),
                            );
                          },
                          childCount: content.length,
                        ),
                      ),
                    ],

                    // Bottom spacing
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Bottom purchase bar
          bottomNavigationBar: BlocBuilder<MarketplaceBloc, MarketplaceState>(
            builder: (context, state) {
              if (state is MarketplaceProgramDetailLoaded) {
                final program = state.program;
                return Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      top: BorderSide(color: borderColor, width: 0.5),
                    ),
                  ),
                  child: program.isPurchased
                      ? GestureDetector(
                          onTap: () => context.read<MarketplaceBloc>().add(
                              LoadProgramContent(
                                  programId: widget.programId)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'View Content',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price',
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '\$${program.price}',
                                  style: GoogleFonts.inter(
                                    color: textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context
                                    .read<MarketplaceBloc>()
                                    .add(PurchaseProgram(
                                        programId: widget.programId)),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Buy Now',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(color: color, fontSize: 13),
        ),
      ],
    );
  }
}

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

class MyPurchasesPage extends StatefulWidget {
  const MyPurchasesPage({super.key});

  @override
  State<MyPurchasesPage> createState() => _MyPurchasesPageState();
}

class _MyPurchasesPageState extends State<MyPurchasesPage> {
  @override
  void initState() {
    super.initState();
    context.read<MarketplaceBloc>().add(LoadMyPurchases());
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
              'My Purchases',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: BlocBuilder<MarketplaceBloc, MarketplaceState>(
            builder: (context, state) {
              if (state is MarketplaceLoading) {
                return Center(
                  child: CircularProgressIndicator(
                      color: primaryColor, strokeWidth: 2),
                );
              }
              if (state is MarketplacePurchasesLoaded) {
                if (state.purchases.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            color: textSecondary, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No purchases yet',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Browse the marketplace to find programs',
                          style: GoogleFonts.inter(
                              color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: state.purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = state.purchases[index];
                    return GestureDetector(
                      onTap: () {
                        if (purchase.program != null) {
                          context.push(
                              '${AppRouter.marketplaceDetail}?id=${purchase.program!.id}');
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl:
                                    purchase.program?.coverImageUrl ?? '',
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 64,
                                  height: 64,
                                  color: isLight
                                      ? const Color(0xFFF3F4F6)
                                      : const Color(0xFF2A2A2A),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 64,
                                  height: 64,
                                  color: isLight
                                      ? const Color(0xFFF3F4F6)
                                      : const Color(0xFF2A2A2A),
                                  child: Icon(Icons.image_outlined,
                                      color: textSecondary, size: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    purchase.program?.title ?? 'Program',
                                    style: GoogleFonts.inter(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${purchase.amount}',
                                    style: GoogleFonts.inter(
                                      color: textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: textSecondary, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              if (state is MarketplaceError) {
                return Center(
                  child: Text(state.message,
                      style:
                          GoogleFonts.inter(color: textSecondary, fontSize: 14)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/coaching_service.dart';
import '../bloc/coaching_bloc.dart';

class CoachesPage extends StatefulWidget {
  const CoachesPage({super.key});

  @override
  State<CoachesPage> createState() => _CoachesPageState();
}

class _CoachesPageState extends State<CoachesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const _categories = [
    'All',
    'Strength',
    'Cardio',
    'Yoga',
    'HIIT',
    'CrossFit',
    'Nutrition',
    'Weight Loss',
    'Wellness',
  ];

  @override
  void initState() {
    super.initState();
    context.read<CoachingBloc>().add(const LoadCoaches());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Coach> _filterCoaches(List<Coach> coaches) {
    var filtered = coaches;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.expert.name.toLowerCase().contains(q) ||
            c.bio.toLowerCase().contains(q) ||
            c.specialties.any((s) => s.toLowerCase().contains(q));
      }).toList();
    }

    // Category filter
    if (_selectedCategory != 'All') {
      final cat = _selectedCategory.toLowerCase();
      filtered = filtered.where((c) {
        return c.specialties.any((s) => s.toLowerCase().contains(cat)) ||
            c.bio.toLowerCase().contains(cat);
      }).toList();
    }

    return filtered;
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
              'Find a Coach',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search by name or specialty...',
                      hintStyle: GoogleFonts.inter(
                        color: textSecondary.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: textSecondary.withOpacity(0.4),
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: textSecondary,
                                size: 18,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              // Category filter chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isLight ? Colors.black : Colors.white)
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected ? Colors.transparent : borderColor,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? (isLight ? Colors.white : Colors.black)
                                : textSecondary,
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Coach list
              Expanded(
                child: BlocBuilder<CoachingBloc, CoachingState>(
                  builder: (context, state) {
                    if (state is CoachingLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                            color: primaryColor, strokeWidth: 2),
                      );
                    }
                    if (state is CoachingError) {
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
                                  .read<CoachingBloc>()
                                  .add(const LoadCoaches()),
                              child: Text('Retry',
                                  style: GoogleFonts.inter(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state is CoachesLoaded) {
                      final filtered = _filterCoaches(state.coaches);
                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_search_outlined,
                                  color: textSecondary, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty ||
                                        _selectedCategory != 'All'
                                    ? 'No coaches match your search'
                                    : 'No coaches available yet',
                                style: GoogleFonts.inter(
                                    color: textSecondary, fontSize: 14),
                              ),
                              if (_searchQuery.isNotEmpty ||
                                  _selectedCategory != 'All') ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _selectedCategory = 'All';
                                  }),
                                  child: Text(
                                    'Clear filters',
                                    style: GoogleFonts.inter(
                                      color: primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildCoachCard(
                          coach: filtered[index],
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

  Widget _buildCoachCard({
    required Coach coach,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () =>
          context.push('${AppRouter.coachDetail}?id=${coach.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: primaryColor.withOpacity(0.15),
              backgroundImage: coach.expert.avatarUrl != null
                  ? CachedNetworkImageProvider(coach.expert.avatarUrl!)
                  : null,
              child: coach.expert.avatarUrl == null
                  ? Text(
                      coach.expert.name[0],
                      style: GoogleFonts.inter(
                        color: primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.expert.name,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (coach.expert.title != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      coach.expert.title!,
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Specialties
                  if (coach.specialties.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: coach.specialties
                          .take(3)
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s,
                                style: GoogleFonts.inter(
                                  color: primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 10),
                  // Price + view profile
                  Row(
                    children: [
                      Text(
                        '\$${coach.hourlyRate}/hr',
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'View Profile',
                          style: GoogleFonts.inter(
                            color: isLight ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

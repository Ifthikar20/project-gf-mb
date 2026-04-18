import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../data/models/coach_program_models.dart';
import '../bloc/coach_program_bloc.dart';

/// Browse all coach-created training programs.
/// Users can filter by duration and category, then tap to view details.
class CoachProgramsPage extends StatefulWidget {
  const CoachProgramsPage({super.key});

  @override
  State<CoachProgramsPage> createState() => _CoachProgramsPageState();
}

class _CoachProgramsPageState extends State<CoachProgramsPage> {
  String _selectedDuration = 'All';
  String _selectedCategory = 'All';

  final _durationFilters = ['All', '2 Weeks', '4 Weeks', '8 Weeks', '12 Weeks'];
  final _categoryFilters = [
    'All', 'Yoga', 'HIIT', 'Strength', 'Mindfulness',
    'Pilates', 'Running', 'Nutrition',
  ];

  @override
  void initState() {
    super.initState();
    context.read<CoachProgramBloc>().add(const LoadCoachPrograms());
  }

  int? _parseDurationWeeks(String label) {
    switch (label) {
      case '2 Weeks': return 2;
      case '4 Weeks': return 4;
      case '8 Weeks': return 8;
      case '12 Weeks': return 12;
      default: return null;
    }
  }

  void _applyFilters() {
    context.read<CoachProgramBloc>().add(LoadCoachPrograms(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      durationWeeks: _parseDurationWeeks(_selectedDuration),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final isLight = themeState.isLight;
        final bgColor = ThemeColors.background(mode);
        final surfaceColor = ThemeColors.surface(mode);
        final primaryColor = ThemeColors.primary(mode);
        final textColor = ThemeColors.textPrimary(mode);
        final textSecondary = ThemeColors.textSecondary(mode);
        final borderColor = ThemeColors.border(mode);

        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor),
                                ),
                                child: Icon(Icons.arrow_back_ios_new_rounded,
                                    color: textColor, size: 18),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  context.push(AppRouter.myPrograms),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.school_outlined,
                                        color: primaryColor, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'My Programs',
                                      style: GoogleFonts.inter(
                                        color: primaryColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Hero Title ──
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.6),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Train With\nThe Best',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Structured programs designed by expert coaches.\nEnroll and follow their recommended training calendar.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Duration Filter ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    children: _durationFilters.map((dur) {
                      final isActive = _selectedDuration == dur;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedDuration = dur);
                            _applyFilters();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? (isLight ? Colors.black : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? Colors.transparent
                                    : borderColor,
                              ),
                            ),
                            child: Text(
                              dur,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isActive
                                    ? (isLight ? Colors.white : Colors.black)
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── Category Filter ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    children: _categoryFilters.map((cat) {
                      final isActive = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            _applyFilters();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? primaryColor.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? primaryColor.withOpacity(0.3)
                                    : borderColor,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isActive
                                    ? primaryColor
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Programs List ──
              BlocBuilder<CoachProgramBloc, CoachProgramState>(
                builder: (context, state) {
                  if (state is CoachProgramLoading) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(60),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: primaryColor, strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  if (state is CoachProgramError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
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
                                    .read<CoachProgramBloc>()
                                    .add(const LoadCoachPrograms()),
                                child: Text('Retry',
                                    style: GoogleFonts.inter(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  if (state is CoachProgramsLoaded) {
                    if (state.programs.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(60),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.fitness_center_rounded,
                                    color: textSecondary, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'No programs available yet',
                                  style: GoogleFonts.inter(
                                      color: textSecondary, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Check back soon for new coach programs',
                                  style: GoogleFonts.inter(
                                      color: textSecondary.withOpacity(0.6),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProgramCard(
                            program: state.programs[index],
                            isLight: isLight,
                            surfaceColor: surfaceColor,
                            textColor: textColor,
                            textSecondary: textSecondary,
                            borderColor: borderColor,
                            primaryColor: primaryColor,
                          ),
                          childCount: state.programs.length,
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────
  // Program Card
  // ─────────────────────────────
  Widget _buildProgramCard({
    required CoachProgram program,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
    required Color primaryColor,
  }) {
    final rng = Random(program.id.hashCode);
    final enrolledCount = program.enrolledCount > 0
        ? program.enrolledCount
        : (rng.nextInt(200) + 50);

    return GestureDetector(
      onTap: () => context.push(
          '${AppRouter.coachProgramDetail}?id=${program.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isLight ? 0.05 : 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail with overlays ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: program.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: program.coverImageUrl!,
                            fit: BoxFit.cover,
                            memCacheHeight: 400,
                            memCacheWidth: 700,
                            placeholder: (_, __) =>
                                Container(color: surfaceColor),
                            errorWidget: (_, __, ___) =>
                                _placeholderThumbnail(
                                    surfaceColor, textSecondary),
                          )
                        : _placeholderThumbnail(
                            surfaceColor, textSecondary),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.65),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Duration badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        program.durationLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Level badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart_rounded,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            program.level,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Coach avatar + name at bottom
                  Positioned(
                    left: 14,
                    bottom: 14,
                    right: 14,
                    child: Row(
                      children: [
                        // Coach avatar
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.3),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5),
                          ),
                          child: program.coach.avatarUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: program.coach.avatarUrl!,
                                    fit: BoxFit.cover,
                                    width: 32,
                                    height: 32,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    program.coach.name.isNotEmpty
                                        ? program.coach.name[0]
                                        : '?',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'With ${program.coach.name}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Info section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    program.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Category + Content count
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          program.category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.play_lesson_rounded,
                          size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${program.contentCount} sessions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      const Spacer(),
                      // Enrolled stack
                      SizedBox(
                        width: 44,
                        height: 22,
                        child: Stack(
                          children: List.generate(3, (i) {
                            final colors = [
                              const Color(0xFF3B82F6),
                              const Color(0xFF8B5CF6),
                              const Color(0xFFF59E0B),
                            ];
                            return Positioned(
                              left: i * 12.0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: colors[i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isLight
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(Icons.person,
                                      size: 10,
                                      color:
                                          Colors.white.withOpacity(0.9)),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$enrolledCount',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description preview
                  if (program.description.isNotEmpty)
                    Text(
                      program.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 14),
                  // Enroll CTA
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: program.isEnrolled
                          ? const Color(0xFF22C55E)
                          : (isLight ? Colors.black : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        program.isEnrolled
                            ? '✓  Enrolled'
                            : program.isFree
                                ? 'Enroll Free'
                                : 'Enroll  •  \$${program.price}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: program.isEnrolled
                              ? Colors.white
                              : isLight
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderThumbnail(Color surfaceColor, Color textSecondary) {
    return Container(
      color: surfaceColor,
      child: Center(
        child: Icon(Icons.fitness_center_rounded,
            color: textSecondary, size: 48),
      ),
    );
  }
}

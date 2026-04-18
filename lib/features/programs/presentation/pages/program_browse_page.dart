import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/navigation/app_router.dart';
import '../bloc/program_bloc.dart';
import '../widgets/program_card.dart';

class ProgramBrowsePage extends StatefulWidget {
  const ProgramBrowsePage({super.key});

  @override
  State<ProgramBrowsePage> createState() => _ProgramBrowsePageState();
}

class _ProgramBrowsePageState extends State<ProgramBrowsePage> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedDifficulty;
  int? _selectedDuration;

  static const _difficulties = ['beginner', 'intermediate', 'advanced'];
  static const _durations = [1, 2, 4, 8, 12];
  static const _categories = [
    'All',
    'Yoga',
    'HIIT',
    'Strength',
    'Meditation',
    'Pilates',
    'Cardio',
    'Flexibility',
  ];

  @override
  void initState() {
    super.initState();
    context.read<ProgramBloc>().add(const LoadPrograms());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    context.read<ProgramBloc>().add(LoadPrograms(
          search: _searchController.text.isEmpty
              ? null
              : _searchController.text,
          difficulty: _selectedDifficulty,
          durationWeeks: _selectedDuration,
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
              // App bar
              SliverAppBar(
                backgroundColor: bgColor,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                floating: true,
                snap: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  'Programs',
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.folder_outlined,
                        color: primaryColor, size: 22),
                    onPressed: () =>
                        context.push(AppRouter.myPrograms),
                    tooltip: 'My Programs',
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(color: borderColor, height: 1),
                ),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _search(),
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search programs...',
                        hintStyle: TextStyle(
                            color: textSecondary.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search,
                            color: textSecondary.withOpacity(0.5)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: textSecondary, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _search();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // Category chips
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected =
                          (_selectedCategory == null && cat == 'All') ||
                              _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory =
                                  cat == 'All' ? null : cat;
                            });
                            _search();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : borderColor,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.inter(
                                color: isSelected
                                    ? Colors.white
                                    : textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Filter row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      // Difficulty filter
                      _buildFilterDropdown(
                        label: 'Difficulty',
                        value: _selectedDifficulty,
                        items: _difficulties,
                        displayName: (d) =>
                            d[0].toUpperCase() + d.substring(1),
                        onChanged: (val) {
                          setState(() => _selectedDifficulty = val);
                          _search();
                        },
                        isLight: isLight,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                      ),
                      const SizedBox(width: 10),
                      // Duration filter
                      _buildFilterDropdown(
                        label: 'Duration',
                        value: _selectedDuration?.toString(),
                        items:
                            _durations.map((d) => d.toString()).toList(),
                        displayName: (d) {
                          final weeks = int.parse(d);
                          return weeks == 1
                              ? '1 Week'
                              : '$weeks Weeks';
                        },
                        onChanged: (val) {
                          setState(() => _selectedDuration =
                              val != null ? int.parse(val) : null);
                          _search();
                        },
                        isLight: isLight,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        textSecondary: textSecondary,
                        borderColor: borderColor,
                      ),
                      const Spacer(),
                      // Clear filters
                      if (_selectedDifficulty != null ||
                          _selectedDuration != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDifficulty = null;
                              _selectedDuration = null;
                            });
                            _search();
                          },
                          child: Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Programs grid
              BlocBuilder<ProgramBloc, ProgramState>(
                builder: (context, state) {
                  if (state is ProgramLoading) {
                    return SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: primaryColor, strokeWidth: 2),
                      ),
                    );
                  }

                  if (state is ProgramError) {
                    return SliverFillRemaining(
                      child: Center(
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
                              onTap: _search,
                              child: Text('Retry',
                                  style: GoogleFonts.inter(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ProgramsLoaded) {
                    if (state.programs.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.explore_outlined,
                                  color: textSecondary.withOpacity(0.4),
                                  size: 56),
                              const SizedBox(height: 12),
                              Text(
                                'No programs found',
                                style: GoogleFonts.inter(
                                    color: textSecondary, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try adjusting your filters',
                                style: TextStyle(
                                    color:
                                        textSecondary.withOpacity(0.5),
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.6,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final program = state.programs[index];
                            return ProgramCard(
                              program: program,
                              onTap: () => context.push(
                                '${AppRouter.programDetail}?id=${program.id}',
                              ),
                              isLight: isLight,
                              surfaceColor: surfaceColor,
                              textColor: textColor,
                              textSecondary: textSecondary,
                              primaryColor: primaryColor,
                              borderColor: borderColor,
                            );
                          },
                          childCount: state.programs.length,
                        ),
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String) displayName,
    required ValueChanged<String?> onChanged,
    required bool isLight,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            label,
            style: TextStyle(
                color: textSecondary.withOpacity(0.6), fontSize: 12),
          ),
          icon: Icon(Icons.expand_more,
              color: textSecondary.withOpacity(0.5), size: 16),
          isDense: true,
          dropdownColor: surfaceColor,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('All',
                  style: TextStyle(color: textColor, fontSize: 12)),
            ),
            ...items.map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(displayName(item),
                      style: TextStyle(color: textColor, fontSize: 12)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

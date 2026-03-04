import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/models/wellness_suggestion_model.dart';
import '../bloc/advisor_bloc.dart';
import '../bloc/advisor_event.dart';
import '../bloc/advisor_state.dart';
import 'wellness_suggestion_card.dart';

/// Horizontal scrollable section of AI-driven suggestion cards.
/// Drop this widget into any page's sliver list.
class AdvisorSuggestionSection extends StatelessWidget {
  /// Optional tab filter: 'home', 'nourish', 'meditate', 'learn'
  final String? tabFilter;

  const AdvisorSuggestionSection({super.key, this.tabFilter});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdvisorBloc, AdvisorState>(
      builder: (context, state) {
        if (state is! AdvisorLoaded) return const SizedBox.shrink();

        var suggestions = state.visibleSuggestions;

        // Apply tab filter if specified
        if (tabFilter != null) {
          suggestions = _filterForTab(suggestions, tabFilter!);
        }

        if (suggestions.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFFF59E0B), size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'For You',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      context.read<AdvisorBloc>().add(RefreshSuggestions());
                    },
                    child: Icon(Icons.refresh_rounded,
                        color: Colors.white24, size: 18),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: WellnessSuggestionCard(
                      suggestion: suggestion,
                      onDismiss: () {
                        context.read<AdvisorBloc>().add(
                            DismissSuggestion(
                                suggestionId: suggestion.id));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<WellnessSuggestion> _filterForTab(List<WellnessSuggestion> suggestions, String tab) {
    switch (tab) {
      case 'nourish':
        return suggestions
            .where((s) =>
                s.category == 'nutrition' || s.category == 'hydration')
            .toList();
      case 'meditate':
        return suggestions
            .where((s) =>
                s.category == 'breathing' ||
                s.category == 'mental' ||
                s.category == 'sleep')
            .toList();
      case 'learn':
        return suggestions
            .where((s) =>
                s.category == 'recovery' ||
                s.category == 'activity' ||
                s.category == 'celebration')
            .toList();
      default:
        return suggestions;
    }
  }
}

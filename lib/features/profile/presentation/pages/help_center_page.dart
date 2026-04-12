import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static const _faqs = [
    _FAQ('How do I scan food?', 'Go to the Calories tab and tap the camera icon. Take a photo of your food and our AI will estimate the calories and nutrients.'),
    _FAQ('How are calories burned calculated?', 'We use your logged workouts and step count from Apple Health. Each workout type has a MET value that determines calorie burn based on your weight and duration.'),
    _FAQ('Is my health data private?', 'Yes. All health data (steps, heart rate, sleep) stays on your device. It is never uploaded to our servers. Only food scan images are sent for AI analysis.'),
    _FAQ('How do I connect Apple Health?', 'On the Home page, tap Connect on the activity card. Enable all categories in the iOS permission screen. If you missed it, go to Settings > Health > Data Access > Great Feel.'),
    _FAQ('How do I set a calorie goal?', 'On the Calories page, tap the calorie goal bar at the top. You can choose a preset or enter a custom daily goal.'),
    _FAQ('How do I log a workout?', 'Go to Activity (tap the card on Home) > scroll to Recent Workouts > tap Log. Select a workout type, set duration, and complete.'),
    _FAQ('What is the Burn It Off feature?', 'After scanning food, you\'ll see workout suggestions that would burn off the calories. Tap Add to set it as a weekly goal.'),
    _FAQ('How do I change my password?', 'Go to Profile > Account > Password & Security.'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final mode = themeState.mode;
        final bg = ThemeColors.background(mode);
        final text = ThemeColors.textPrimary(mode);
        final subtle = ThemeColors.textSecondary(mode);
        final surface = ThemeColors.surface(mode);
        final border = themeState.isLight ? const Color(0xFFE8E8EC) : const Color(0xFF2A2A2A);

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: text, size: 20), onPressed: () => Navigator.pop(context)),
            title: Text('Help Center', style: GoogleFonts.inter(color: text, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _faqs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _FAQCard(faq: _faqs[i], surface: surface, text: text, subtle: subtle, border: border),
          ),
        );
      },
    );
  }
}

class _FAQ {
  final String question;
  final String answer;
  const _FAQ(this.question, this.answer);
}

class _FAQCard extends StatefulWidget {
  final _FAQ faq;
  final Color surface, text, subtle, border;
  const _FAQCard({required this.faq, required this.surface, required this.text, required this.subtle, required this.border});

  @override
  State<_FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<_FAQCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.faq.question, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: widget.text))),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: widget.subtle, size: 20),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(widget.faq.answer, style: GoogleFonts.inter(fontSize: 13, color: widget.subtle, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}

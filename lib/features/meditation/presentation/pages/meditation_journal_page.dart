import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/journal_models.dart';

/// Post-session journal page for reflecting after meditation/breathing
class MeditationJournalPage extends StatefulWidget {
  final String sessionType; // 'breathing', 'meditation', 'mindfulness'
  final int? durationSeconds;

  const MeditationJournalPage({
    super.key,
    required this.sessionType,
    this.durationSeconds,
  });

  @override
  State<MeditationJournalPage> createState() => _MeditationJournalPageState();
}

class _MeditationJournalPageState extends State<MeditationJournalPage> {
  int _moodAfter = 3;
  final _gratitudeController = TextEditingController();
  final _noteController = TextEditingController();

  static const _sheetBg = Color(0xFF0F0F0F);

  @override
  void dispose() {
    _gratitudeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final entry = MeditationJournalEntry(
      date: DateTime.now(),
      moodAfter: _moodAfter,
      gratitude: _gratitudeController.text.trim().isEmpty
          ? null
          : _gratitudeController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      sessionType: widget.sessionType,
      durationSeconds: widget.durationSeconds,
    );

    try {
      final box =
          await Hive.openBox<MeditationJournalEntry>('meditation_journal');
      await box.add(entry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry saved ✨'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final durationStr = widget.durationSeconds != null
        ? '${widget.durationSeconds! ~/ 60}:${(widget.durationSeconds! % 60).toString().padLeft(2, '0')}'
        : null;

    return Scaffold(
      backgroundColor: _sheetBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Session Reflection',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Skip',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session summary
            if (durationStr != null)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.sessionType} · $durationStr',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8B5CF6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Mood after
            Text(
              'How do you feel now?',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final mood = i + 1;
                final entry = MeditationJournalEntry(
                  date: DateTime.now(),
                  moodAfter: mood,
                  sessionType: 'preview',
                );
                final isSelected = mood == _moodAfter;
                return GestureDetector(
                  onTap: () => setState(() => _moodAfter = mood),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B5CF6).withOpacity(0.2)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(entry.moodEmoji,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          entry.moodLabel,
                          style: GoogleFonts.inter(
                            color:
                                isSelected ? Colors.white : Colors.white38,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Gratitude
            Text(
              'What are you grateful for?',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              _gratitudeController,
              'I\'m grateful for...',
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Notes
            Text(
              'Any thoughts or reflections?',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              _noteController,
              'Write freely...',
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Reflection',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

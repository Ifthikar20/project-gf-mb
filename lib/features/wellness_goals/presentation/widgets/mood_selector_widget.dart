import 'package:flutter/material.dart';

/// Mood data model
class MoodOption {
  final String id;
  final String label;
  final Color color;
  final IconData icon;
  
  const MoodOption({
    required this.id,
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Available moods with colors matching capsule design
class Moods {
  static const List<MoodOption> all = [
    MoodOption(id: 'anxious', label: 'Anxious', color: Color(0xFFE57373), icon: Icons.psychology_outlined),
    MoodOption(id: 'sad', label: 'Sad', color: Color(0xFF64B5F6), icon: Icons.sentiment_dissatisfied),
    MoodOption(id: 'tired', label: 'Tired', color: Color(0xFFBA68C8), icon: Icons.bedtime_outlined),
    MoodOption(id: 'stressed', label: 'Stressed', color: Color(0xFFFFB74D), icon: Icons.flash_on),
    MoodOption(id: 'calm', label: 'Calm', color: Color(0xFF81C784), icon: Icons.spa_outlined),
    MoodOption(id: 'happy', label: 'Happy', color: Color(0xFFFFD54F), icon: Icons.sentiment_very_satisfied),
    MoodOption(id: 'focused', label: 'Focused', color: Color(0xFF4FC3F7), icon: Icons.center_focus_strong),
    MoodOption(id: 'energetic', label: 'Energetic', color: Color(0xFFFF8A65), icon: Icons.bolt),
  ];
  
  static MoodOption? getById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Animated mood check button with popup selector
class MoodSelectorWidget extends StatefulWidget {
  final String? selectedMoodId;
  final ValueChanged<MoodOption> onMoodSelected;
  
  const MoodSelectorWidget({
    super.key,
    this.selectedMoodId,
    required this.onMoodSelected,
  });

  @override
  State<MoodSelectorWidget> createState() => _MoodSelectorWidgetState();
}

class _MoodSelectorWidgetState extends State<MoodSelectorWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showMoodPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MoodPopup(
        selectedMoodId: widget.selectedMoodId,
        onMoodSelected: (mood) {
          Navigator.pop(context);
          widget.onMoodSelected(mood);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMood = widget.selectedMoodId != null 
        ? Moods.getById(widget.selectedMoodId!) 
        : null;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selectedMood != null
              ? [selectedMood.color.withOpacity(0.2), selectedMood.color.withOpacity(0.1)]
              : [const Color(0xFF1A1A1A), const Color(0xFF151515)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selectedMood?.color.withOpacity(0.3) ?? Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Left side - question
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How are you feeling?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedMood != null 
                      ? "You're feeling ${selectedMood.label.toLowerCase()}"
                      : 'Tap to check in with yourself',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Animated button
          GestureDetector(
            onTap: _showMoodPopup,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: selectedMood == null ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: selectedMood != null
                            ? [selectedMood.color, selectedMood.color.withOpacity(0.7)]
                            : [const Color(0xFF1DB954), const Color(0xFF1ED760)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (selectedMood?.color ?? const Color(0xFF1DB954)).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      selectedMood?.icon ?? Icons.add_reaction_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Mood selection popup with capsule-shaped options
class _MoodPopup extends StatelessWidget {
  final String? selectedMoodId;
  final ValueChanged<MoodOption> onMoodSelected;
  
  const _MoodPopup({
    this.selectedMoodId,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select your current mood and we'll personalize your content",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Mood capsules grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: Moods.all.map((mood) {
              final isSelected = selectedMoodId == mood.id;
              return GestureDetector(
                onTap: () => onMoodSelected(mood),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? mood.color : mood.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: mood.color,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: mood.color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mood.icon,
                        color: isSelected ? Colors.white : mood.color,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        mood.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : mood.color,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

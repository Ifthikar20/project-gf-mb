/// Journal entry entity — maps to the backend JournalEntry model.
///
/// Each entry represents one day's mood check-in + optional reflection,
/// with Gemini-generated AI insights.
class JournalEntry {
  final String id;
  final String mood;
  final String moodLabel;
  final int moodIntensity;
  final String reflectionText;
  final String aiInsight;
  final String gratitudePrompt;
  final String suggestedAction;
  final String suggestedActionLabel;
  final List<String> tags;
  final String entryDate;
  final String? createdAt;
  final String? updatedAt;

  const JournalEntry({
    required this.id,
    required this.mood,
    required this.moodLabel,
    required this.moodIntensity,
    this.reflectionText = '',
    this.aiInsight = '',
    this.gratitudePrompt = '',
    this.suggestedAction = '',
    this.suggestedActionLabel = '',
    this.tags = const [],
    required this.entryDate,
    this.createdAt,
    this.updatedAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      moodLabel: json['mood_label'] as String? ?? '',
      moodIntensity: json['mood_intensity'] as int? ?? 3,
      reflectionText: json['reflection_text'] as String? ?? '',
      aiInsight: json['ai_insight'] as String? ?? '',
      gratitudePrompt: json['gratitude_prompt'] as String? ?? '',
      suggestedAction: json['suggested_action'] as String? ?? '',
      suggestedActionLabel: json['suggested_action_label'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      entryDate: json['entry_date'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'mood': mood,
        'mood_intensity': moodIntensity,
        'reflection_text': reflectionText,
      };

  /// Check if this entry has an AI insight loaded
  bool get hasInsight => aiInsight.isNotEmpty;

  /// Check if this entry has a reflection
  bool get hasReflection => reflectionText.isNotEmpty;
}

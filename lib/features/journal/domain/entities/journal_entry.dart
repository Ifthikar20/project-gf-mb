/// Journal entry data model.
///
/// Maps to the backend JournalEntry model. Includes mood, reflection,
/// AI-generated insight, gratitude prompt, and suggested action.
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
    required this.reflectionText,
    required this.aiInsight,
    required this.gratitudePrompt,
    required this.suggestedAction,
    required this.suggestedActionLabel,
    required this.tags,
    required this.entryDate,
    this.createdAt,
    this.updatedAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] ?? '',
      mood: json['mood'] ?? '',
      moodLabel: json['mood_label'] ?? '',
      moodIntensity: json['mood_intensity'] ?? 3,
      reflectionText: json['reflection_text'] ?? '',
      aiInsight: json['ai_insight'] ?? '',
      gratitudePrompt: json['gratitude_prompt'] ?? '',
      suggestedAction: json['suggested_action'] ?? '',
      suggestedActionLabel: json['suggested_action_label'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      entryDate: json['entry_date'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood': mood,
      'mood_intensity': moodIntensity,
      'reflection_text': reflectionText,
    };
  }

  bool get hasReflection => reflectionText.isNotEmpty;
  bool get hasInsight => aiInsight.isNotEmpty;
}

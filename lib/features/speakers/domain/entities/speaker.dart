/// Represents a speaker/author in the app
class Speaker {
  final String id;
  final String name;
  final String imageUrl;
  final String bio;
  final String specialization;

  const Speaker({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.bio = '',
    this.specialization = '',
  });

  /// Create a Speaker from JSON
  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      imageUrl: json['imageUrl'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
    );
  }

  /// Convert Speaker to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'bio': bio,
      'specialization': specialization,
    };
  }
}

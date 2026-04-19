/// Data models for the Coach Chat feature.
///
/// Maps to the backend serialization in coaching/chat_views.py:
///   - CoachChatModel  → _serialize_chat()
///   - ChatMessageModel → _serialize_message()
///   - AssignedWorkoutModel → _serialize_assigned_workout()

class CoachChatModel {
  final String id;
  final ChatCoachInfo coach;
  final ChatUserInfo user;
  final ChatLastMessage? lastMessage;
  final int unreadCount;
  final String createdAt;
  final String updatedAt;

  CoachChatModel({
    required this.id,
    required this.coach,
    required this.user,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoachChatModel.fromJson(Map<String, dynamic> json) {
    return CoachChatModel(
      id: json['id'] ?? '',
      coach: ChatCoachInfo.fromJson(json['coach'] ?? {}),
      user: ChatUserInfo.fromJson(json['user'] ?? {}),
      lastMessage: json['last_message'] != null
          ? ChatLastMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class ChatCoachInfo {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? title;
  final List<String> specialties;

  ChatCoachInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.title,
    required this.specialties,
  });

  factory ChatCoachInfo.fromJson(Map<String, dynamic> json) {
    return ChatCoachInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Coach',
      avatarUrl: json['avatar_url'],
      title: json['title'],
      specialties: (json['specialties'] as List?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
    );
  }
}

class ChatUserInfo {
  final String id;
  final String displayName;
  final String? avatarUrl;

  ChatUserInfo({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory ChatUserInfo.fromJson(Map<String, dynamic> json) {
    return ChatUserInfo(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}

class ChatLastMessage {
  final String text;
  final String? messageType;
  final String? createdAt;

  ChatLastMessage({
    required this.text,
    this.messageType,
    this.createdAt,
  });

  factory ChatLastMessage.fromJson(Map<String, dynamic> json) {
    return ChatLastMessage(
      text: json['text'] ?? '',
      messageType: json['message_type'],
      createdAt: json['created_at'],
    );
  }
}

class ChatMessageModel {
  final String id;
  final ChatSender sender;
  final String messageType;
  final String text;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.sender,
    required this.messageType,
    required this.text,
    required this.metadata,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      sender: ChatSender.fromJson(json['sender'] ?? {}),
      messageType: json['message_type'] ?? 'text',
      text: json['text'] ?? '',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  bool get isWorkoutAssignment => messageType == 'workout_assignment';
  bool get isWorkoutCompletion => messageType == 'workout_completion';
  bool get isCoachSuggestion => messageType == 'coach_suggestion';
  bool get isText => messageType == 'text';
}

class ChatSender {
  final String id;
  final String displayName;
  final String? avatarUrl;

  ChatSender({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory ChatSender.fromJson(Map<String, dynamic> json) {
    return ChatSender(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}

class AssignedWorkoutModel {
  final String id;
  final String workoutName;
  final String? workoutTypeId;
  final int durationMinutes;
  final String intensity;
  final String coachNotes;
  final String status;
  final String assignedAt;
  final String? startedAt;
  final String? expiresAt;
  final String? confirmedAt;
  final int? caloriesBurned;
  final String userFeedback;
  final String mood;

  AssignedWorkoutModel({
    required this.id,
    required this.workoutName,
    this.workoutTypeId,
    required this.durationMinutes,
    required this.intensity,
    required this.coachNotes,
    required this.status,
    required this.assignedAt,
    this.startedAt,
    this.expiresAt,
    this.confirmedAt,
    this.caloriesBurned,
    required this.userFeedback,
    required this.mood,
  });

  factory AssignedWorkoutModel.fromJson(Map<String, dynamic> json) {
    return AssignedWorkoutModel(
      id: json['id'] ?? '',
      workoutName: json['workout_name'] ?? '',
      workoutTypeId: json['workout_type_id'],
      durationMinutes: json['duration_minutes'] ?? 0,
      intensity: json['intensity'] ?? 'moderate',
      coachNotes: json['coach_notes'] ?? '',
      status: json['status'] ?? 'assigned',
      assignedAt: json['assigned_at'] ?? '',
      startedAt: json['started_at'],
      expiresAt: json['expires_at'],
      confirmedAt: json['confirmed_at'],
      caloriesBurned: json['calories_burned'],
      userFeedback: json['user_feedback'] ?? '',
      mood: json['mood'] ?? '',
    );
  }

  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';
  bool get canStart => isAssigned;
  bool get canComplete => isInProgress || status == 'pending_confirmation';

  String get intensityEmoji {
    switch (intensity) {
      case 'low': return '🟢';
      case 'moderate': return '🟡';
      case 'high': return '🟠';
      case 'max': return '🔴';
      default: return '⚡';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'assigned': return 'Ready';
      case 'in_progress': return 'In Progress';
      case 'pending_confirmation': return 'Confirm?';
      case 'completed': return 'Completed';
      case 'skipped': return 'Skipped';
      default: return status;
    }
  }
}

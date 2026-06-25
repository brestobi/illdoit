import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// Type of message in a job conversation
enum MessageType {
  text,
  system,
  progressUpdate,
  quickAction,
  location,
  timeBlocked,
}

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'receiver_id') required String receiverId,
    required String content,
    @JsonKey(name: 'job_id') String? jobId,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'message_type') @Default('text') String messageType,
    @Default({}) Map<String, dynamic> metadata,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

/// Represents an active job conversation context
class JobConversation {
  const JobConversation({
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.jobId,
    required this.jobTitle,
    required this.jobType,
    required this.jobStatus,
    this.lastMessage = '',
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String jobId;
  final String jobTitle;
  final String jobType;
  final String jobStatus;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  bool get isPhysical => jobType == 'physical';

  factory JobConversation.fromMap(Map<String, dynamic> map) {
    return JobConversation(
      otherUserId: map['other_user_id'] as String? ?? '',
      otherUserName: map['other_user_name'] as String? ?? 'User',
      otherUserAvatar: map['other_user_avatar'] as String?,
      jobId: map['job_id'] as String? ?? '',
      jobTitle: map['job_title'] as String? ?? 'Job',
      jobType: map['job_type'] as String? ?? 'digital',
      jobStatus: map['job_status'] as String? ?? 'in_progress',
      lastMessage: map['last_message'] as String? ?? '',
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.tryParse(map['last_message_at'] as String)
          : null,
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

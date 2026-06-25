import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/message.dart';
import '../../../../core/repositories/message_repository_impl.dart';

/// Parameters for scoping a chat to a specific job conversation
class ChatParams {
  const ChatParams({
    required this.otherUserId,
    required this.jobId,
    required this.jobTitle,
    required this.jobType,
  });

  final String otherUserId;
  final String jobId;
  final String jobTitle;
  final String jobType;

  bool get isPhysical => jobType == 'physical';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatParams &&
          otherUserId == other.otherUserId &&
          jobId == other.jobId;

  @override
  int get hashCode => Object.hash(otherUserId, jobId);
}

/// Provider for messages in a specific job chat
final jobChatMessagesProvider =
    StreamProvider.family<List<Message>, ChatParams>((ref, params) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  return messageRepository.watchMessages(
    otherUserId: params.otherUserId,
    jobId: params.jobId,
  );
});

/// Provider for all active job conversations (Real-time)
final jobConversationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  return messageRepository.watchConversations();
});

/// Provider that checks if two users have an active job between them
final activeJobBetweenUsersProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, otherUserId) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  return messageRepository.getActiveJobBetween(otherUserId: otherUserId);
});

// ── Legacy aliases (backward compat if still referenced elsewhere) ──────────
final chatMessagesProvider = StreamProvider.family<List<Message>, String>(
  (ref, otherUserId) {
    final repo = ref.watch(messageRepositoryProvider);
    return repo.watchMessages(otherUserId: otherUserId);
  },
);

final conversationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(messageRepositoryProvider);
  return repo.watchConversations();
});

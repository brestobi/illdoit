import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/message.dart';
import '../../../../core/repositories/message_repository_impl.dart';

/// Provider for messages in a specific chat
final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, otherUserId) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  return messageRepository.watchMessages(otherUserId: otherUserId);
});

/// Provider for all active conversations (Real-time)
final conversationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  return messageRepository.watchConversations();
});

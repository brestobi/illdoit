import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';

/// Concrete implementation of MessageRepository using Supabase
class MessageRepositoryImpl implements MessageRepository {
  final SupabaseService _supabaseService;

  MessageRepositoryImpl(this._supabaseService);

  @override
  Future<Message> sendMessage({
    required String receiverId,
    required String content,
    String? imageUrl,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      final response = await _supabaseService.insert(
        table: 'messages',
        data: {
          'sender_id': currentUser.id,
          'receiver_id': receiverId,
          'content': content,
          'image_url': imageUrl,
          'is_read': false,
        },
      );
      return Message.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to send message: $e');
    }
  }

  @override
  Future<String> uploadChatImage({required List<int> bytes}) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      final fileName = 'chat/${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      return await _supabaseService.uploadFile(
        bucket: 'chat-images',
        path: fileName,
        bytes: bytes,
      );
    } catch (e) {
      throw ServerException('Failed to upload chat image: $e');
    }
  }

  @override
  Future<List<Message>> getChatMessages({required String otherUserId}) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      final results = await _supabaseService.client
          .from('messages')
          .select()
          .or('and(sender_id.eq.${currentUser.id},receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.${currentUser.id})')
          .order('created_at', ascending: true);

      return (results as List).map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      throw ServerException('Failed to fetch messages: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getConversations() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      // This is a complex query in Supabase/Postgres. 
      // For MVP, we'll fetch unique users the current user has messaged or received messages from.
      final results = await _supabaseService.client
          .from('messages')
          .select('sender_id, receiver_id')
          .or('sender_id.eq.${currentUser.id},receiver_id.eq.${currentUser.id}');

      final userIds = <String>{};
      for (var row in (results as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        if (map['sender_id'] != currentUser.id) userIds.add(map['sender_id'] as String);
        if (map['receiver_id'] != currentUser.id) userIds.add(map['receiver_id'] as String);
      }

      if (userIds.isEmpty) return [];

      // Fetch user details for these IDs
      final users = await _supabaseService.client
          .from('users')
          .select('id, display_name, avatar_url')
          .in_('id', userIds.toList());

      return (users as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch conversations: $e');
    }
  }

  @override
  Future<void> markAsRead({required String senderId}) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      await _supabaseService.client
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', senderId)
          .eq('receiver_id', currentUser.id)
          .eq('is_read', false);
    } catch (e) {
      throw ServerException('Failed to mark messages as read: $e');
    }
  }

  @override
  Stream<List<Message>> watchMessages({required String otherUserId}) {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    return _supabaseService.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((event) {
          return event
              .where((row) =>
                  (row['sender_id'] == currentUser.id && row['receiver_id'] == otherUserId) ||
                  (row['sender_id'] == otherUserId && row['receiver_id'] == currentUser.id))
              .map((e) => Message.fromJson(e))
              .toList();
        });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchConversations() {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    // This is a simplified version of real-time conversations.
    // We watch all messages involving the current user, then fetch profiles for unique user IDs.
    return _supabaseService.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((event) async {
          final userIds = <String>{};
          for (var row in event) {
            if (row['sender_id'] == currentUser.id) {
              userIds.add(row['receiver_id'] as String);
            } else if (row['receiver_id'] == currentUser.id) {
              userIds.add(row['sender_id'] as String);
            }
          }

          if (userIds.isEmpty) return [];

          // Fetch user details for these IDs
          final users = await _supabaseService.client
              .from('users')
              .select('id, display_name, avatar_url')
              .in_('id', userIds.toList());

          return (users as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
  }
}

/// Provider for MessageRepository
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return MessageRepositoryImpl(supabaseService);
});

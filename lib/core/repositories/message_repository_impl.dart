import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';

/// Concrete implementation of MessageRepository using Supabase
/// All messaging is scoped to an active (in_progress) job between two users.
class MessageRepositoryImpl implements MessageRepository {

  MessageRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

  // ── Time-block enforcement ────────────────────────────────────────────────
  // Physical jobs cannot be done between 4:00 PM and 7:00 AM (local time).
  static bool isWithinAllowedHours() {
    final now = DateTime.now();
    final hour = now.hour;
    // Allowed: 07:00 – 15:59 (i.e., 7 AM inclusive to before 4 PM)
    return hour >= 7 && hour < 16;
  }

  static bool isPhysicalTimeBlocked() => !isWithinAllowedHours();

  /// Returns time remaining until next allowed window (for display)
  static String timeUntilNextWindow() {
    final now = DateTime.now();
    DateTime nextOpen;
    if (now.hour < 7) {
      nextOpen = DateTime(now.year, now.month, now.day, 7, 0);
    } else {
      // After 4 PM — next window is 7 AM tomorrow
      nextOpen = DateTime(now.year, now.month, now.day + 1, 7, 0);
    }
    final diff = nextOpen.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h}h ${m}m';
  }

  // ── Job validation ────────────────────────────────────────────────────────

  /// Verifies an active in_progress job exists between current user and otherUserId.
  /// Returns the job data or throws a [BusinessRuleException].
  Future<Map<String, dynamic>?> getActiveJobBetween({
    required String otherUserId,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final results = await _supabaseService.client.rpc(
        'get_active_job_between_users',
        params: {
          'p_user_a': currentUser.id,
          'p_user_b': otherUserId,
        },
      );
      final list = results as List?;
      if (list == null || list.isEmpty) return null;
      return Map<String, dynamic>.from(list.first as Map);
    } catch (_) {
      // Fallback: direct query if RPC not yet deployed
      try {
        final result = await _supabaseService.client
            .from('jobs')
            .select('id, title, job_type, status, deadline, client_id, worker_id, budget, location, category')
            .eq('status', 'in_progress')
            .or('and(client_id.eq.${currentUser.id},worker_id.eq.$otherUserId),and(client_id.eq.$otherUserId,worker_id.eq.${currentUser.id})')
            .limit(1);
        final list2 = result as List?;
        if (list2 == null || list2.isEmpty) return null;
        return Map<String, dynamic>.from(list2.first as Map);
      } catch (e) {
        throw ServerException('Failed to validate job context: $e');
      }
    }
  }

  // ── Send message ──────────────────────────────────────────────────────────

  @override
  Future<Message> sendMessage({
    required String receiverId,
    required String content,
    String? imageUrl,
    String? jobId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    // 1. Validate there is an in_progress job between the parties
    final job = jobId != null
        ? await _getJobById(jobId)
        : await getActiveJobBetween(otherUserId: receiverId);

    if (job == null) {
      throw BusinessRuleException(
        'Messaging is only available when you have an active job together. '
        'Accept an application or get hired to start chatting.',
      );
    }

    final resolvedJobId = job['id'] as String;
    final resolvedJobType = job['job_type'] as String? ?? 'digital';

    // 2. Time-block enforcement for physical jobs
    if (resolvedJobType == 'physical' && messageType != 'system') {
      if (isPhysicalTimeBlocked()) {
        throw BusinessRuleException(
          'Physical job communications are restricted between 4:00 PM and 7:00 AM for your safety. '
          'Please try again at 7:00 AM (in ${timeUntilNextWindow()}).',
        );
      }
    }

    try {
      final response = await _supabaseService.insert(
        table: 'messages',
        data: {
          'sender_id': currentUser.id,
          'receiver_id': receiverId,
          'content': content,
          'image_url': imageUrl,
          'job_id': resolvedJobId,
          'message_type': messageType,
          'metadata': metadata ?? {},
          'is_read': false,
        },
      );
      return Message.fromJson(response);
    } catch (e) {
      if (e is BusinessRuleException) rethrow;
      throw ServerException('Failed to send message: $e');
    }
  }

  Future<Map<String, dynamic>?> _getJobById(String jobId) async {
    try {
      final result = await _supabaseService.client
          .from('jobs')
          .select('id, title, job_type, status, deadline, client_id, worker_id, budget, location, category')
          .eq('id', jobId)
          .eq('status', 'in_progress')
          .limit(1);
      final list = result as List?;
      if (list == null || list.isEmpty) return null;
      return Map<String, dynamic>.from(list.first as Map);
    } catch (_) {
      return null;
    }
  }

  // ── Send quick action (physical jobs only) ────────────────────────────────

  Future<Message> sendQuickAction({
    required String receiverId,
    required String actionKey,
    required String actionLabel,
    required String jobId,
  }) async {
    return sendMessage(
      receiverId: receiverId,
      content: actionLabel,
      jobId: jobId,
      messageType: 'quick_action',
      metadata: {'action_key': actionKey, 'action_label': actionLabel},
    );
  }

  // ── Share location ────────────────────────────────────────────────────────

  Future<Message> shareLocation({
    required String receiverId,
    required double latitude,
    required double longitude,
    required String jobId,
    String? addressLabel,
  }) async {
    final label = addressLabel ?? '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    return sendMessage(
      receiverId: receiverId,
      content: '📍 Shared location: $label',
      jobId: jobId,
      messageType: 'location',
      metadata: {
        'latitude': latitude,
        'longitude': longitude,
        'address_label': label,
        'shared_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // ── Send progress update ──────────────────────────────────────────────────

  Future<Message> sendProgressUpdate({
    required String receiverId,
    required String jobId,
    required String updateText,
    int? progressPercent,
  }) async {
    return sendMessage(
      receiverId: receiverId,
      content: updateText,
      jobId: jobId,
      messageType: 'progress_update',
      metadata: {
        if (progressPercent != null) 'progress_percent': progressPercent,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // ── Get chat messages ─────────────────────────────────────────────────────

  @override
  Future<List<Message>> getChatMessages({
    required String otherUserId,
    String? jobId,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      dynamic query = _supabaseService.client
          .from('messages')
          .select()
          .or('and(sender_id.eq.${currentUser.id},receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.${currentUser.id})')
          .order('created_at', ascending: true);

      if (jobId != null) {
        query = _supabaseService.client
            .from('messages')
            .select()
            .eq('job_id', jobId)
            .or('and(sender_id.eq.${currentUser.id},receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.${currentUser.id})')
            .order('created_at', ascending: true);
      }

      final results = await query;
      return (results as List)
          .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch messages: $e');
    }
  }

  // ── Conversations ─────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getConversations() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      // Try the DB function first
      final results = await _supabaseService.client.rpc(
        'get_job_conversations',
        params: {'p_user_id': currentUser.id},
      );
      return (results as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      // Fallback: query in_progress jobs where user is client or worker
      try {
        final jobs = await _supabaseService.client
            .from('jobs')
            .select('id, title, job_type, status, client_id, worker_id')
            .eq('status', 'in_progress')
            .or('client_id.eq.${currentUser.id},worker_id.eq.${currentUser.id}');

        final List<Map<String, dynamic>> conversations = [];
        for (final job in jobs as List) {
          final jobMap = Map<String, dynamic>.from(job as Map);
          final otherId = jobMap['client_id'] == currentUser.id
              ? jobMap['worker_id']
              : jobMap['client_id'];
          if (otherId == null) continue;

          final users = await _supabaseService.client
              .from('users')
              .select('id, display_name, avatar_url')
              .eq('id', otherId as String);
          final userList = users as List;
          if (userList.isEmpty) continue;
          final user = Map<String, dynamic>.from(userList.first as Map);

          conversations.add({
            'other_user_id': otherId,
            'other_user_name': user['display_name'],
            'other_user_avatar': user['avatar_url'],
            'job_id': jobMap['id'],
            'job_title': jobMap['title'],
            'job_type': jobMap['job_type'],
            'job_status': jobMap['status'],
            'last_message': '',
            'last_message_at': null,
            'unread_count': 0,
          });
        }
        return conversations;
      } catch (e) {
        throw ServerException('Failed to fetch conversations: $e');
      }
    }
  }

  @override
  Future<void> markAsRead({required String senderId, String? jobId}) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      dynamic query = _supabaseService.client
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', senderId)
          .eq('receiver_id', currentUser.id)
          .eq('is_read', false);

      if (jobId != null) {
        query = _supabaseService.client
            .from('messages')
            .update({'is_read': true})
            .eq('sender_id', senderId)
            .eq('receiver_id', currentUser.id)
            .eq('job_id', jobId)
            .eq('is_read', false);
      }

      await query;
    } catch (e) {
      throw ServerException('Failed to mark messages as read: $e');
    }
  }

  @override
  Stream<List<Message>> watchMessages({
    required String otherUserId,
    String? jobId,
  }) {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    return _supabaseService.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((event) => event
              .where((row) {
                final isParty =
                    (row['sender_id'] == currentUser.id &&
                        row['receiver_id'] == otherUserId) ||
                    (row['sender_id'] == otherUserId &&
                        row['receiver_id'] == currentUser.id);
                if (!isParty) return false;
                if (jobId != null) return row['job_id'] == jobId;
                return true;
              })
              .map(Message.fromJson)
              .toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> watchConversations() {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    // Watch in_progress jobs — refresh conversations whenever job list changes
    return _supabaseService.client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .asyncMap((event) async {
          final myJobs = (event).where((j) =>
              j['status'] == 'in_progress' &&
              (j['client_id'] == currentUser.id ||
                  j['worker_id'] == currentUser.id));

          final List<Map<String, dynamic>> conversations = [];
          for (final job in myJobs) {
            final otherId = job['client_id'] == currentUser.id
                ? job['worker_id']
                : job['client_id'];
            if (otherId == null) continue;

            final users = await _supabaseService.client
                .from('users')
                .select('id, display_name, avatar_url')
                .eq('id', otherId as String);
            final userList = users as List;
            if (userList.isEmpty) continue;
            final user = Map<String, dynamic>.from(userList.first as Map);

            // Fetch last message for this job
            final lastMsgs = await _supabaseService.client
                .from('messages')
                .select('content, created_at, is_read, receiver_id')
                .eq('job_id', job['id'] as String)
                .order('created_at', ascending: false)
                .limit(1);
            final lastMsgList = lastMsgs as List;
            final lastMsg = lastMsgList.isNotEmpty
                ? Map<String, dynamic>.from(lastMsgList.first as Map)
                : null;

            // Count unread
            final unreadResult = await _supabaseService.client
                .from('messages')
                .select('id')
                .eq('job_id', job['id'] as String)
                .eq('receiver_id', currentUser.id)
                .eq('is_read', false);
            final unread = (unreadResult as List).length;

            conversations.add({
              'other_user_id': otherId,
              'other_user_name': user['display_name'] ?? 'User',
              'other_user_avatar': user['avatar_url'],
              'job_id': job['id'],
              'job_title': job['title'] ?? 'Job',
              'job_type': job['job_type'] ?? 'digital',
              'job_status': job['status'] ?? 'in_progress',
              'last_message': lastMsg?['content'] ?? '',
              'last_message_at': lastMsg?['created_at'],
              'unread_count': unread,
            });
          }
          return conversations;
        });
  }
}

/// Business rule exception for messaging restrictions
class BusinessRuleException implements Exception {
  BusinessRuleException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Provider for MessageRepository
final messageRepositoryProvider = Provider<MessageRepositoryImpl>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return MessageRepositoryImpl(supabaseService);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../models/app_notification.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';

/// Concrete implementation of NotificationRepository using Supabase
class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseService _supabaseService;

  NotificationRepositoryImpl(this._supabaseService);

  @override
  Future<List<AppNotification>> getNotifications() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final results = await _supabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return (results as List).map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      throw ServerException('Failed to fetch notifications: $e');
    }
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {
    try {
      await _supabaseService.update(
        table: 'notifications',
        id: notificationId,
        data: {'is_read': true},
      );
    } catch (e) {
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      await _supabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', currentUser.id)
          .eq('is_read', false);
    } catch (e) {
      throw ServerException('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification({required String notificationId}) async {
    try {
      await _supabaseService.delete(table: 'notifications', id: notificationId);
    } catch (e) {
      throw ServerException('Failed to delete notification: $e');
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _supabaseService.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false)
        .map((results) => results.map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map))).toList());
  }

  @override
  Future<int> getUnreadCount() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return 0;

    try {
      final response = await _supabaseService.client
          .from('notifications')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', currentUser.id)
          .eq('is_read', false);
      
      return response.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return NotificationRepositoryImpl(supabaseService);
});

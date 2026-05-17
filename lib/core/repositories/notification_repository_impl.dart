import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<void> markAsRead(String id) async {
    try {
      await _supabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return;

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
  Future<void> deleteNotification(String id) async {
    try {
      await _supabaseService.client
          .from('notifications')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete notification: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return 0;

    try {
      final response = await _supabaseService.client
          .from('notifications')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('is_read', false);
      
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _supabaseService.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false)
        .map((event) {
          return event.map((e) => AppNotification.fromJson(e)).toList();
        });
  }
}

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return NotificationRepositoryImpl(supabaseService);
});

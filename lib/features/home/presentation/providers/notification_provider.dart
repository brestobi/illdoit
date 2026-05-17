import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/app_notification.dart';
import '../../../../core/repositories/notification_repository_impl.dart';

/// Provider for real-time notifications
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchNotifications();
});

/// Provider for unread notification count
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchNotifications().map((list) => list.where((n) => !n.isRead).length);
});

/// Notifier for notification actions
class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationRepositoryImpl _repository;

  NotificationNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider) as NotificationRepositoryImpl;
  return NotificationNotifier(repository);
});

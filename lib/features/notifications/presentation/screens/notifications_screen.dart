import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/models/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref.read(notificationNotifierProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationItem(notification: notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Could not load notifications',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {

  const _NotificationItem({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('MMM dd, HH:mm').format(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(notificationNotifierProvider.notifier).deleteNotification(notification.id);
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(context, ref),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
            border: const Border(bottom: BorderSide(color: AppColors.borderColor)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color color;

    switch (notification.type) {
      case 'chat':
        iconData = Icons.chat_bubble_outline_rounded;
        color = Colors.blue;
        break;
      case 'order':
        iconData = Icons.shopping_bag_outlined;
        color = Colors.orange;
        break;
      case 'job_application':
        iconData = Icons.assignment_outlined;
        color = Colors.purple;
        break;
      case 'payment':
        iconData = Icons.payments_outlined;
        color = Colors.green;
        break;
      case 'review':
        iconData = Icons.star_outline_rounded;
        color = AppColors.primary;
        break;
      default:
        iconData = Icons.notifications_none_rounded;
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref) {
    if (!notification.isRead) {
      ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }

    // Navigation logic based on notification type and data
    final data = notification.data;
    switch (notification.type) {
      case 'chat':
        final senderId = data['sender_id'];
        if (senderId != null) {
          context.push(AppRoutes.chat.replaceFirst(':id', senderId), extra: 'User');
        }
        break;
      case 'order':
        context.push(AppRoutes.myOrders);
        break;
      case 'job_application':
        final jobId = data['job_id'];
        if (jobId != null) {
          context.push(AppRoutes.manageApplications.replaceFirst(':jobId', jobId));
        } else {
          context.push(AppRoutes.myApplications);
        }
        break;
      case 'payment':
        context.push(AppRoutes.wallet);
        break;
      case 'review':
        context.push(AppRoutes.profile);
        break;
      default:
        // Stay on current screen if no specific destination
        break;
    }
  }
}

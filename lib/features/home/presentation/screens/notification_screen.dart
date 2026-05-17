import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_notification.dart';
import '../../../../core/router/app_router.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => ref.read(notificationNotifierProvider.notifier).markAllAsRead(),
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
                  Icon(Icons.notifications_none, size: 64, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationItem(notification: notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationItem({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('MMM dd, HH:mm').format(notification.createdAt);
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(notificationNotifierProvider.notifier).deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
          }
          _handleTap(context, notification);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? AppColors.surface : AppColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead ? AppColors.borderColor : AppColors.primary.withValues(alpha: 0.3),
            ),
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
                            fontSize: 14,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!notification.isRead)
                          const CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeStr,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
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
        iconData = Icons.chat_bubble_outline;
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
        iconData = Icons.account_balance_wallet_outlined;
        color = AppColors.primary;
        break;
      case 'review':
        iconData = Icons.star_outline;
        color = Colors.yellow;
        break;
      default:
        iconData = Icons.notifications_outlined;
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  void _handleTap(BuildContext context, AppNotification notification) {
    final type = notification.type;
    final data = notification.data;

    if (type == 'chat') {
      final senderId = data['sender_id'];
      if (senderId != null) {
        context.push(AppRoutes.chat.replaceFirst(':id', senderId));
      } else {
        context.push(AppRoutes.chat);
      }
    } else if (type == 'order') {
      context.push(AppRoutes.myOrders);
    } else if (type == 'job_application') {
      final jobId = data['job_id'];
      if (jobId != null) {
        context.push(AppRoutes.jobDetail.replaceFirst(':id', jobId));
      }
    } else if (type == 'payment') {
      context.push(AppRoutes.wallet);
    } else if (type == 'review') {
      final reviewerId = data['reviewer_id'];
      if (reviewerId != null) {
        context.push(AppRoutes.publicProfile.replaceFirst(':id', reviewerId));
      }
    }
  }
}

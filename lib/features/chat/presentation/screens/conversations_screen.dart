import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../providers/chat_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(jobConversationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Job Messages'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push(AppRoutes.safetyTips),
            tooltip: 'Safety Tips',
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) => conversations.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.question_answer_outlined,
                        size: 64,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active job chats yet.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chats will appear here once you have an in-progress job together. All communication must be about the job.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conv = conversations[index];
                  return _buildConversationTile(context, conv);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Could not load conversations',
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildConversationTile(BuildContext context, Map<String, dynamic> conv) {
    final theme = Theme.of(context);
    final otherUserId = conv['other_user_id'] ?? conv['id'] ?? '';
    final otherUserName = conv['other_user_name'] ?? conv['display_name'] ?? 'User';
    final otherUserAvatar = conv['other_user_avatar'] ?? conv['avatar_url'];
    final jobTitle = conv['job_title'] ?? 'Job';
    final jobType = conv['job_type'] ?? 'digital';
    final lastMsg = conv['last_message'] ?? 'Tap to view chat';
    final unreadCount = conv['unread_count'] as int? ?? 0;

    final isPhysical = jobType == 'physical';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          context.push(
            AppRoutes.chat.replaceFirst(':id', otherUserId),
            extra: otherUserName,
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: theme.primaryColor,
          backgroundImage: otherUserAvatar != null ? NetworkImage(otherUserAvatar) : null,
          child: otherUserAvatar == null
              ? Icon(Icons.person, color: theme.colorScheme.onPrimary)
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUserName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPhysical
                    ? AppColors.blue.withValues(alpha: 0.15)
                    : AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPhysical ? Icons.directions_run : Icons.computer,
                    size: 12,
                    color: isPhysical ? AppColors.blue : AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      jobTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPhysical ? AppColors.blue : AppColors.gold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unreadCount > 0 ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodySmall?.color,
                fontSize: 13,
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: theme.disabledColor,
        ),
      ),
    );
  }
}

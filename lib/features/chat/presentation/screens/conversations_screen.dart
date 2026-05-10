import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../providers/chat_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
      ),
      body: conversationsAsync.when(
        data: (conversations) => conversations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No messages yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
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
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildConversationTile(BuildContext context, Map<String, dynamic> conv) {
    return ListTile(
      onTap: () {
        context.push(
          AppRoutes.chat.replaceFirst(':id', conv['id']),
          extra: conv['display_name'],
        );
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primary,
        backgroundImage: conv['avatar_url'] != null
            ? NetworkImage(conv['avatar_url'])
            : null,
        child: conv['avatar_url'] == null
            ? const Icon(Icons.person, color: AppColors.darkBg)
            : null,
      ),
      title: Text(
        conv['display_name'] ?? 'Unknown',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text(
        'Tap to chat',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}

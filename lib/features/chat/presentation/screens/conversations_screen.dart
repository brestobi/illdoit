import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../providers/chat_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No messages yet.',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
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
    final theme = Theme.of(context);
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
        backgroundColor: theme.primaryColor,
        backgroundImage: conv['avatar_url'] != null
            ? NetworkImage(conv['avatar_url'])
            : null,
        child: conv['avatar_url'] == null
            ? Icon(Icons.person, color: theme.colorScheme.onPrimary)
            : null,
      ),
      title: Text(
        conv['display_name'] ?? 'Unknown',
        style: TextStyle(
          color: theme.textTheme.titleMedium?.color,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Tap to chat',
        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.disabledColor,
      ),
    );
  }
}

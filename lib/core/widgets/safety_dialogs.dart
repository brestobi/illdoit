import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../repositories/user_repository_impl.dart';
import '../repositories/app_config_repository.dart';

class ReportUserDialog extends ConsumerStatefulWidget {
const ReportUserDialog({
  super.key,
  required this.targetUserId,
  required this.targetUserName,
});
  final String targetUserId;
  final String targetUserName;

  @override
  ConsumerState<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends ConsumerState<ReportUserDialog> {
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportReasonsAsync = ref.watch(reportReasonsProvider);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Report ${widget.targetUserName}', style: const TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you reporting this user?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            reportReasonsAsync.when(
              data: (reasons) => Column(
                children: reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (val) => setState(() => _selectedReason = val),
                  activeColor: AppColors.primary,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Text('Error loading reasons: $e', style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Provide more details (optional)',
                hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer(
          builder: (context, ref, child) => ElevatedButton(
              onPressed: (_selectedReason == null || _isLoading) ? null : () async {
                setState(() => _isLoading = true);
                try {
                  await ref.read(userRepositoryProvider).reportUser(
                    targetUserId: widget.targetUserId,
                    reason: _selectedReason!,
                    description: _descriptionController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted. We will investigate this user.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit Report'),
            ),
        ),
      ],
    );
  }
}

class BlockUserDialog extends StatefulWidget {

  const BlockUserDialog({super.key, 
    required this.targetUserId,
    required this.targetUserName,
  });
  final String targetUserId;
  final String targetUserName;

  @override
  State<BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<BlockUserDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Block ${widget.targetUserName}?', style: const TextStyle(color: AppColors.textPrimary)),
      content: const Text(
        'You will no longer receive messages from this user, and they won\'t be able to see your profile or services.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer(
          builder: (context, ref, child) => ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                try {
                  await ref.read(userRepositoryProvider).blockUser(targetUserId: widget.targetUserId);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${widget.targetUserName} has been blocked.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Block User', style: TextStyle(color: Colors.white)),
            ),
        ),
      ],
    );
}

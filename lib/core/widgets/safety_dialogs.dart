import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../repositories/user_repository_impl.dart';

class ReportUserDialog extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const ReportUserDialog({
    Key? key,
    required this.targetUserId,
    required this.targetUserName,
  }) : super(key: key);

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  final List<String> _reasons = [
    'Scam or Fraud',
    'Abusive Behavior',
    'Inappropriate Content',
    'Late / No-show for job',
    'Poor quality of work',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            ..._reasons.map((reason) => RadioListTile<String>(
              title: Text(reason, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val),
              activeColor: AppColors.primary,
              dense: true,
              contentPadding: EdgeInsets.zero,
            )),
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
          builder: (context, ref, child) {
            return ElevatedButton(
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
            );
          },
        ),
      ],
    );
  }
}

class BlockUserDialog extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const BlockUserDialog({
    Key? key,
    required this.targetUserId,
    required this.targetUserName,
  }) : super(key: key);

  @override
  State<BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<BlockUserDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Block ${widget.targetUserName}?', style: const TextStyle(color: AppColors.textPrimary)),
      content: Text(
        'You will no longer receive messages from this user, and they won\'t be able to see your profile or services.',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer(
          builder: (context, ref, child) {
            return ElevatedButton(
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
            );
          },
        ),
      ],
    );
  }
}

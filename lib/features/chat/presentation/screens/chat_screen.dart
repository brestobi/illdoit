import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/message.dart';
import '../../../../core/repositories/message_repository_impl.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/safety_dialogs.dart';
import '../../../../core/router/app_router.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  final String otherUserId;
  final String otherUserName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  bool _isLocationSharingLoading = false;
  bool _hasSensitiveInfo = false;
  String? _sensitiveWarning;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();

    // Mark messages as read when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageRepositoryProvider).markAsRead(senderId: widget.otherUserId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isRestrictedHours() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 16 || hour < 7; // 4:00 PM to 7:00 AM
  }

  String _timeUntilNextWindow() {
    return MessageRepositoryImpl.timeUntilNextWindow();
  }

  void _scanMessageText(String text) {
    final cleanText = text.toLowerCase();

    // Regex to match phone numbers (7+ digits, option + prefix)
    final phoneRegex = RegExp(r'(\+?\d[\d\s\-\(\)]‌{7,}\d)');
    // Regex for emails
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');

    // Specific risk terms
    final keywords = [
      'whatsapp', 'phone', 'email', 'cell', 'number', 'mobile',
      'pay', 'bank', 'eft', 'cash', 'money', 'transfer', 'capitec',
      'fnb', 'std bank', 'nedbank', 'absa', 'external', 'outside'
    ];

    bool containsKeyword = false;
    for (final word in keywords) {
      if (cleanText.contains(word)) {
        containsKeyword = true;
        break;
      }
    }

    final containsPhone = phoneRegex.hasMatch(cleanText) || _containsPhoneFallback(cleanText);
    final containsEmail = emailRegex.hasMatch(cleanText);

    if (containsPhone || containsEmail || containsKeyword) {
      setState(() {
        _hasSensitiveInfo = true;
        _sensitiveWarning = '⚠️ Safety Notice: Always keep payments and messaging inside I\'ll Do It. Sharing details violates safety policies.';
      });
    } else {
      setState(() {
        _hasSensitiveInfo = false;
        _sensitiveWarning = null;
      });
    }
  }

  bool _containsPhoneFallback(String text) {
    // Basic digit matching for phone numbers
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 15;
  }

  void _sendMessage(String jobId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _hasSensitiveInfo = false;
      _sensitiveWarning = null;
    });

    try {
      await ref.read(messageRepositoryProvider).sendMessage(
            receiverId: widget.otherUserId,
            content: text,
            jobId: jobId,
          );

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  void _sendQuickAction(String actionKey, String label, String jobId) async {
    try {
      await ref.read(messageRepositoryProvider).sendQuickAction(
            receiverId: widget.otherUserId,
            actionKey: actionKey,
            actionLabel: label,
            jobId: jobId,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send quick action: $e')),
        );
      }
    }
  }

  Future<void> _shareLocation(String jobId) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied.')),
          );
        }
        return;
      }

      setState(() => _isLocationSharingLoading = true);

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await ref.read(messageRepositoryProvider).shareLocation(
            receiverId: widget.otherUserId,
            latitude: position.latitude,
            longitude: position.longitude,
            jobId: jobId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📍 Location shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocationSharingLoading = false);
    }
  }

  void _showProgressUpdateBottomSheet(String jobId) {
    double percent = 50;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Job Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Progress: ${percent.toInt()}%',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Slider(
                    value: percent,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    activeColor: AppColors.blue,
                    inactiveColor: AppColors.borderColor,
                    onChanged: (val) {
                      setModalState(() {
                        percent = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Progress description (optional)',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final desc = controller.text.trim();
                        final updateText = desc.isEmpty
                            ? '📊 Job progress updated to ${percent.toInt()}%'
                            : '📊 Job progress: ${percent.toInt()}% - $desc';

                        Navigator.pop(context);

                        try {
                          await ref.read(messageRepositoryProvider).sendProgressUpdate(
                                receiverId: widget.otherUserId,
                                jobId: jobId,
                                updateText: updateText,
                                progressPercent: percent.toInt(),
                              );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update progress: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Send Update', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSOSDialog(Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Icon(Icons.shield_outlined, color: AppColors.error, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Emergency SOS Assistance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you feel unsafe or are in immediate danger, please use the options below to call emergency services or instantly share your GPS coordinate.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Police (10111)', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final uri = Uri.parse('tel:10111');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.my_location),
                        label: const Text('Share GPS Info', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _shareLocation(job['id'] as String);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Dismiss', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeJobAsync = ref.watch(activeJobBetweenUsersProvider(widget.otherUserId));
    final currentUserId = ref.read(supabaseServiceProvider).currentUser?.id;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor,
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.otherUserName, style: const TextStyle(fontSize: 16)),
                  activeJobAsync.when(
                    data: (job) => job != null
                        ? Text(
                            job['job_type'] == 'physical' ? 'Physical Job' : 'Digital Job',
                            style: TextStyle(fontSize: 11, color: theme.disabledColor),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          activeJobAsync.when(
            data: (job) {
              if (job == null) return const SizedBox.shrink();
              final isPhysical = job['job_type'] == 'physical';
              if (!isPhysical) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.shield, color: AppColors.error),
                onPressed: () => _showSOSDialog(job),
                tooltip: 'Emergency SOS',
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'report') {
                showDialog(
                  context: context,
                  builder: (context) => ReportUserDialog(
                    targetUserId: widget.otherUserId,
                    targetUserName: widget.otherUserName,
                  ),
                );
              } else if (value == 'block') {
                showDialog(
                  context: context,
                  builder: (context) => BlockUserDialog(
                    targetUserId: widget.otherUserId,
                    targetUserName: widget.otherUserName,
                  ),
                );
              } else if (value == 'tips') {
                context.push(AppRoutes.safetyTips);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'tips',
                child: Row(
                  children: [
                    Icon(Icons.security, size: 20),
                    SizedBox(width: 8),
                    Text('Safety Center'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_outlined, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text('Report User', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text('Block User', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: activeJobAsync.when(
        data: (job) {
          if (job == null) {
            return _buildNoActiveJobView();
          }

          final jobId = job['id'] as String;
          final jobTitle = job['title'] as String? ?? 'Job';
          final jobType = job['job_type'] as String? ?? 'digital';
          final isPhysical = jobType == 'physical';

          final isRestricted = isPhysical && _isRestrictedHours();

          return Column(
            children: [
              _buildJobHeaderBanner(job),
              _buildPrivacyDisclaimer(),
              if (isRestricted) _buildRestrictedBanner(),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final params = ChatParams(
                      otherUserId: widget.otherUserId,
                      jobId: jobId,
                      jobTitle: jobTitle,
                      jobType: jobType,
                    );
                    final messagesAsync = ref.watch(jobChatMessagesProvider(params));

                    return messagesAsync.when(
                      data: (messages) {
                        final reversedMessages = messages.reversed.toList();
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: reversedMessages.length,
                          itemBuilder: (context, index) {
                            final message = reversedMessages[index];
                            final isMe = message.senderId == currentUserId;
                            return _buildMessageWrapper(message, isMe);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    );
                  },
                ),
              ),
              _buildInputSection(jobId, isPhysical, isRestricted),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading active job: $err')),
      ),
    );
  }

  Widget _buildNoActiveJobView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Messaging Unavailable',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can only communicate if you have an active, in-progress job together. All communications must remain on-platform and be related directly to the job.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobHeaderBanner(Map<String, dynamic> job) {
    final title = job['title'] ?? 'Job';
    final isPhysical = job['job_type'] == 'physical';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Icon(
            isPhysical ? Icons.directions_run : Icons.computer,
            color: isPhysical ? AppColors.blue : AppColors.gold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Communication must strictly focus on this job.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'IN PROGRESS',
              style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyDisclaimer() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Safety Warning: Avoid sharing email, phone number, or external payment methods.',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.error.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.timer_off_outlined, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restricted Hours (4:00 PM - 7:00 AM)',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Physical work & messaging are locked for safety. Window opens in ${_timeUntilNextWindow()}.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWrapper(Message message, bool isMe) {
    if (message.messageType == 'progress_update') {
      return _buildProgressUpdateBubble(message);
    }
    if (message.messageType == 'location') {
      return _buildLocationBubble(message);
    }
    if (message.messageType == 'quick_action') {
      return _buildQuickActionBubble(message);
    }
    return _buildMessageBubble(message, isMe);
  }

  Widget _buildProgressUpdateBubble(Message message) {
    final percent = message.metadata['progress_percent'] as int?;
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.blue, size: 16),
                SizedBox(width: 6),
                Text(
                  'PROGRESS UPDATE',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.content,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            if (percent != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: AppColors.borderColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percent%',
                    style: const TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBubble(Message message) {
    final lat = message.metadata['latitude'] as double?;
    final lng = message.metadata['longitude'] as double?;
    final label = message.metadata['address_label'] as String? ?? 'Shared GPS Coordinate';
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: AppColors.success, size: 16),
                SizedBox(width: 6),
                Text(
                  'LOCATION SHARING',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            if (lat != null && lng != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('Open in Google Maps', style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBubble(Message message) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.blue, size: 16),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) => Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
            ),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: message.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        width: 200,
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => const SizedBox(
                        width: 200,
                        height: 200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.white70),
                            SizedBox(height: 8),
                            Text(
                              'Image failed to load',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? AppColors.darkBg : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: TextStyle(
                  color: (isMe ? AppColors.darkBg : AppColors.textSecondary).withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildInputSection(String jobId, bool isPhysical, bool isRestricted) {
    if (isRestricted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderColor)),
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_clock, color: AppColors.textTertiary, size: 16),
                SizedBox(width: 8),
                Text(
                  'Messaging is disabled during restricted hours.',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPhysical) _buildQuickActionChips(jobId),
            if (_sensitiveWarning != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.error.withValues(alpha: 0.1),
                child: Text(
                  _sensitiveWarning!,
                  style: const TextStyle(color: AppColors.error, fontSize: 11),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.trending_up, color: AppColors.blue),
                    onPressed: () => _showProgressUpdateBottomSheet(jobId),
                    tooltip: 'Send progress update',
                  ),
                  if (isPhysical)
                    IconButton(
                      icon: _isLocationSharingLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, color: AppColors.success),
                      onPressed: _isLocationSharingLoading ? null : () => _shareLocation(jobId),
                      tooltip: 'Share current location',
                    ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _scanMessageText,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.darkBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: AppColors.darkBg),
                      onPressed: () => _sendMessage(jobId),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChips(String jobId) {
    final chips = [
      {'key': 'way', 'label': 'I\'m on my way! 🚗'},
      {'key': 'arrived', 'label': 'I have arrived! 📍'},
      {'key': 'late', 'label': 'Running late ⏳'},
      {'key': 'done', 'label': 'Job complete! ✅'},
    ];

    return Container(
      height: 36,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chip = chips[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: AppColors.surfaceAlt,
              side: BorderSide(color: AppColors.borderColor),
              label: Text(
                chip['label']!,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
              onPressed: () => _sendQuickAction(chip['key']!, chip['label']!, jobId),
            ),
          );
        },
      ),
    );
  }
}

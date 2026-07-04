import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_service.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _pushEnabled = true;
  bool _jobAlerts = true;
  bool _messageAlerts = true;
  bool _orderAlerts = true;
  bool _marketingAlerts = false;
  bool _loaded = false;

  static const _keyPush = 'notif_push_enabled';
  static const _keyJob = 'notif_job_alerts';
  static const _keyMsg = 'notif_message_alerts';
  static const _keyOrder = 'notif_order_alerts';
  static const _keyMarketing = 'notif_marketing_alerts';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool(_keyPush) ?? true;
      _jobAlerts = prefs.getBool(_keyJob) ?? true;
      _messageAlerts = prefs.getBool(_keyMsg) ?? true;
      _orderAlerts = prefs.getBool(_keyOrder) ?? true;
      _marketingAlerts = prefs.getBool(_keyMarketing) ?? false;
      _loaded = true;
    });
  }

  Future<void> _setPushEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPush, val);
    setState(() => _pushEnabled = val);

    if (val) {
      // Re-register FCM token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && mounted) {
        final currentUser = ref.read(supabaseServiceProvider).currentUser;
        if (currentUser != null) {
          try {
            await ref.read(supabaseServiceProvider).update(
              table: 'users',
              id: currentUser.id,
              data: {'push_token': token},
            );
          } catch (_) {}
        }
      }
    } else {
      // Delete FCM token to stop receiving pushes
      try {
        await FirebaseMessaging.instance.deleteToken();
        final currentUser = ref.read(supabaseServiceProvider).currentUser;
        if (currentUser != null) {
          await ref.read(supabaseServiceProvider).update(
            table: 'users',
            id: currentUser.id,
            data: {'push_token': null},
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _setPref(String key, bool val, void Function(bool) setter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
    setState(() => setter(val));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_loaded) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Notification Preferences'), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader('General'),
          _buildSettingCard([
            _buildToggleTile(
              icon: Icons.notifications_active_rounded,
              title: 'Push Notifications',
              subtitle: _pushEnabled
                  ? 'You will receive push notifications'
                  : 'All push notifications are paused',
              value: _pushEnabled,
              onChanged: _setPushEnabled,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Alert Types'),
          _buildSettingCard([
            _buildToggleTile(
              icon: Icons.work_outline,
              title: 'Job Alerts',
              subtitle: 'New jobs, application updates, and hires',
              value: _jobAlerts,
              onChanged: _pushEnabled
                  ? (val) => _setPref(_keyJob, val, (v) => _jobAlerts = v)
                  : null,
            ),
            _buildDivider(),
            _buildToggleTile(
              icon: Icons.chat_bubble_outline,
              title: 'Messages',
              subtitle: 'New messages from other users',
              value: _messageAlerts,
              onChanged: _pushEnabled
                  ? (val) => _setPref(_keyMsg, val, (v) => _messageAlerts = v)
                  : null,
            ),
            _buildDivider(),
            _buildToggleTile(
              icon: Icons.receipt_long_outlined,
              title: 'Orders & Payments',
              subtitle: 'Order status changes and payment confirmations',
              value: _orderAlerts,
              onChanged: _pushEnabled
                  ? (val) => _setPref(_keyOrder, val, (v) => _orderAlerts = v)
                  : null,
            ),
            _buildDivider(),
            _buildToggleTile(
              icon: Icons.campaign_outlined,
              title: 'Tips & Promotions',
              subtitle: 'Platform tips, promotions, and feature updates',
              value: _marketingAlerts,
              onChanged: _pushEnabled
                  ? (val) => _setPref(_keyMarketing, val, (v) => _marketingAlerts = v)
                  : null,
            ),
          ]),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Disabling push notifications stops all alerts. You will still see updates inside the app.',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodySmall?.color,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);
    return Divider(height: 1, indent: 56, color: theme.dividerColor);
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    final theme = Theme.of(context);
    final disabled = onChanged == null;
    return ListTile(
      enabled: !disabled,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.textTertiary.withOpacity(0.1)
              : theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: disabled ? AppColors.textTertiary : theme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: disabled ? AppColors.textTertiary : theme.textTheme.titleMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: disabled ? AppColors.textTertiary : theme.textTheme.bodySmall?.color,
          fontSize: 12,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: theme.primaryColor,
      ),
    );
  }
}

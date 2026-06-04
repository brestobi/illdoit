import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../providers/profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.titleTextStyle?.color,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.appBarTheme.iconTheme?.color ?? theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        data: (user) {
          if (user == null) return Center(child: Text('User not found', style: TextStyle(color: theme.textTheme.bodyLarge?.color)));

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              _buildSectionHeader('Appearance'),
              _buildSettingCard([
                _buildToggleTile(
                  icon: Icons.brightness_6,
                  title: 'Dark Mode',
                  subtitle: 'Enable dark theme across the app',
                  value: ref.watch(themeNotifierProvider) == ThemeMode.dark,
                  onChanged: (val) {
                    ref.read(themeNotifierProvider.notifier).toggleTheme();
                  },
                ),
              ]),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Privacy Controls'),
              _buildSettingCard([
                _buildToggleTile(
                  icon: Icons.public,
                  title: 'Public Profile',
                  subtitle: 'Allow others to view your profile and ratings',
                  value: user.isProfilePublic,
                  onChanged: (val) {
                    ref.read(profileProvider.notifier).updateProfile(isProfilePublic: val);
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor),
                _buildToggleTile(
                  icon: Icons.visibility,
                  title: 'Show Last Seen',
                  subtitle: 'Let others see when you were last active',
                  value: user.showLastSeen,
                  onChanged: (val) {
                    ref.read(profileProvider.notifier).updateProfile(showLastSeen: val);
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor),
                _buildToggleTile(
                  icon: Icons.contact_mail_outlined,
                  title: 'Show Contact Info',
                  subtitle: 'Display your phone number and email',
                  value: user.showContactInfo,
                  onChanged: (val) {
                    ref.read(profileProvider.notifier).updateProfile(showContactInfo: val);
                  },
                ),
              ]),
              
              const SizedBox(height: 24),
              _buildSectionHeader('Account'),
              _buildSettingCard([
                _buildActionTile(
                  icon: Icons.account_circle_outlined,
                  title: 'Change Account Role',
                  onTap: () {
                    // Navigate to a screen to change role
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor),
                _buildActionTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor),
                _buildActionTile(
                  icon: Icons.notifications_none,
                  title: 'Notification Preferences',
                  onTap: () {},
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor),
                _buildActionTile(
                  icon: Icons.language,
                  title: 'Language',
                  trailing: 'English (US)',
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionHeader('Support'),
              _buildSettingCard([
                _buildActionTile(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () => _launchUrl('https://illdoit.space/helpcenter'),
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor),
                _buildActionTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => _launchUrl('https://illdoit.space/terms'),
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor),
                _buildActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _launchUrl('https://illdoit.space/policy'),
                ),
              ]),

              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Text(
                      'By Hungry Developers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version $_version ($_buildNumber)',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e', style: TextStyle(color: theme.colorScheme.error))),
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

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.textTheme.titleMedium?.color),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (theme.textTheme.bodySmall?.color ?? Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.textTheme.bodySmall?.color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.textTheme.titleMedium?.color),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
            ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios, size: 14, color: theme.disabledColor),
        ],
      ),
    );
  }
}

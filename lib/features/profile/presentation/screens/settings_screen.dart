import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found', style: TextStyle(color: AppColors.textPrimary)));

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
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
                const Divider(height: 1, indent: 56, color: AppColors.borderColor),
                _buildToggleTile(
                  icon: Icons.visibility,
                  title: 'Show Last Seen',
                  subtitle: 'Let others see when you were last active',
                  value: user.showLastSeen,
                  onChanged: (val) {
                    ref.read(profileProvider.notifier).updateProfile(showLastSeen: val);
                  },
                ),
                const Divider(height: 1, indent: 56, color: AppColors.borderColor),
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
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56, color: AppColors.borderColor),
                _buildActionTile(
                  icon: Icons.notifications_none,
                  title: 'Notification Preferences',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56, color: AppColors.borderColor),
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
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56, color: AppColors.borderColor),
                _buildActionTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56, color: AppColors.borderColor),
                _buildActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'By Hungry Developers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version $_version ($_buildNumber)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
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
        error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textDisabled),
        ],
      ),
    );
  }
}

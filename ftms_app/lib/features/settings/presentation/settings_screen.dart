
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../features/auth/bloc/auth_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state is AuthAuthenticated ? state.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          if (user != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.categoryGradient(AppColors.primary),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          user.email,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.totalFiles} files • ${FileUtils.formatSize(user.storageUsedBytes)}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Telegram Status
          _SectionTitle('Telegram Storage'),
          _SettingTile(
            icon: Icons.telegram,
            iconColor: const Color(0xFF2AABEE),
            title: 'Telegram Account',
            subtitle: user?.isTelegramConnected == true
              ? 'Connected ✓'
              : 'Not connected',
            trailing: user?.isTelegramConnected == true
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: () => context.go('/telegram-connect'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Connect'),
                ),
            onTap: null,
          ),
          const SizedBox(height: 8),

          // App Settings
          _SectionTitle('App'),
          _SettingTile(
            icon: Icons.dark_mode_rounded,
            iconColor: AppColors.primary,
            title: 'Dark Mode',
            subtitle: 'Always on',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.notifications_rounded,
            iconColor: AppColors.warning,
            title: 'Notifications',
            subtitle: 'Upload & download alerts',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.storage_rounded,
            iconColor: AppColors.info,
            title: 'Cache',
            subtitle: 'Clear thumbnail cache',
            onTap: () {},
          ),
          const SizedBox(height: 8),

          // About
          _SectionTitle('About'),
          _SettingTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.textSecondary,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          _SettingTile(
            icon: Icons.code_rounded,
            iconColor: AppColors.codeColor,
            title: 'Open Source',
            subtitle: 'GitHub repository',
            onTap: () {},
          ),
          const SizedBox(height: 8),

          // Logout
          _SectionTitle('Account'),
          _SettingTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Sign Out',
            subtitle: 'Log out of FTMS',
            titleColor: AppColors.error,
            onTap: () => _confirmLogout(context),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
              context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: titleColor,
          ),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.bodyMedium),
        trailing: trailing ?? (onTap != null
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            )
          : null),
      ),
    );
  }
}

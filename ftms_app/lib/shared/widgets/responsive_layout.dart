
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/platform_utils.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isDesktop && desktop != null) {
      return desktop!;
    }
    return mobile;
  }
}

// Windows sidebar navigation
class DesktopShell extends StatelessWidget {
  final Widget child;
  const DesktopShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home'))     return 0;
    if (location.startsWith('/files'))    return 1;
    if (location.startsWith('/photos'))   return 2;
    if (location.startsWith('/videos'))   return 3;
    if (location.startsWith('/audio'))    return 4;
    if (location.startsWith('/documents'))return 5;
    if (location.startsWith('/search'))   return 6;
    if (location.startsWith('/settings')) return 7;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _Sidebar(currentIndex: _currentIndex(context)),
          // Vertical divider
          Container(width: 1, color: AppColors.surfaceLight),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  const _Sidebar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.bgCard,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('FTMS', style: AppTextStyles.headlineMedium),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Nav items
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => context.go('/home'),
          ),
          _NavItem(
            icon: Icons.folder_rounded,
            label: 'Files',
            selected: currentIndex == 1,
            onTap: () => context.go('/files'),
          ),
          const SizedBox(height: 8),
          _SidebarSection('Media'),
          _NavItem(
            icon: Icons.image_rounded,
            label: 'Photos',
            selected: currentIndex == 2,
            onTap: () => context.go('/photos'),
          ),
          _NavItem(
            icon: Icons.videocam_rounded,
            label: 'Videos',
            selected: currentIndex == 3,
            onTap: () => context.go('/videos'),
          ),
          _NavItem(
            icon: Icons.music_note_rounded,
            label: 'Music',
            selected: currentIndex == 4,
            onTap: () => context.go('/audio'),
          ),
          _NavItem(
            icon: Icons.description_rounded,
            label: 'Documents',
            selected: currentIndex == 5,
            onTap: () => context.go('/documents'),
          ),
          const SizedBox(height: 8),
          _SidebarSection('Discover'),
          _NavItem(
            icon: Icons.search_rounded,
            label: 'Search',
            selected: currentIndex == 6,
            onTap: () => context.go('/search'),
          ),

          const Spacer(),
          const Divider(),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            selected: currentIndex == 7,
            onTap: () => context.go('/settings'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          ),
          title: Text(
            label,
            style: AppTextStyles.titleMedium.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  const _SidebarSection(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          letterSpacing: 1.5,
          color: AppColors.textHint,
          fontSize: 10,
        ),
      ),
    );
  }
}

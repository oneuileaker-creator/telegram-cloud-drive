
import 'package:flutter/material.dart';
import '../../core/utils/platform_utils.dart';
import 'responsive_layout.dart';
import 'ftms_bottom_nav.dart';
import '../../shared/widgets/offline_banner.dart';

class FTMSShell extends StatelessWidget {
  final Widget child;
  const FTMSShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return OfflineBanner(
      child: ResponsiveLayout(
        mobile: _MobileShell(child: child),
        desktop: DesktopShell(child: child),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const FTMSBottomNav(),
    );
  }
}

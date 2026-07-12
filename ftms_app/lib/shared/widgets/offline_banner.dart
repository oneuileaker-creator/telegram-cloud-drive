import 'package:flutter/material.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConnectivityService.instance,
      builder: (ctx, _) {
        final offline = !ConnectivityService.instance.isOnline;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: offline ? 36 : 0,
              color: AppColors.warning,
              child: offline
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.black,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Offline - Showing cached data',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  )
                : null,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

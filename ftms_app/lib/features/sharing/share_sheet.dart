import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/files/models/file_model.dart';
import 'sharing_service.dart';

class ShareSheet extends StatefulWidget {
  final FileModel file;
  const ShareSheet({super.key, required this.file});

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet>
    with SingleTickerProviderStateMixin {

  late TabController _tabs;
  final _service = SharingService();

  ShareLink? _link;
  bool _creating = false;

  // Options
  int? _expiryHours;
  final _passwordCtrl = TextEditingController();
  int? _maxDownloads;
  bool _showQr = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createLink() async {
    setState(() => _creating = true);
    try {
      final link = await _service.createShareLink(
        fileId:         widget.file.id,
        expiresInHours: _expiryHours,
        password:       _passwordCtrl.text.isEmpty
                          ? null
                          : _passwordCtrl.text,
        maxDownloads:   _maxDownloads,
      );
      if (mounted) setState(() { _link = link; _creating = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyLink() {
    if (_link == null) return;
    Clipboard.setData(ClipboardData(text: _link!.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareLink() {
    if (_link == null) return;
    Share.share(
      'Download "${widget.file.name}" from FTMS:\n${_link!.url}',
      subject: widget.file.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.share_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Share "${widget.file.name}"',
                    style: AppTextStyles.headlineMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Create Link'),
              Tab(text: 'Quick Share'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // ── Create Link Tab ────────────────────────
                ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_link == null) ...[
                      // Expiry
                      Text('Link Expiry', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ChipOption(
                            label: 'Never',
                            selected: _expiryHours == null,
                            onTap: () => setState(() => _expiryHours = null),
                          ),
                          _ChipOption(
                            label: '1 hour',
                            selected: _expiryHours == 1,
                            onTap: () => setState(() => _expiryHours = 1),
                          ),
                          _ChipOption(
                            label: '24 hours',
                            selected: _expiryHours == 24,
                            onTap: () => setState(() => _expiryHours = 24),
                          ),
                          _ChipOption(
                            label: '7 days',
                            selected: _expiryHours == 168,
                            onTap: () => setState(() => _expiryHours = 168),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Password
                      Text('Password (optional)', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Leave empty for no password',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),

                      // Max downloads
                      Text('Max Downloads', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ChipOption(
                            label: 'Unlimited',
                            selected: _maxDownloads == null,
                            onTap: () => setState(() => _maxDownloads = null),
                          ),
                          _ChipOption(
                            label: '1',
                            selected: _maxDownloads == 1,
                            onTap: () => setState(() => _maxDownloads = 1),
                          ),
                          _ChipOption(
                            label: '5',
                            selected: _maxDownloads == 5,
                            onTap: () => setState(() => _maxDownloads = 5),
                          ),
                          _ChipOption(
                            label: '10',
                            selected: _maxDownloads == 10,
                            onTap: () => setState(() => _maxDownloads = 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _creating ? null : _createLink,
                          icon: _creating
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.link_rounded),
                          label: Text(_creating ? 'Creating...' : 'Create Link'),
                        ),
                      ),
                    ] else ...[
                      // Link created
                      _LinkCreatedCard(
                        link: _link!,
                        onCopy: _copyLink,
                        onShare: _shareLink,
                        onShowQr: () => setState(() => _showQr = !_showQr),
                        showQr: _showQr,
                      ),
                    ],
                  ],
                ),

                // ── Quick Share Tab ────────────────────────
                ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _QuickShareButton(
                      icon: Icons.copy_rounded,
                      label: 'Copy Download Link',
                      color: AppColors.primary,
                      onTap: () async {
                        await _createLink();
                        _copyLink();
                      },
                    ),
                    const SizedBox(height: 12),
                    _QuickShareButton(
                      icon: Icons.share_rounded,
                      label: 'Share via Apps',
                      color: AppColors.info,
                      onTap: () async {
                        await _createLink();
                        _shareLink();
                      },
                    ),
                    const SizedBox(height: 12),
                    _QuickShareButton(
                      icon: Icons.qr_code_rounded,
                      label: 'Show QR Code',
                      color: AppColors.codeColor,
                      onTap: () async {
                        await _createLink();
                        setState(() => _showQr = true);
                        _tabs.animateTo(0);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkCreatedCard extends StatelessWidget {
  final ShareLink link;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onShowQr;
  final bool showQr;

  const _LinkCreatedCard({
    required this.link,
    required this.onCopy,
    required this.onShare,
    required this.onShowQr,
    required this.showQr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text('Link Created!', style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                link.url,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (link.expiresAt != null)
                    Text(
                      'Expires: ${link.expiresAt!.toLocal().toString().split('.').first}',
                      style: AppTextStyles.caption,
                    ),
                  const Spacer(),
                  Text(
                    '${link.downloadCount} downloads',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                ),
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.codeColor),
            ),
            onPressed: onShowQr,
            icon: Icon(
              showQr ? Icons.qr_code_2_rounded : Icons.qr_code_rounded,
              color: AppColors.codeColor,
              size: 18,
            ),
            label: Text(
              showQr ? 'Hide QR' : 'Show QR Code',
              style: const TextStyle(color: AppColors.codeColor),
            ),
          ),
        ),
        if (showQr) ...[
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: link.url,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan to download file',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _ChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
            ? AppColors.primary.withOpacity(0.2)
            : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _QuickShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(label, style: AppTextStyles.titleMedium),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

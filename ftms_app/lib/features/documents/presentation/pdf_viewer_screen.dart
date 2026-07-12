
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/files/models/file_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/upload/secure_uploader.dart';

class PdfViewerScreen extends StatefulWidget {
  final FileModel file;
  const PdfViewerScreen({super.key, required this.file});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _loading = true;
  int _pages = 0;
  int _currentPage = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final url =
        '${ApiConstants.baseUrl}${ApiConstants.filesDownload}/${widget.file.id}';

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${widget.file.id}.pdf';
      final file = File(path);

      if (!await file.exists()) {
        final isEncrypted = widget.file.name.startsWith('__enc__');
        if (isEncrypted) {
          final uploader = SecureUploader();
          final bytes = await uploader.downloadFile(
            fileId: widget.file.id,
            fileName: widget.file.name,
            isEncrypted: true,
          );
          await file.writeAsBytes(bytes);
        } else {
          await DioClient.instance.dio.download(
            url,
            path,
            onReceiveProgress: (received, total) {},
          );
        }
      }

      if (mounted) {
        setState(() {
          _localPath = path;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          if (_pages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                '$_currentPage / $_pages',
                style: AppTextStyles.bodyMedium,
              ),
            ),
        ],
      ),
      body: _loading
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Loading PDF...'),
              ],
            ),
          )
        : _error != null
          ? Center(child: Text('Error: $_error'))
          : PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: true,
              onRender: (count) => setState(() => _pages = count ?? 0),
              onPageChanged: (page, _) =>
                setState(() => _currentPage = (page ?? 0) + 1),
              onError: (e) => setState(() => _error = e.toString()),
            ),
    );
  }
}

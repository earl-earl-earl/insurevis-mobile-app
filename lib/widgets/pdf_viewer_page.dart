import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final String? title;

  const PdfViewerPage({super.key, required this.filePath, this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  int _pages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'PDF')),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(_errorMessage!),
              ),
            )
          else
            PDFView(
              filePath: widget.filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) {
                setState(() {
                  _pages = pages ?? 0;
                  _isReady = true;
                });
              },
              onError: (error) {
                setState(() => _errorMessage = error.toString());
              },
              onPageError: (page, error) {
                setState(() => _errorMessage = 'Page $page: $error');
              },
              onViewCreated: (controller) {},
              onPageChanged: (page, total) {
                setState(() => _currentPage = page ?? 0);
              },
            ),
          if (!_isReady && _errorMessage == null)
            const Center(child: CircularProgressIndicator()),
          if (_isReady && _errorMessage == null)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_currentPage + 1}/$_pages',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

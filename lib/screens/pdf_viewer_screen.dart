import 'dart:async';
import 'dart:io';

import 'package:dress_right/storage/hive_boxes.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.path});

  final String path;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfViewerController _pdfController;
  late final bool _fileExists;
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();
  int _matchCount = 0;
  PdfTextSearchResult? _searchResult;
  int? _initialPage;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _fileExists = File(widget.path).existsSync();
    final prefs = HiveBoxes.prefsSnapshot;
    if (prefs.dafiLocalPath == widget.path && prefs.dafiLastPage != null) {
      _initialPage = prefs.dafiLastPage;
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _searchCtrl.dispose();
    _searchResult?.removeListener(_onSearchResult);
    _searchResult?.clear();
    super.dispose();
  }

  void _onSearchResult() {
    if (!mounted) return;
    if (_searchResult?.hasResult ?? false) {
      setState(() {
        _matchCount = _searchResult!.totalInstanceCount;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchCtrl.clear();
        _searchResult?.clear();
        _pdfController.clearSelection();
        _matchCount = 0;
      }
    });
  }

  void _onSearchChanged(String text) {
    if (text.isEmpty) {
      _searchResult?.clear();
      _pdfController.clearSelection();
      setState(() => _matchCount = 0);
    } else {
      Future.delayed(const Duration(milliseconds: 280), () {
        if (_searchCtrl.text == text) {
          _searchResult?.removeListener(_onSearchResult);
          _searchResult = _pdfController.searchText(text);
          _searchResult?.addListener(_onSearchResult);
        }
      });
    }
  }

  void _handlePageChanged(PdfPageChangedDetails details) {
    final snapshot = HiveBoxes.prefsSnapshot;
    if (snapshot.dafiLocalPath == widget.path && snapshot.dafiLastPage != details.newPageNumber) {
      unawaited(HiveBoxes.savePrefs(snapshot.copyWith(dafiLastPage: details.newPageNumber)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_fileExists) {
      return Scaffold(
        appBar: AppBar(title: const Text('AFI PDF Viewer')),
        body: const Center(
          child: Text('PDF not found. Re-import from Settings.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                onChanged: _onSearchChanged,
              )
            : const Text('AFI 36-2903'),
        actions: [
          if (_isSearching && _matchCount > 0) ...[
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () => _searchResult?.previousInstance(),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => _searchResult?.nextInstance(),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('$_matchCount'),
              ),
            ),
          ],
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: SfPdfViewer.file(
        File(widget.path),
        controller: _pdfController,
        onDocumentLoaded: (details) {
          if (_initialPage != null && _initialPage! > 0 && _initialPage! <= details.document.pages.count) {
            _pdfController.jumpToPage(_initialPage!);
          }
        },
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}

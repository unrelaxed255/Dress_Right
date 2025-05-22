import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String path; // local file path to your PDF

  const PdfViewerScreen({super.key, required this.path});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfController;
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();
  int _matchCount = 0;
  PdfTextSearchResult? _searchResult;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _searchCtrl.dispose();
    _searchResult?.clear();
    super.dispose();
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
      // Add a slight delay to prevent searching on every keystroke
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_searchCtrl.text == text) {
          // Search for text and handle the result
          _searchResult = _pdfController.searchText(text);
          
          // Listen for search completion manually
          _searchResult?.addListener(() {
            if (_searchResult!.hasResult) {
              setState(() {
                _matchCount = _searchResult!.totalInstanceCount;
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            : const Text('AFI PDF Viewer'),
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
      ),
    );
  }
}
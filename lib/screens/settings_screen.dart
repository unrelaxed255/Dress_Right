import 'dart:io';
import 'dart:ui';

import 'package:dress_right/models/prefs.dart';
import 'package:dress_right/providers/theme_provider.dart';
import 'package:dress_right/screens/pdf_viewer_screen.dart';
import 'package:dress_right/storage/hive_boxes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:dress_right/utils/color_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _rankNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  String _themeKey = AppThemeMode.dark;
  bool _isImporting = false;
  String? _dafiPath;
  int? _lastPdfPage;

  @override
  void initState() {
    super.initState();
    final prefs = HiveBoxes.prefsSnapshot;
    _themeKey = prefs.theme;
    _dafiPath = prefs.dafiLocalPath;
    _lastPdfPage = prefs.dafiLastPage;
    _rankNameCtrl = TextEditingController(text: prefs.emailSignature.rankName);
    _phoneCtrl = TextEditingController(text: prefs.emailSignature.phone);
    _emailCtrl = TextEditingController(text: prefs.emailSignature.email);
  }

  @override
  void dispose() {
    _rankNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onThemeSelected(String value) async {
    await context.read<ThemeProvider>().setTheme(value);
    setState(() => _themeKey = value);
  }

  Future<void> _saveSignature() async {
    final snapshot = HiveBoxes.prefsSnapshot;
    final updated = snapshot.copyWith(
      emailSignature: snapshot.emailSignature.copyWith(
        rankName: _rankNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      ),
    );
    await HiveBoxes.savePrefs(updated);
    _showToast('Email signature saved');
  }

  Future<void> _importDafiPdf() async {
    try {
      setState(() => _isImporting = true);
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: false,
      );
      if (picked == null || picked.files.isEmpty) {
        return;
      }
      final filePath = picked.files.first.path;
      if (filePath == null) {
        _showToast('Unable to read selected file');
        return;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = 'dafi36-2903.pdf';
      final targetPath = p.join(docsDir.path, fileName);
      final sourceFile = File(filePath);
      await sourceFile.copy(targetPath);

      final snapshot = HiveBoxes.prefsSnapshot;
      final updated = snapshot.copyWith(
        dafiLocalPath: targetPath,
        dafiLastPage: 1,
      );
      await HiveBoxes.savePrefs(updated);

      setState(() {
        _dafiPath = targetPath;
        _lastPdfPage = 1;
      });
      _showToast('AFI 36-2903 imported for offline use');
    } catch (e) {
      _showToast('Import failed: ');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _openPdfViewer() {
    final path = _dafiPath;
    if (path == null) {
      _showToast('Import the PDF first');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(path: path),
      ),
    ).then((_) {
      final latest = HiveBoxes.prefsSnapshot;
      setState(() => _lastPdfPage = latest.dafiLastPage);
    });
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withFraction(0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallpaper.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC050A16),
                  Color(0xCC0B1D38),
                  Color(0xCC050A16),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Appearance', textTheme),
                  const SizedBox(height: 12),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: [
                            _ThemeChip(
                              label: 'Dark',
                              value: AppThemeMode.dark,
                              selected: _themeKey == AppThemeMode.dark,
                              onSelected: _onThemeSelected,
                            ),
                            _ThemeChip(
                              label: 'Light',
                              value: AppThemeMode.light,
                              selected: _themeKey == AppThemeMode.light,
                              onSelected: _onThemeSelected,
                            ),
                            _ThemeChip(
                              label: 'System',
                              value: AppThemeMode.system,
                              selected: _themeKey == AppThemeMode.system,
                              onSelected: _onThemeSelected,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Email Signature', textTheme),
                  const SizedBox(height: 12),
                  _GlassCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _rankNameCtrl,
                          label: 'Rank / Name',
                          hint: 'e.g. TSgt Avery Moody',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneCtrl,
                          label: 'Phone',
                          hint: '(555) 555-5555',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'avery.moody@us.af.mil',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildPrimaryButton(
                            label: 'Save Signature',
                            icon: Icons.save_rounded,
                            onPressed: _saveSignature,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('AFI 36-2903', textTheme),
                  const SizedBox(height: 12),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import the official instruction for offline reference. The file is stored in app documents and remains available without connectivity.',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPrimaryButton(
                                label: _dafiPath == null ? 'Import PDF' : 'Replace PDF',
                                icon: Icons.file_download_rounded,
                                onPressed: _isImporting ? null : _importDafiPdf,
                                isBusy: _isImporting,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSecondaryButton(
                                label: 'Open PDF',
                                icon: Icons.picture_as_pdf_outlined,
                                onPressed: _dafiPath == null ? null : _openPdfViewer,
                              ),
                            ),
                          ],
                        ),
                        if (_dafiPath != null) ...[
                          const SizedBox(height: 16),
                          _buildMetaText('Location: $_dafiPath'),
                          if (_lastPdfPage != null)
                            _buildMetaText('Last page viewed: $_lastPdfPage'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.sourceSans3(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withFraction(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withFraction(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withFraction(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withFraction(0.45)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isBusy = false,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B3A66),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
        onPressed: isBusy ? null : onPressed,
        icon: isBusy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withFraction(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }

  Widget _buildSectionHeader(String title, TextTheme textTheme) {
    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildMetaText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: GoogleFonts.sourceSans3(
          fontSize: 13,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withFraction(0.08),
                Colors.white.withFraction(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withFraction(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withFraction(0.35),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      backgroundColor: Colors.white.withFraction(0.08),
      selectedColor: const Color(0xFF1B3A66).withFraction(0.85),
      labelStyle: TextStyle(
        color: Colors.white.withFraction(selected ? 0.95 : 0.7),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: Colors.white.withFraction(selected ? 0.45 : 0.25)),
      onSelected: (_) => onSelected(value),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}





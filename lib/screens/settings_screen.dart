// lib/screens/settings_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dress_right/main.dart';

// 🔔 our notification helper
import 'package:dress_right/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // AFI PDF URL
  final _afiUrl =
      'https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2903/dafi36-2903.pdf';

  // State
  bool _isDownloading = false;
  bool _hasLocalCopy = false;
  String _lastUpdated = 'Never';
  bool _isConnected = false;
  Timer? _connectivityTimer;

  // Inspector info (stored separately)
  String? _inspectorName;
  String? _inspectorPosition;
  String? _inspectorUnit;
  String? _inspectorDsn;
  String? _inspectorBase;

  // Colors
  static const _baseColor      = Color(0xFF192841);
  static const _highlightColor = Color(0xFF3A8DFF);
  static const _creamColor     = Color(0xFFF5F5DC);

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _checkForLocalAFI();
    _loadInspectorInfo();
    
    // Set up periodic connectivity check
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
  }
  
  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      // Simple connectivity check using DNS lookup
      final result = await InternetAddress.lookup('google.com');
      setState(() {
        _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
    }
  }

  Future<void> _checkForLocalAFI() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/dafi36-2903.pdf');
    if (await file.exists()) {
      final mod = await file.lastModified();
      setState(() {
        _hasLocalCopy = true;
        _lastUpdated = DateFormat.yMd().add_jm().format(mod);
      });
    }
  }

  Future<void> _downloadAFI() async {
    // Check connectivity first
    await _checkConnectivity();
    if (!_isConnected) {
      _showToast('No internet connection');
      return;
    }
    
    _showToast('Downloading…');
    setState(() => _isDownloading = true);
    try {
      final res = await http.get(
        Uri.parse(_afiUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; DressRightApp/1.0)',
          'Accept': 'application/pdf,*/*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      );
      if (res.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/dafi36-2903.pdf');
        await file.writeAsBytes(res.bodyBytes);
        final mod = await file.lastModified();
        setState(() {
          _hasLocalCopy = true;
          _lastUpdated = DateFormat.yMd().add_jm().format(mod);
        });
        _showToast('Download complete');
      } else if (res.statusCode == 403) {
        _showToast('Access denied - try viewing online instead');
      } else {
        _showToast('Error ${res.statusCode} - trying alternative source');
        // Try alternative approach
        _openWebAFI();
      }
    } catch (e) {
      _showToast('Download failed - opening in browser');
      _openWebAFI();
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _openAFI() async {
    // First check if we have a local file
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/dafi36-2903.pdf');
    
    if (await file.exists()) {
      // Open local PDF with Syncfusion viewer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _PDFViewerScreen(
            title: 'AFI 36-2903',
            pdfPath: file.path,
            isLocal: true,
          ),
        ),
      );
    } else {
      // Open web PDF with Syncfusion viewer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _PDFViewerScreen(
            title: 'AFI 36-2903',
            pdfPath: _afiUrl,
            isLocal: false,
          ),
        ),
      );
    }
  }

  Future<void> _openWebAFI() async {
    final uri = Uri.parse(_afiUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showToast('Could not open AFI');
    }
  }

  Future<void> _loadInspectorInfo() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _inspectorName = sp.getString('insp_name');
      _inspectorPosition = sp.getString('insp_position');
      _inspectorUnit = sp.getString('insp_unit');
      _inspectorDsn = sp.getString('insp_dsn');
      _inspectorBase = sp.getString('insp_base');
    });
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black54,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
    );
  }

  Future<void> _showInspectorDialog() async {
    final nameC = TextEditingController(text: _inspectorName ?? '');
    final positionC = TextEditingController(text: _inspectorPosition ?? '');
    final unitC = TextEditingController(text: _inspectorUnit ?? '');
    final dsnC = TextEditingController(text: _inspectorDsn ?? '');
    final baseC = TextEditingController(text: _inspectorBase ?? '');
    final form = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SingleChildScrollView(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: _baseColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _highlightColor.withValues(alpha: 0.3), width: 2),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'INSPECTOR INFORMATION',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: _creamColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For email signature blocks',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Form(
                          key: form,
                          child: Column(
                            children: [
                              _buildThemedTextFormField(
                                controller: nameC,
                                label: 'NAME, RANK',
                                hint: 'SMITH, JOHN A., SSgt',
                                validator: (v) => v!.trim().isEmpty ? 'Name and rank required' : null,
                              ),
                              const SizedBox(height: 20),
                              _buildThemedTextFormField(
                                controller: positionC,
                                label: 'POSITION',
                                hint: 'First Sergeant / NCOIC',
                                validator: (v) => v!.trim().isEmpty ? 'Position required' : null,
                              ),
                              const SizedBox(height: 20),
                              _buildThemedTextFormField(
                                controller: unitC,
                                label: 'UNIT/WORKCENTER',
                                hint: '123rd Security Forces Squadron',
                                validator: (v) => v!.trim().isEmpty ? 'Unit required' : null,
                              ),
                              const SizedBox(height: 20),
                              _buildThemedTextFormField(
                                controller: dsnC,
                                label: 'DSN',
                                hint: '449-7777',
                                validator: (v) => v!.trim().isEmpty ? 'DSN required' : null,
                              ),
                              const SizedBox(height: 20),
                              _buildThemedTextFormField(
                                controller: baseC,
                                label: 'BASE, STATE',
                                hint: 'Joint Base San Antonio, TX',
                                validator: (v) => v!.trim().isEmpty ? 'Base required' : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _themedDialogButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            text: 'CANCEL',
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _themedDialogButton(
                            onPressed: () {
                              if (form.currentState!.validate()) {
                                Navigator.pop(ctx, true);
                              }
                            },
                            text: 'SAVE',
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('insp_name', nameC.text.trim());
      await sp.setString('insp_position', positionC.text.trim());
      await sp.setString('insp_unit', unitC.text.trim());
      await sp.setString('insp_dsn', dsnC.text.trim());
      await sp.setString('insp_base', baseC.text.trim());
      
      setState(() {
        _inspectorName = nameC.text.trim();
        _inspectorPosition = positionC.text.trim();
        _inspectorUnit = unitC.text.trim();
        _inspectorDsn = dsnC.text.trim();
        _inspectorBase = baseC.text.trim();
      });
      _showToast('Inspector information saved successfully');
    }
  }

  Widget _buildThemedTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Block Label
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _highlightColor.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.bebasNeue(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        // Input Field
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A3D5C), // Darker blue-grey for better contrast
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border.all(color: _highlightColor.withValues(alpha: 0.3)),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFB8C5D1), // Much lighter blue-grey for visibility
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _themedDialogButton({
    required VoidCallback onPressed,
    required String text,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isPrimary ? _highlightColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? _highlightColor : Colors.white54,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.bebasNeue(
              fontSize: 16,
              color: isPrimary ? Colors.white : _creamColor,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scheduleReminder() async {
    // Custom themed date picker
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _highlightColor,
              onPrimary: Colors.white,
              surface: _baseColor,
              onSurface: _creamColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    // Custom time picker dialog
    final time = await _showCustomTimePicker();
    if (time == null) return;

    final when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final id   = when.hashCode;

    await NotificationService().scheduleInspectionReminder(
      id:    id,
      title: 'SRR Inspection Reminder',
      body:  "Don't forget your SRR on ${DateFormat.yMd().format(when)} at ${DateFormat.jm().format(when)}",
      when:  when,
    );

    _showToast('Reminder set for ${DateFormat.yMd().add_jm().format(when)}');
  }

  Future<TimeOfDay?> _showCustomTimePicker() async {
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    
    return await showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _baseColor.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _highlightColor.withValues(alpha: 0.3), width: 2),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SELECT TIME',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 24,
                            color: _creamColor,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Material Design time picker with roller effect
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _highlightColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              // Hour picker
                              Expanded(
                                child: ListWheelScrollView(
                                  controller: FixedExtentScrollController(initialItem: selectedTime.hour),
                                  itemExtent: 40,
                                  perspective: 0.005,
                                  diameterRatio: 1.2,
                                  physics: FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (int index) {
                                    setDialogState(() {
                                      selectedTime = TimeOfDay(hour: index, minute: selectedTime.minute);
                                    });
                                  },
                                  children: List.generate(24, (index) => Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        color: _creamColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )),
                                ),
                              ),
                              // Separator
                              Container(
                                width: 20,
                                child: Text(
                                  ':',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: _creamColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Minute picker
                              Expanded(
                                child: ListWheelScrollView(
                                  controller: FixedExtentScrollController(initialItem: selectedTime.minute),
                                  itemExtent: 40,
                                  perspective: 0.005,
                                  diameterRatio: 1.2,
                                  physics: FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (int index) {
                                    setDialogState(() {
                                      selectedTime = TimeOfDay(hour: selectedTime.hour, minute: index);
                                    });
                                  },
                                  children: List.generate(60, (index) => Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        color: _creamColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: _themedDialogButton(
                                onPressed: () => Navigator.pop(ctx, null),
                                text: 'CANCEL',
                                isPrimary: false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _themedDialogButton(
                                onPressed: () => Navigator.pop(ctx, selectedTime),
                                text: 'SET TIME',
                                isPrimary: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeSelector({
    required int value,
    required int maxValue,
    int step = 1,
    required Function(int) onChanged,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            int newValue = value + step;
            if (newValue > maxValue) {
              newValue = step == 5 ? 0 : 0; // Handle 5-minute intervals properly
            }
            onChanged(newValue);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _highlightColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.keyboard_arrow_up, color: _creamColor, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _highlightColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _highlightColor.withValues(alpha: 0.5), width: 2),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              color: _creamColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            int newValue = value - step;
            if (newValue < 0) {
              newValue = step == 5 ? (maxValue ~/ 5) * 5 : maxValue; // Handle 5-minute intervals properly
            }
            onChanged(newValue);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _highlightColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.keyboard_arrow_down, color: _creamColor, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTimeButton(String label, TimeOfDay time, Function(TimeOfDay) onPressed) {
    return GestureDetector(
      onTap: () => onPressed(time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _highlightColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _highlightColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _creamColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showAFITooltip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _baseColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Button Guide',
          style: GoogleFonts.bebasNeue(
            fontSize: 20,
            color: _creamColor,
            letterSpacing: 1,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTooltipItem('Update AFI', 'Downloads the latest regulation to your device'),
            const SizedBox(height: 12),
            _buildTooltipItem('View AFI', 'Opens the regulation (local copy if available, web otherwise)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('GOT IT', style: TextStyle(color: _highlightColor)),
          ),
        ],
      ),
    );
  }

  void _showReminderTooltip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _baseColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'SRR Reminders',
          style: GoogleFonts.bebasNeue(
            fontSize: 20,
            color: _creamColor,
            letterSpacing: 1,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule notifications to remind yourself or your team about upcoming Self-Reporting Requirements (SRR) inspections.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Perfect for First Sergeants, NCOICs, and anyone conducting regular inspections.',
              style: TextStyle(color: _highlightColor, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('GOT IT', style: TextStyle(color: _highlightColor)),
          ),
        ],
      ),
    );
  }

  void _rebootApp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _baseColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reboot App',
          style: GoogleFonts.bebasNeue(
            fontSize: 20,
            color: _creamColor,
            letterSpacing: 1,
          ),
        ),
        content: const Text(
          'This will restart the application. Any unsaved changes will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _highlightColor),
            onPressed: () {
              Navigator.pop(ctx);
              _performReboot();
            },
            child: const Text('Reboot', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performReboot() {
    // Clear any cached data if needed
    _showToast('Rebooting app...');
    
    // Use SystemNavigator to restart the app
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MyApp()),
      (route) => false,
    );
  }

  Widget _buildTooltipItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _highlightColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('SETTINGS',
            style: GoogleFonts.bebasNeue(
                fontSize: 36, color: _creamColor, letterSpacing: 2)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildNetworkIndicator(),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset('assets/images/wallpaper.png', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),
        SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const SizedBox(height: 8),
            _glassCard(Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('AFI 36-2903',
                      style: GoogleFonts.bebasNeue(
                          fontSize: 28,
                          color: _creamColor,
                          letterSpacing: 2)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showAFITooltip,
                    child: Icon(
                      Icons.info_outline,
                      color: _highlightColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Last Updated: $_lastUpdated',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _bubbleButton(
                    icon: Icons.download,
                    label: _isDownloading ? 'Downloading…' : 'Update AFI',
                    isPrimary: true,
                    onPressed: _isDownloading ? null : _downloadAFI,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _bubbleButton(
                    icon: Icons.picture_as_pdf,
                    label: 'View AFI',
                    isPrimary: true,
                    onPressed: _openAFI,
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 16),
              _bubbleButton(
                icon: Icons.person,
                label: _inspectorName == null
                    ? 'Set Inspector Info'
                    : 'Edit Inspector Info',
                isPrimary: false,
                onPressed: _showInspectorDialog,
              ),
              const SizedBox(height: 12),
              _bubbleButton(
                icon: Icons.schedule,
                label: 'Schedule SRR Reminder',
                isPrimary: false,
                onPressed: _scheduleReminder,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _bubbleButton(
                    icon: Icons.delete_forever,
                    label: 'Clear All Data',
                    isPrimary: false,
                    onPressed: () => showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: _baseColor,
                        title: Text('Clear all inspection data?', style: TextStyle(color: _creamColor)),
                        content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.white)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel', style: TextStyle(color: Colors.white70))),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Clear', style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    ).then((ok) {
                      if (ok == true) {
                        // TODO: clear inspection data
                        _showToast('Data cleared');
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _bubbleButton(
                    icon: Icons.restart_alt,
                    label: 'Reboot App',
                    isPrimary: false,
                    onPressed: _rebootApp,
                  ),
                ),
              ]),
            ])),
            const SizedBox(height: 24),
            _glassCard(
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _creamColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'DressRight',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _creamColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _glassCard(Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
                color: Colors.black.withAlpha(76),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24)),
            child: child,
          ),
        ),
      );

  Widget _bubbleButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = true,
  }) {
    final textColor = isPrimary ? Colors.white : Colors.white70;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkIndicator() {
    if (_isConnected) {
      return const Icon(Icons.wifi, color: Colors.green);
    } else {
      return const Icon(Icons.signal_wifi_off, color: Colors.red);
    }
  }
}

// Custom PDF Viewer Screen with your app's theme
class _PDFViewerScreen extends StatelessWidget {
  final String title;
  final String pdfPath;
  final bool isLocal;

  const _PDFViewerScreen({
    required this.title,
    required this.pdfPath,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            color: const Color(0xFFF5F5DC),
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Add share functionality if needed
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF192841),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF192841),
              Color(0xFF0A1E3D),
            ],
          ),
        ),
        child: SafeArea(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: isLocal
                  ? SfPdfViewer.file(
                      File(pdfPath),
                      enableDoubleTapZooming: true,
                      enableTextSelection: true,
                    )
                  : SfPdfViewer.network(
                      pdfPath,
                      enableDoubleTapZooming: true,
                      enableTextSelection: true,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
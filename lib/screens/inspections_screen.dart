import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:dress_right/models/inspection.dart';
import 'package:dress_right/models/inspection_item.dart';
import 'package:dress_right/providers/inspection_provider.dart';
import 'package:dress_right/storage/hive_boxes.dart';
import 'package:dress_right/utils/checklist_loader.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dress_right/utils/color_utils.dart';

class InspectionsScreen extends StatefulWidget {
  const InspectionsScreen({super.key});

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final inspections = context.watch<InspectionProvider>().inspections;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Inspections'),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isCreating ? null : _startInspection,
                      icon: _isCreating
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_task_rounded),
                      label: Text(_isCreating ? 'Preparing...' : 'New Inspection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3A66).withFraction(0.85),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: inspections.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 32),
                            itemCount: inspections.length,
                            itemBuilder: (context, index) {
                              final inspection = inspections[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _InspectionTile(
                                  inspection: inspection,
                                  onTap: () => _openDetail(inspection.inspectionId),
                                ),
                              );
                            },
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

  Future<void> _startInspection() async {
    setState(() => _isCreating = true);
    try {
      final provider = context.read<InspectionProvider>();
      final checklists = await provider.loadChecklists();
      if (!mounted) return;
      final selection = await showModalBottomSheet<ChecklistDefinition>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _ChecklistPicker(definitions: checklists),
      );
      if (!mounted) return;
      if (selection == null) {
        return;
      }
      final inspection = await provider.createInspection(selection.name, selection);
      if (!mounted) return;
      _openDetail(inspection.inspectionId);
    } catch (e) {
      _showSnack('Unable to start inspection: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _openDetail(String inspectionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<InspectionProvider>(),
          child: InspectionDetailScreen(inspectionId: inspectionId),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withFraction(0.72),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.fact_check_outlined, size: 58, color: Colors.white70),
          SizedBox(height: 12),
          Text(
            'No inspections yet. Start one to track results.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _InspectionTile extends StatelessWidget {
  const _InspectionTile({required this.inspection, required this.onTap});

  final Inspection inspection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d, yyyy - h:mm a');
    final subtitle = StringBuffer()
      ..write('Started ${formatter.format(inspection.startedAt)}');
    if (inspection.completedAt != null) {
      subtitle.write(' | Completed ${formatter.format(inspection.completedAt!)}');
    }
    final summaryText = _summaryLabel(inspection.summary);

    return _GlassCard(
      child: ListTile(
        onTap: onTap,
        title: Text(inspection.uniformType, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle.toString()),
            if (summaryText != null) ...[
              const SizedBox(height: 4),
              Text(summaryText, style: const TextStyle(color: Colors.white70)),
            ],
          ],
        ),
        trailing: Chip(
          label: Text(inspection.status.replaceAll('_', ' ').toUpperCase()),
          backgroundColor: inspection.status == InspectionStatus.completed
              ? Colors.greenAccent.withFraction(0.2)
              : Colors.blueAccent.withFraction(0.2),
          labelStyle: TextStyle(
            color: inspection.status == InspectionStatus.completed ? Colors.greenAccent : Colors.blueAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String? _summaryLabel(String? summary) {
    if (summary == null) return null;
    try {
      final counts = jsonDecode(summary) as Map<String, dynamic>;
      final pass = counts[InspectionResult.pass] ?? 0;
      final fail = counts[InspectionResult.fail] ?? 0;
      final na = counts[InspectionResult.na] ?? 0;
      return 'Pass $pass | Fail $fail | N/A $na';
    } catch (_) {
      return null;
    }
  }
}

class _ChecklistPicker extends StatelessWidget {
  const _ChecklistPicker({required this.definitions});

  final List<ChecklistDefinition> definitions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Select checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: min(280, 56.0 * definitions.length),
              child: ListView.builder(
                itemCount: definitions.length,
                itemBuilder: (context, index) {
                  final def = definitions[index];
                  return ListTile(
                    title: Text(def.name),
                    subtitle: Text('${def.items.length} items'),
                    onTap: () => Navigator.pop(context, def),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class InspectionDetailScreen extends StatefulWidget {
  const InspectionDetailScreen({super.key, required this.inspectionId});

  final String inspectionId;

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _completing = false;

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inspectionBox = HiveBoxes.inspectionsBox();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Inspection Detail'),
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
          ValueListenableBuilder<Box<Inspection>>(
            valueListenable: inspectionBox.listenable(keys: [widget.inspectionId]),
            builder: (context, box, _) {
              final inspection = box.get(widget.inspectionId);
              if (inspection == null) {
                return const Center(child: Text('Inspection not found'));
              }
              final formatter = DateFormat('MMM d, yyyy - h:mm a');
              final isCompleted = inspection.status == InspectionStatus.completed;
              final summaryLabel = _summaryLabel(inspection.summary);

              return SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inspection.uniformType, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('Started ${formatter.format(inspection.startedAt)}'),
                            if (inspection.completedAt != null)
                              Text('Completed ${formatter.format(inspection.completedAt!)}'),
                            if (summaryLabel != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(summaryLabel, style: const TextStyle(color: Colors.white70)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<Box<InspectionItem>>(
                        valueListenable: HiveBoxes.inspectionItemsBox().listenable(),
                        builder: (context, itemBox, _) {
                          final items = itemBox.values
                              .where((item) => item.inspectionId == widget.inspectionId)
                              .toList()
                            ..sort((a, b) => a.label.compareTo(b.label));
                          if (items.isEmpty) {
                            return const Center(child: Text('No checklist items found'));
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final controller = _commentControllers.putIfAbsent(
                                item.compositeId,
                                () => TextEditingController(text: item.comment ?? ''),
                              );
                              final focusNode = _focusNodes.putIfAbsent(
                                item.compositeId,
                                () => FocusNode(),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _ChecklistItemCard(
                                  item: item,
                                  readOnly: isCompleted,
                                  commentController: controller,
                                  focusNode: focusNode,
                                  onResultChanged: (result) => _setResult(item, result),
                                  onCommentChanged: (comment) => _setComment(item, comment),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          if (isCompleted)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await context.read<InspectionProvider>().reopenInspection(widget.inspectionId);
                                  _showSnack('Inspection reopened');
                                },
                                child: const Text('Reopen'),
                              ),
                            )
                          else
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _completing ? null : () => _completeInspection(inspection),
                                icon: _completing
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(_completing ? 'Completing...' : 'Complete Inspection'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B3A66).withFraction(0.85),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _setResult(InspectionItem item, String result) async {
    await context.read<InspectionProvider>().recordResult(item, result);
    if (result == InspectionResult.fail) {
      final controller = _commentControllers[item.compositeId];
      if (controller != null && controller.text.trim().isEmpty) {
        _focusNodes[item.compositeId]?.requestFocus();
      }
    }
  }

  Future<void> _setComment(InspectionItem item, String comment) async {
    if (context.mounted) {
      await context.read<InspectionProvider>().saveComment(item, comment.trim());
    }
  }

  Future<void> _completeInspection(Inspection inspection) async {
    setState(() => _completing = true);
    try {
      await context.read<InspectionProvider>().completeInspection(inspection.inspectionId);
      _showSnack('Inspection completed');
    } on FormatException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Could not complete inspection: $e');
    } finally {
      if (mounted) {
        setState(() => _completing = false);
      }
    }
  }

  String? _summaryLabel(String? summary) {
    if (summary == null) return null;
    try {
      final counts = jsonDecode(summary) as Map<String, dynamic>;
      final pass = counts[InspectionResult.pass] ?? 0;
      final fail = counts[InspectionResult.fail] ?? 0;
      final na = counts[InspectionResult.na] ?? 0;
      return 'Pass $pass | Fail $fail | N/A $na';
    } catch (_) {
      return null;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withFraction(0.72),
      ),
    );
  }
}

class _ChecklistItemCard extends StatelessWidget {
  const _ChecklistItemCard({
    required this.item,
    required this.readOnly,
    required this.commentController,
    required this.focusNode,
    required this.onResultChanged,
    required this.onCommentChanged,
  });

  final InspectionItem item;
  final bool readOnly;
  final TextEditingController commentController;
  final FocusNode focusNode;
  final ValueChanged<String> onResultChanged;
  final ValueChanged<String> onCommentChanged;

  @override
  Widget build(BuildContext context) {
    final segments = <ButtonSegment<String>>[
      const ButtonSegment(value: InspectionResult.pass, label: Text('Pass'), icon: Icon(Icons.check_circle_outline)),
      const ButtonSegment(value: InspectionResult.fail, label: Text('Fail'), icon: Icon(Icons.cancel_outlined)),
      const ButtonSegment(value: InspectionResult.na, label: Text('N/A'), icon: Icon(Icons.remove_circle_outline)),
    ];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: segments,
            selected: <String>{item.result},
            onSelectionChanged: readOnly ? null : (values) => onResultChanged(values.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: commentController,
            focusNode: focusNode,
            enabled: !readOnly,
            minLines: 1,
            maxLines: 4,
            onChanged: onCommentChanged,
            decoration: InputDecoration(
              labelText: 'Comment${item.result == InspectionResult.fail ? ' (required for fail)' : ''}',
              filled: true,
              fillColor: Colors.white.withFraction(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withFraction(0.18)),
              ),
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withFraction(0.08),
                Colors.white.withFraction(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withFraction(0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withFraction(0.35),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

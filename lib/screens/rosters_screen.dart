import 'dart:math';
import 'dart:ui';

import 'package:dress_right/models/member.dart';
import 'package:dress_right/providers/member_provider.dart';
import 'package:dress_right/utils/roster_models.dart';
import 'package:dress_right/utils/roster_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dress_right/utils/color_utils.dart';
import 'package:provider/provider.dart';

class RostersScreen extends StatefulWidget {
  const RostersScreen({super.key});

  @override
  State<RostersScreen> createState() => _RostersScreenState();
}

class _RostersScreenState extends State<RostersScreen> {
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final memberProvider = context.watch<MemberProvider>();
    final members = memberProvider.members;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Rosters'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import roster',
            onPressed: _isImporting ? null : _handleImport,
          ),
        ],
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
                  Color(0xCC040A14),
                  Color(0xCC10243C),
                  Color(0xCC040A14),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _FilterBar(
                    workcenters: memberProvider.availableWorkcenters,
                    selectedWorkcenter: memberProvider.workcenterFilter,
                    status: memberProvider.statusFilter,
                    onWorkcenterChanged: memberProvider.setWorkcenterFilter,
                    onStatusChanged: memberProvider.setStatusFilter,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: members.isEmpty
                        ? _EmptyState(isImporting: _isImporting)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              final member = members[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _MemberTile(
                                  member: member,
                                  onEditWorkcenter: () => _promptWorkcenterEdit(member),
                                  onToggleDeparted: () => _toggleDeparted(member),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isImporting ? null : _handleImport,
        icon: _isImporting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.upload_file),
        label: Text(_isImporting ? 'Importing...' : 'Import Roster'),
      ),
    );
  }

  Future<void> _handleImport() async {
    try {
      setState(() => _isImporting = true);
      final files = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['csv', 'xlsx', 'txt', 'docx'],
      );
      if (files == null || files.files.isEmpty) {
        return;
      }
      final path = files.files.first.path;
      if (path == null) {
        _showSnack('Unable to read selected file');
        return;
      }

      final result = await RosterParser.parse(path);
      final overrides = result.isConfident ? <RosterField, String>{} : await _promptForMapping(result);
      if (!result.isConfident && (overrides == null || overrides.isEmpty)) {
        _showSnack('Import canceled');
        return;
      }

      final records = result.toRecords(overrides: overrides);
      final confirmed = await _showPreview(records.take(20).toList(), _confidence(result));
      if (!confirmed) {
        return;
      }

      if (!mounted) {
        return;
      }
      await context.read<MemberProvider>().importRoster(records);
      _showSnack('Roster imported: ${records.length} members updated');
    } on FormatException catch (e) {
      _showSnack('Import failed: ${e.message}');
    } catch (e) {
      _showSnack('Import error: $e');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<Map<RosterField, String>?> _promptForMapping(RosterParseResult result) {
    return showModalBottomSheet<Map<RosterField, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final controller = _MappingController(result);
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _MappingSheet(controller: controller),
        );
      },
    );
  }

  Future<bool> _showPreview(List<RosterRecord> preview, double confidence) async {
    return showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Import'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Confidence: ${(confidence * 100).toStringAsFixed(0)}%'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: min(320, 24.0 * preview.length + 24),
                      child: ListView.builder(
                        itemCount: preview.length,
                        itemBuilder: (context, index) {
                          final item = preview[index];
                          return ListTile(
                            dense: true,
                            title: Text('${item.rank} | ${item.name}'),
                            subtitle: Text(item.workcenter),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Import'),
                ),
              ],
            );
          },
        ).then((value) => value ?? false);
  }

  double _confidence(RosterParseResult result) {
    if (result.matches.isEmpty) {
      return 0;
    }
    return result.matches.values.map((match) => match.confidence).reduce(min);
  }

  Future<void> _promptWorkcenterEdit(Member member) async {
    final controller = TextEditingController(text: member.workcenter);
    final provider = context.read<MemberProvider>();
    final options = provider.availableWorkcenters;

    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _WorkcenterSheet(controller: controller, options: options),
        );
      },
    );

    if (selection == null) {
      return;
    }

    final trimmed = selection.trim();
    if (trimmed.isEmpty || trimmed == member.workcenter) {
      return;
    }

    await provider.changeWorkcenter(member, trimmed);
    _showSnack('Workcenter updated');
  }

  Future<void> _toggleDeparted(Member member) async {
    final isDeparted = member.status == MemberStatus.departed;
    if (isDeparted) {
      await context.read<MemberProvider>().changeWorkcenter(member, member.workcenter);
      _showSnack('Member marked active');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mark Departed'),
          content: Text('Mark ${member.name} as departed and close current assignment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    if (!mounted) {
      return;
    }
    await context.read<MemberProvider>().markDeparted(member);
    _showSnack('${member.name} marked departed');
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withFraction(0.72),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.workcenters,
    required this.selectedWorkcenter,
    required this.status,
    required this.onWorkcenterChanged,
    required this.onStatusChanged,
  });

  final List<String> workcenters;
  final String? selectedWorkcenter;
  final String status;
  final ValueChanged<String?> onWorkcenterChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedWorkcenter,
                  decoration: _dropdownDecoration('Workcenter'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All workcenters')),
                    ...workcenters.map(
                      (wc) => DropdownMenuItem<String?>(value: wc, child: Text(wc)),
                    ),
                  ],
                  onChanged: onWorkcenterChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: _dropdownDecoration('Status'),
                  items: const [
                    DropdownMenuItem<String>(value: 'all', child: Text('All status')),
                    DropdownMenuItem<String>(value: 'active', child: Text('Active')),
                    DropdownMenuItem<String>(value: 'departed', child: Text('Departed')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onStatusChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withFraction(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withFraction(0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withFraction(0.45)),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.onEditWorkcenter,
    required this.onToggleDeparted,
  });

  final Member member;
  final VoidCallback onEditWorkcenter;
  final VoidCallback onToggleDeparted;

  @override
  Widget build(BuildContext context) {
    final statusColor = member.status == MemberStatus.active ? Colors.greenAccent : Colors.orangeAccent;
    final updatedLabel = DateFormat('MMM d, yyyy - h:mm a').format(member.updatedAt.toLocal());

    return _GlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text('${member.rank} ${member.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Workcenter: ${member.workcenter}'),
            const SizedBox(height: 4),
            Text('Updated: $updatedLabel'),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(member.status.toUpperCase()),
              backgroundColor: statusColor.withFraction(0.2),
              labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEditWorkcenter();
                    break;
                  case 'departed':
                    onToggleDeparted();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(value: 'edit', child: Text('Edit workcenter')),
                PopupMenuItem<String>(
                  value: 'departed',
                  child: Text(member.status == MemberStatus.active ? 'Mark departed' : 'Mark active'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isImporting});

  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isImporting ? Icons.hourglass_bottom : Icons.people_outline, size: 58, color: Colors.white70),
          const SizedBox(height: 12),
          Text(
            isImporting ? 'Parsing roster...' : 'No members yet. Import a roster to get started.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
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

class _MappingController {
  _MappingController(this.result) {
    final matches = result.matches;
    rankColumn = matches[RosterField.rank]?.column ?? result.pickSuggestion(RosterField.rank);
    nameColumn = matches[RosterField.name]?.column ?? result.pickSuggestion(RosterField.name);
    workcenterColumn = matches[RosterField.workcenter]?.column ?? result.pickSuggestion(RosterField.workcenter);
  }

  final RosterParseResult result;
  String? rankColumn;
  String? nameColumn;
  String? workcenterColumn;

  Map<RosterField, String> toMap() {
    return {
      if (rankColumn != null) RosterField.rank: rankColumn!,
      if (nameColumn != null) RosterField.name: nameColumn!,
      if (workcenterColumn != null) RosterField.workcenter: workcenterColumn!,
    };
  }
}

class _MappingSheet extends StatefulWidget {
  const _MappingSheet({required this.controller});

  final _MappingController controller;

  @override
  State<_MappingSheet> createState() => _MappingSheetState();
}

class _MappingSheetState extends State<_MappingSheet> {
  late String? rank = widget.controller.rankColumn;
  late String? name = widget.controller.nameColumn;
  late String? workcenter = widget.controller.workcenterColumn;

  @override
  Widget build(BuildContext context) {
    final headers = widget.controller.result.headers;
    final preview = widget.controller.result.previewRows(limit: 5);

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
            const SizedBox(height: 16),
            const Text('Map columns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: rank,
              items: headers.map((h) => DropdownMenuItem<String?>(value: h, child: Text(h))).toList(),
              onChanged: (value) => setState(() => rank = value),
              decoration: _fieldDecoration('Rank column'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: name,
              items: headers.map((h) => DropdownMenuItem<String?>(value: h, child: Text(h))).toList(),
              onChanged: (value) => setState(() => name = value),
              decoration: _fieldDecoration('Name column'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: workcenter,
              items: headers.map((h) => DropdownMenuItem<String?>(value: h, child: Text(h))).toList(),
              onChanged: (value) => setState(() => workcenter = value),
              decoration: _fieldDecoration('Workcenter column'),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Preview', style: Theme.of(context).textTheme.titleSmall),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: preview.length,
                itemBuilder: (context, index) {
                  final row = preview[index];
                  return ListTile(
                    dense: true,
                    title: Text(row[name ?? ''] ?? ''),
                    subtitle: Text('${row[rank ?? ''] ?? ''} | ${row[workcenter ?? ''] ?? ''}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: rank != null && name != null && workcenter != null
                        ? () {
                            widget.controller
                              ..rankColumn = rank
                              ..nameColumn = name
                              ..workcenterColumn = workcenter;
                            Navigator.pop(context, widget.controller.toMap());
                          }
                        : null,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withFraction(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withFraction(0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withFraction(0.45)),
      ),
    );
  }
}

class _WorkcenterSheet extends StatelessWidget {
  const _WorkcenterSheet({required this.controller, required this.options});

  final TextEditingController controller;
  final List<String> options;

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
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Workcenter',
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: min(220, 40.0 * options.length),
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return ListTile(
                    title: Text(option),
                    onTap: () => Navigator.pop(context, option),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text.trim()),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ChecklistDefinition {
  ChecklistDefinition({required this.id, required this.name, required this.items});

  final String id;
  final String name;
  final List<ChecklistItemDefinition> items;
}

class ChecklistItemDefinition {
  ChecklistItemDefinition({required this.id, required this.fieldKey, required this.label});

  final String id;
  final String fieldKey;
  final String label;
}

class ChecklistLoader {
  ChecklistLoader._();

  static List<ChecklistDefinition>? _cache;

  static Future<List<ChecklistDefinition>> loadAll() async {
    if (_cache != null) {
      return _cache!;
    }

    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final checklistPaths = manifest.keys
        .where((key) => key.startsWith('assets/checklists/') && key.endsWith('.json'))
        .toList()
      ..sort();

    final definitions = <ChecklistDefinition>[];
    for (final path in checklistPaths) {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final items = (json['items'] as List<dynamic>).map((item) {
        final map = item as Map<String, dynamic>;
        return ChecklistItemDefinition(
          id: map['id'] as String,
          fieldKey: map['key'] as String,
          label: map['label'] as String,
        );
      }).toList();
      definitions.add(
        ChecklistDefinition(
          id: json['id'] as String,
          name: json['name'] as String,
          items: items,
        ),
      );
    }

    _cache = definitions;
    return definitions;
  }

  static Future<ChecklistDefinition?> findById(String id) async {
    final all = await loadAll();
    for (final definition in all) {
      if (definition.id == id) {
        return definition;
      }
    }
    return all.isNotEmpty ? all.first : null;
  }
}

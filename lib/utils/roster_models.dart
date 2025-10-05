import 'dart:math';

enum RosterField { rank, name, workcenter }

extension RosterFieldKey on RosterField {
  String get key {
    switch (this) {
      case RosterField.rank:
        return 'rank';
      case RosterField.name:
        return 'name';
      case RosterField.workcenter:
        return 'workcenter';
    }
  }
}

class RosterColumnMatch {
  RosterColumnMatch({this.column, this.confidence = 0, Map<String, double>? candidates})
      : candidates = candidates ?? <String, double>{};

  final String? column;
  final double confidence;
  final Map<String, double> candidates;
}

class RosterParseResult {
  RosterParseResult({
    required this.headers,
    required this.rows,
    required this.matches,
  });

  final List<String> headers;
  final List<Map<String, String>> rows;
  final Map<RosterField, RosterColumnMatch> matches;
  final _random = Random();

  bool get isConfident => matches.values.every((match) => (match.column ?? '').isNotEmpty && match.confidence >= 0.7);

  List<RosterRecord> toRecords({Map<RosterField, String>? overrides}) {
    final resolved = <RosterField, String>{};
    for (final entry in matches.entries) {
      final override = overrides?[entry.key];
      if (override != null) {
        resolved[entry.key] = override;
      } else if (entry.value.column != null) {
        resolved[entry.key] = entry.value.column!;
      }
    }

    return rows.map((row) {
      final rank = row[resolved[RosterField.rank] ?? ''] ?? '';
      final name = row[resolved[RosterField.name] ?? ''] ?? '';
      final workcenter = row[resolved[RosterField.workcenter] ?? ''] ?? '';
      return RosterRecord(
        rank: rank.trim(),
        name: normalizeName(name),
        workcenter: workcenter.trim(),
      );
    }).toList();
  }

  List<Map<String, String>> previewRows({int limit = 20}) {
    return rows.take(limit).toList();
  }

  String pickSuggestion(RosterField field) {
    final match = matches[field];
    if (match == null) return '';
    if (match.column != null) return match.column!;
    if (match.candidates.isEmpty) return '';
    final ordered = match.candidates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ordered.take(3).toList();
    return top[_random.nextInt(top.length)].key;
  }
}

class RosterRecord {
  RosterRecord({required this.rank, required this.name, required this.workcenter});

  final String rank;
  final String name;
  final String workcenter;
}

String normalizeName(String input) {
  final cleaned = input.trim();
  if (cleaned.isEmpty) {
    return '';
  }

  if (cleaned.contains(',')) {
    final parts = cleaned.split(',');
    final last = capitalize(parts.first.trim());
    final remainder = parts.skip(1).join(',').trim();
    if (remainder.isEmpty) {
      return last;
    }
    return '$last, ${capitalizeWords(remainder)}';
  }

  final segments = cleaned.split(RegExp(r'\s+')).where((segment) => segment.isNotEmpty).toList();
  if (segments.length == 1) {
    return capitalize(segments.first);
  }

  final last = segments.last;
  final firstAndMiddle = segments.sublist(0, segments.length - 1).join(' ');
  return '${capitalize(last)}, ${capitalizeWords(firstAndMiddle)}';
}

String capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

String capitalizeWords(String value) {
  return value
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(capitalize)
      .join(' ')
      .trim();
}

String rosterNameKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
}

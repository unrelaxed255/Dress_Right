import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:excel/excel.dart';
import 'package:dress_right/utils/roster_models.dart';
import 'package:path/path.dart' as p;

class RosterParser {
  static Future<RosterParseResult> parse(String path) async {
    final extension = p.extension(path).toLowerCase();
    final rows = await _readRows(path, extension);
    if (rows.isEmpty) {
      throw const FormatException('File contains no rows');
    }

    final headers = _prepareHeaders(rows.first);
    final mappedRows = <Map<String, String>>[];
    for (final row in rows.skip(1)) {
      final map = <String, String>{};
      for (var i = 0; i < headers.length; i++) {
        final value = i < row.length ? row[i].toString() : '';
        map[headers[i]] = value.trim();
      }
      mappedRows.add(map);
    }

    final matches = _scoreColumns(headers, mappedRows);
    return RosterParseResult(headers: headers, rows: mappedRows, matches: matches);
  }

  static Future<List<List<dynamic>>> _readRows(String path, String extension) async {
    switch (extension) {
      case '.csv':
        final content = await File(path).openRead().transform(utf8.decoder).join();
        return const CsvToListConverter(eol: '\n').convert(content);
      case '.xlsx':
        final bytes = await File(path).readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        if (excel.tables.isEmpty) {
          return [];
        }
        final firstTable = excel.tables.values.first;
        return firstTable.rows.map((row) => row.map((cell) => cell?.value ?? '').toList()).toList();
      case '.txt':
        final content = await File(path).readAsString();
        return _splitPlainText(content);
      case '.docx':
        final bytes = await File(path).readAsBytes();
        final text = docxToText(bytes);
        return _splitPlainText(text);
      default:
        throw FormatException('Unsupported file type: $extension');
    }
  }

  static List<List<dynamic>> _splitPlainText(String text) {
    final lines = text.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty).toList();
    final rows = <List<dynamic>>[];
    for (final line in lines) {
      if (line.contains(',')) {
        rows.add(line.split(',').map((value) => value.trim()).toList());
      } else if (line.contains('\t')) {
        rows.add(line.split('\t').map((value) => value.trim()).toList());
      } else {
        rows.add(line.split(RegExp(r'\s{2,}')).map((value) => value.trim()).toList());
      }
    }
    return rows;
  }

  static List<String> _prepareHeaders(List<dynamic> rawHeaders) {
    final headers = <String>[];
    for (var i = 0; i < rawHeaders.length; i++) {
      final value = rawHeaders[i]?.toString().trim() ?? '';
      headers.add(value.isEmpty ? 'column_${i + 1}' : value.toLowerCase());
    }
    return headers;
  }

  static Map<RosterField, RosterColumnMatch> _scoreColumns(
    List<String> headers,
    List<Map<String, String>> rows,
  ) {
    final Map<RosterField, Map<String, double>> scores = {
      RosterField.rank: {},
      RosterField.name: {},
      RosterField.workcenter: {},
    };

    for (final header in headers) {
      final values = rows.map((row) => row[header] ?? '').take(60).toList();
      scores[RosterField.rank]![header] = _scoreRank(header, values);
      scores[RosterField.name]![header] = _scoreName(header, values);
      scores[RosterField.workcenter]![header] = _scoreWorkcenter(header, values);
    }

    final result = <RosterField, RosterColumnMatch>{};
    scores.forEach((field, columnScores) {
      final sorted = columnScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final best = sorted.isNotEmpty ? sorted.first : null;
      final candidates = <String, double>{
        for (final entry in sorted.take(5)) entry.key: entry.value,
      };
      final column = (best != null && best.value >= 0.1) ? best.key : null;
      final confidence = best?.value ?? 0;
      result[field] = RosterColumnMatch(
        column: column,
        confidence: confidence,
        candidates: candidates,
      );
    });

    return result;
  }

  static double _scoreRank(String header, List<String> values) {
    final headerScore = _headerMatchScore(header, const [
      'rank',
      'grade',
      'paygrade',
      'pay grade',
      'grade/rank',
    ]);
    final rankRegex = RegExp(r'^(?:ab|amn|a1c|sra|ssgt|tsgt|msgt|smsgt|cmsgt|cmsaf|2lt|1lt|capt|maj|lt col|col|brig gen|maj gen|lt gen|gen|e-\d|o-\d)', caseSensitive: false);
    final matches = values.where((value) => rankRegex.hasMatch(value.trim())).length;
    final valueScore = values.isEmpty ? 0 : (matches / values.length) * 0.45;
    return (headerScore + valueScore).clamp(0, 1).toDouble();
  }

  static double _scoreName(String header, List<String> values) {
    final headerScore = _headerMatchScore(header, const [
      'name',
      'member',
      'full name',
      'last',
      'first',
      'surname',
    ]);
    final matches = values.where((value) {
      final trimmed = value.trim();
      return trimmed.contains(',') || trimmed.split(RegExp(r'\s+')).length >= 2;
    }).length;
    final valueScore = values.isEmpty ? 0 : (matches / values.length) * 0.5;
    return (headerScore + valueScore).clamp(0, 1).toDouble();
  }

  static double _scoreWorkcenter(String header, List<String> values) {
    final headerScore = _headerMatchScore(header, const [
      'workcenter',
      'work center',
      'wc',
      'shop',
      'section',
      'flight',
      'office',
      'duty location',
    ]);
    final matches = values.where((value) {
      final trimmed = value.trim();
      return trimmed.isNotEmpty && !RegExp(r'^.*\d{3,}.*').hasMatch(trimmed);
    }).length;
    final valueScore = values.isEmpty ? 0 : (matches / values.length) * 0.45;
    return (headerScore + valueScore).clamp(0, 1).toDouble();
  }

  static double _headerMatchScore(String header, List<String> synonyms) {
    final lower = header.toLowerCase();
    for (final synonym in synonyms) {
      if (lower.contains(synonym)) {
        return 0.55;
      }
    }
    return 0.0;
  }
}

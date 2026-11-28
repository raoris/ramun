import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../database.dart';
import '../models.dart';
import '../repository.dart';

Future<String> exportBackupToDocuments(AlsefaRepository repo) async {
  final tables = await repo.exportAll();
  final payload = <String, dynamic>{
    'version': alsefaSchemaVersion,
    'exportedAt': nowIso(),
    'tables': tables,
  };
  return Uri.dataFromString(
    jsonEncode(payload),
    mimeType: 'application/json',
    encoding: utf8,
  ).toString();
}

Future<int> restoreBackupFromPicker(AlsefaRepository repo) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    withData: true,
    type: FileType.custom,
    allowedExtensions: <String>['json'],
  );
  if (result == null || result.files.isEmpty) return 0;
  final bytes = result.files.single.bytes;
  if (bytes == null || bytes.isEmpty) {
    throw StateError('Selected backup has no readable data');
  }
  final tables = _parseBackupTables(utf8.decode(bytes));
  final count = _countRows(tables);
  await repo.importAll(tables);
  return count;
}

List<Map<String, dynamic>> _parseBackupTables(String content) {
  final decoded = jsonDecode(content);
  final rawTables = decoded is List
      ? decoded
      : decoded is Map
          ? decoded['tables']
          : null;
  if (rawTables is! List) {
    throw const FormatException('Backup file must contain a tables list');
  }
  final result = <Map<String, dynamic>>[];
  for (final entry in rawTables) {
    if (entry is! Map) {
      throw const FormatException('Invalid backup table entry');
    }
    final table = entry['table']?.toString() ?? '';
    if (table.trim().isEmpty) {
      throw const FormatException('Backup table entry has no table name');
    }
    final rowsValue = entry['rows'];
    if (rowsValue is! List) {
      throw FormatException('Invalid rows for backup table: $table');
    }
    final rows = <Map<String, dynamic>>[];
    for (final raw in rowsValue) {
      if (raw is! Map) {
        throw FormatException('Invalid row in backup table: $table');
      }
      rows.add(Map<String, dynamic>.from(raw));
    }
    result.add(<String, dynamic>{'table': table, 'rows': rows});
  }
  return result;
}

int _countRows(List<Map<String, dynamic>> tables) => tables.fold<int>(
      0,
      (sum, table) => sum + (table['rows'] as List).length,
    );

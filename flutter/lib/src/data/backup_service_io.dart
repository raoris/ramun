import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

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
  final documents = await getApplicationDocumentsDirectory();
  final root = Directory(_joinPath(_joinPath(documents.path, 'alsefa'), 'backups'));
  await root.create(recursive: true);
  final name = 'alsefa-backup-${dateKey()}-${newId().substring(0, 8)}.json';
  final path = _joinPath(root.path, name);
  await File(path).writeAsString(jsonEncode(payload));
  return path;
}

Future<int> restoreBackupFromPicker(AlsefaRepository repo) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    withData: false,
    type: FileType.custom,
    allowedExtensions: <String>['json'],
  );
  if (result == null || result.files.isEmpty) return 0;
  final path = result.files.single.path;
  if (path == null || path.trim().isEmpty) {
    throw StateError('Selected backup has no readable path');
  }
  final content = await File(path).readAsString();
  final tables = _parseBackupTables(content);
  final count = _countRows(tables);
  await repo.importAll(tables);
  return count;
}

String _joinPath(String directory, String child) {
  if (directory.endsWith('/') || directory.endsWith('\\')) {
    return '$directory$child';
  }
  final separator = directory.contains('\\') ? '\\' : '/';
  return '$directory$separator$child';
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

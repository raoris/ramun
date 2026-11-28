import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../repository.dart';

Future<DocumentRecord?> pickDocumentForPatient(
  String patientId,
  AlsefaRepository repo,
) async {
  _requireText(patientId, 'patient id');
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    withData: false,
    type: FileType.any,
  );
  if (result == null || result.files.isEmpty) return null;
  final picked = result.files.single;
  final source = picked.path;
  if (source == null || source.trim().isEmpty) {
    throw StateError('Selected file has no readable path');
  }
  final documents = await getApplicationDocumentsDirectory();
  final root = Directory(_joinPath(_joinPath(documents.path, 'alsefa'), 'documents'));
  await root.create(recursive: true);
  final name = _safeFileName(picked.name.trim().isEmpty ? 'document' : picked.name);
  final target = await _uniquePath(root.path, name);
  final copied = await File(source).copy(target);
  final doc = DocumentRecord(
    patientId: patientId,
    name: name,
    path: copied.path,
    mimeType: _mimeFromName(name),
  );
  await repo.saveDocument(doc);
  return doc;
}

Future<void> openDocument(DocumentRecord doc) async {
  final path = doc.path;
  _requireText(path, 'document path');
  final isDataUri = path.startsWith('data:');
  final uri = isDataUri ? Uri.parse(path) : Uri.file(path);
  final canLaunch = await canLaunchUrl(uri);
  if (canLaunch) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  if (isDataUri) {
    throw StateError('Unable to open document data');
  }
  try {
    if (Platform.isWindows) {
      await Process.start('explorer', <String>[path]);
      return;
    }
    if (Platform.isMacOS) {
      await Process.start('open', <String>[path]);
      return;
    }
    await Process.start('xdg-open', <String>[path]);
  } on ProcessException catch (error) {
    throw StateError('Unable to open document: ${error.message}');
  }
}

void _requireText(String value, String label) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, label, '$label is required');
  }
}

String _joinPath(String directory, String child) {
  if (directory.endsWith('/') || directory.endsWith('\\')) {
    return '$directory$child';
  }
  final separator = directory.contains('\\') ? '\\' : '/';
  return '$directory$separator$child';
}

String _safeFileName(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'[\r\n\t]'), '_')
      .trim();
  return cleaned.isEmpty ? 'document' : cleaned;
}

Future<String> _uniquePath(String directory, String fileName) async {
  var candidate = _joinPath(directory, fileName);
  var counter = 1;
  while (await File(candidate).exists()) {
    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    final extension = dot > 0 ? fileName.substring(dot) : '';
    candidate = _joinPath(directory, '${base}_$counter$extension');
    counter++;
  }
  return candidate;
}

String _mimeFromName(String name) {
  final dot = name.lastIndexOf('.');
  final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  switch (extension) {
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'txt':
      return 'text/plain';
    case 'csv':
      return 'text/csv';
    case 'json':
      return 'application/json';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    default:
      return 'application/octet-stream';
  }
}

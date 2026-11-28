import 'dart:convert';

import 'package:file_picker/file_picker.dart';
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
    withData: true,
    type: FileType.any,
  );
  if (result == null || result.files.isEmpty) return null;
  final picked = result.files.single;
  final bytes = picked.bytes;
  if (bytes == null || bytes.isEmpty) {
    throw StateError('Selected file has no readable data');
  }
  final name = picked.name.trim().isEmpty ? 'document' : picked.name;
  final mime = _mimeFromName(name);
  final path = 'data:$mime;base64,${base64Encode(bytes)}';
  final doc = DocumentRecord(
    patientId: patientId,
    name: name,
    path: path,
    mimeType: mime,
  );
  await repo.saveDocument(doc);
  return doc;
}

Future<void> openDocument(DocumentRecord doc) async {
  final path = doc.path;
  _requireText(path, 'document path');
  final uri = Uri.tryParse(path);
  if (uri == null ||
      !(uri.scheme == 'data' ||
          uri.scheme == 'http' ||
          uri.scheme == 'https')) {
    throw StateError('Unsupported document path on web');
  }
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
      return;
    }
  } catch (error) {
    throw StateError('Unable to open document: $error');
  }
  throw StateError('Unable to open document');
}

void _requireText(String value, String label) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, label, '$label is required');
  }
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

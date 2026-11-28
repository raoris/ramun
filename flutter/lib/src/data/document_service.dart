import 'models.dart';
import 'repository.dart';
import 'document_service_web.dart'
    if (dart.library.io) 'document_service_io.dart'
    if (dart.library.html) 'document_service_web.dart';

export 'models.dart';
export 'repository.dart';

class DocumentService {
  static Future<DocumentRecord?> pickForPatient(
    String patientId,
    AlsefaRepository repo,
  ) async =>
      pickDocumentForPatient(patientId, repo);

  static Future<void> open(DocumentRecord doc) async => openDocument(doc);
}

import 'models.dart';
import 'repository.dart';
import 'backup_service_web.dart'
    if (dart.library.io) 'backup_service_io.dart'
    if (dart.library.html) 'backup_service_web.dart';

export 'models.dart';
export 'repository.dart';

class BackupService {
  static Future<String> exportToDocuments(AlsefaRepository repo) async =>
      exportBackupToDocuments(repo);

  static Future<int> restoreFromPicker(AlsefaRepository repo) async =>
      restoreBackupFromPicker(repo);
}

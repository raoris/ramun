import 'package:sqflite/sqflite.dart';

import 'database_config.dart';

const int alsefaSchemaVersion = 1;
const String _databaseFileName = 'alsefa.db';

const List<String> alsefaTables = <String>[
  'patients',
  'documents',
  'visits',
  'treatments',
  'sessions',
  'ledger',
  'sync_queue',
  'app_users',
  'settings',
];

Future<void> _createSchemaV1(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS patients (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      age INTEGER NOT NULL,
      gender TEXT NOT NULL,
      bp TEXT NOT NULL,
      address TEXT NOT NULL,
      phone TEXT NOT NULL,
      weightKg REAL NOT NULL,
      diagnosis TEXT NOT NULL,
      regularFee REAL NOT NULL,
      firstFee REAL NOT NULL,
      initialPayment REAL NOT NULL,
      preferredTime TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      syncStatus TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS documents (
      id TEXT PRIMARY KEY,
      patientId TEXT NOT NULL,
      name TEXT NOT NULL,
      path TEXT NOT NULL,
      mimeType TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      syncStatus TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS visits (
      id TEXT PRIMARY KEY,
      patientId TEXT NOT NULL,
      arrivedAt TEXT NOT NULL,
      sessionAt TEXT NOT NULL,
      status TEXT NOT NULL,
      isRushHour INTEGER NOT NULL,
      notes TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      syncStatus TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS treatments (
      id TEXT PRIMARY KEY,
      patientId TEXT NOT NULL,
      assessment TEXT NOT NULL,
      plan TEXT NOT NULL,
      checklist TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      syncStatus TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS sessions (
      id TEXT PRIMARY KEY,
      patientId TEXT NOT NULL,
      treatmentId TEXT NOT NULL,
      dateKey TEXT NOT NULL,
      completed INTEGER NOT NULL,
      notes TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      syncStatus TEXT NOT NULL,
      UNIQUE(patientId, dateKey)
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS ledger (
      id TEXT PRIMARY KEY,
      patientId TEXT,
      type TEXT NOT NULL,
      category TEXT NOT NULL,
      description TEXT NOT NULL,
      amount REAL NOT NULL,
      occurredAt TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      syncStatus TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY,
      entity TEXT NOT NULL,
      entityId TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      synced INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS app_users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      role TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      syncStatus TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS settings (
      id TEXT PRIMARY KEY,
      "key" TEXT NOT NULL UNIQUE,
      "value" TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      syncStatus TEXT NOT NULL
    )
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_patients_name ON patients(name)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_patients_gender ON patients(gender)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_patients_diagnosis ON patients(diagnosis)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_patient ON documents(patientId)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_visits_patient ON visits(patientId)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_treatments_patient ON treatments(patientId)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_patient ON sessions(patientId)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_ledger_patient ON ledger(patientId)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_ledger_type ON ledger(type)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_synced ON sync_queue(synced)');
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  for (var version = oldVersion + 1; version <= newVersion; version++) {
    switch (version) {
      case 1:
        await _createSchemaV1(db);
        break;
      default:
        await _createSchemaV1(db);
        break;
    }
  }
}

Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
  throw StateError(
    'Cannot downgrade ALSEFA database from $oldVersion to $newVersion',
  );
}

String _joinPath(String directory, String child) {
  if (directory.endsWith('/') || directory.endsWith('\\')) {
    return '$directory$child';
  }
  final separator = directory.contains('\\') ? '\\' : '/';
  return '$directory$separator$child';
}

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;
  Future<Database>? _opening;

  Future<Database> open() async {
    final current = _database;
    if (current != null && current.isOpen) return current;
    final opening = _opening;
    if (opening != null) return opening;
    final future = _open();
    _opening = future;
    try {
      final database = await future;
      _database = database;
      return database;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _open() async {
    try {
      await configureDatabaseFactory();
      final directory = await getDatabasesPath();
      final path = _joinPath(directory, _databaseFileName);
      return await openDatabase(
        path,
        version: alsefaSchemaVersion,
        onCreate: (db, version) => _createSchemaV1(db),
        onUpgrade: _onUpgrade,
        onDowngrade: _onDowngrade,
      );
    } catch (error) {
      throw StateError('Unable to open ALSEFA local database: $error');
    }
  }

  Future<void> close() async {
    final database = _database;
    if (database != null && database.isOpen) {
      await database.close();
    }
    _database = null;
  }
}

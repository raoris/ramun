import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'database.dart';
import 'models.dart';

export 'models.dart';

class AlsefaDataException implements Exception {
  AlsefaDataException(this.message);

  final String message;

  @override
  String toString() => 'AlsefaDataException: $message';
}

abstract class AlsefaRepository {
  Future<List<Patient>> patients({
    String query = '',
    String? gender,
    String? diagnosis,
  });

  Future<Patient?> patient(String id);

  Future<void> savePatient(Patient p);

  Future<void> deletePatient(String id);

  Future<List<DocumentRecord>> documents(String patientId);

  Future<void> saveDocument(DocumentRecord d);

  Future<void> deleteDocument(String id);

  Future<List<Visit>> visits({String? patientId});

  Future<void> saveVisit(Visit v);

  Future<List<Treatment>> treatments(String patientId);

  Future<void> saveTreatment(Treatment t);

  Future<List<SessionRecord>> sessions(String patientId);

  Future<bool> hasSession(String patientId, String dateKey);

  Future<void> saveSession(SessionRecord s);

  Future<List<LedgerEntry>> ledger({String? patientId, String? type});

  Future<void> saveLedger(LedgerEntry e);

  Future<void> deleteLedger(String id);

  Future<int> pendingSyncCount();

  Future<List<SyncQueueItem>> pendingSync();

  Future<void> markSynced(String id);

  Future<Map<String, dynamic>> dashboardSummary();

  Future<List<Map<String, dynamic>>> exportAll();

  Future<void> importAll(List<Map<String, dynamic>> data);

  Future<void> clearAll();

  Future<void> migrateLegacyPatients(List<Map<String, dynamic>> legacy);
}

class SqliteRepository implements AlsefaRepository {
  SqliteRepository(this._db);

  final Database _db;

  static Future<SqliteRepository> create() async {
    final database = await AppDatabase.instance.open();
    return SqliteRepository(database);
  }

  @override
  Future<List<Patient>> patients({
    String query = '',
    String? gender,
    String? diagnosis,
  }) =>
      _dbAction('load patients', () async {
        final clauses = <String>[];
        final args = <Object?>[];
        const escape = "ESCAPE '\\'";
        final search = query.trim();
        if (search.isNotEmpty) {
          final pattern = '%${_escapeLike(search)}%';
          clauses.add(
            '(name LIKE ? $escape OR phone LIKE ? $escape '
            'OR address LIKE ? $escape OR diagnosis LIKE ? $escape)',
          );
          args.addAll(List<Object?>.filled(4, pattern));
        }
        if (gender != null && gender.trim().isNotEmpty) {
          clauses.add('gender = ?');
          args.add(gender);
        }
        if (diagnosis != null && diagnosis.trim().isNotEmpty) {
          clauses.add('diagnosis = ?');
          args.add(diagnosis);
        }
        final where = clauses.isEmpty ? null : clauses.join(' AND ');
        final rows = await _db.query(
          'patients',
          where: where,
          whereArgs: where == null ? null : args,
          orderBy: 'createdAt DESC',
        );
        return rows
            .map((row) => Patient.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      });

  @override
  Future<Patient?> patient(String id) => _dbAction('load patient', () async {
        _requireText(id, 'patient id');
        final rows = await _db.query(
          'patients',
          where: 'id = ?',
          whereArgs: <Object?>[id],
          limit: 1,
        );
        if (rows.isEmpty) return null;
        return Patient.fromJson(Map<String, dynamic>.from(rows.first));
      });

  @override
  Future<void> savePatient(Patient p) => _dbAction('save patient', () async {
        _validatePatient(p);
        final record = p.copyWith(
          updatedAt: p.updatedAt.trim().isEmpty ? nowIso() : p.updatedAt,
          syncStatus: 'pending',
        );
        final payload = jsonEncode(record.toJson());
        await _db.transaction((tx) async {
          await tx.insert(
            'patients',
            record.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _enqueue(tx, 'patients', record.id, 'upsert', payload);
        });
      });

  @override
  Future<void> deletePatient(String id) => _dbAction('delete patient', () async {
        _requireText(id, 'patient id');
        await _db.transaction((tx) async {
          await tx.delete('documents', where: 'patientId = ?', whereArgs: <Object?>[id]);
          await _enqueue(tx, 'documents', id, 'delete', jsonEncode(<String, dynamic>{'patientId': id}));
          await tx.delete('visits', where: 'patientId = ?', whereArgs: <Object?>[id]);
          await _enqueue(tx, 'visits', id, 'delete', jsonEncode(<String, dynamic>{'patientId': id}));
          await tx.delete('treatments', where: 'patientId = ?', whereArgs: <Object?>[id]);
          await _enqueue(tx, 'treatments', id, 'delete', jsonEncode(<String, dynamic>{'patientId': id}));
          await tx.delete('sessions', where: 'patientId = ?', whereArgs: <Object?>[id]);
          await _enqueue(tx, 'sessions', id, 'delete', jsonEncode(<String, dynamic>{'patientId': id}));
          await tx.update(
            'ledger',
            <String, Object?>{
              'patientId': null,
              'updatedAt': nowIso(),
              'syncStatus': 'pending',
            },
            where: 'patientId = ?',
            whereArgs: <Object?>[id],
          );
          await _enqueue(tx, 'ledger', id, 'unlink', jsonEncode(<String, dynamic>{'patientId': id}));
          await tx.delete('patients', where: 'id = ?', whereArgs: <Object?>[id]);
          await _enqueue(tx, 'patients', id, 'delete', jsonEncode(<String, dynamic>{'id': id}));
        });
      });

  @override
  Future<List<DocumentRecord>> documents(String patientId) =>
      _dbAction('load documents', () async {
        _requireText(patientId, 'patient id');
        final rows = await _db.query(
          'documents',
          where: 'patientId = ?',
          whereArgs: <Object?>[patientId],
          orderBy: 'createdAt DESC',
        );
        return rows
            .map((row) => DocumentRecord.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      });

  @override
  Future<void> saveDocument(DocumentRecord d) =>
      _dbAction('save document', () async {
        _validateDocument(d);
        final record = d.copyWith(
          updatedAt: d.updatedAt.trim().isEmpty ? nowIso() : d.updatedAt,
          syncStatus: 'pending',
        );
        final payload = jsonEncode(record.toJson());
        await _db.transaction((tx) async {
          await tx.insert(
            'documents',
            record.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _enqueue(tx, 'documents', record.id, 'upsert', payload);
        });
      });

  @override
  Future<void> deleteDocument(String id) =>
      _dbAction('delete document', () async {
        _requireText(id, 'document id');
        await _db.transaction((tx) async {
          await tx.delete('documents', where: 'id = ?', whereArgs: <Object?>[id]);
          await _enqueue(tx, 'documents', id, 'delete', jsonEncode(<String, dynamic>{'id': id}));
        });
      });

  @override
  Future<List<Visit>> visits({String? patientId}) =>
      _dbAction('load visits', () async {
        final rows = await _db.query(
          'visits',
          where: patientId == null || patientId.trim().isEmpty ? null : 'patientId = ?',
          whereArgs: patientId == null || patientId.trim().isEmpty ? null : <Object?>[patientId],
          orderBy: 'sessionAt DESC, createdAt DESC',
        );
        return rows
            .map((row) => Visit.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      });

  @override
  Future<void> saveVisit(Visit v) => _dbAction('save visit', () async {
        _validateVisit(v);
        final record = v.copyWith(
          updatedAt: v.updatedAt.trim().isEmpty ? nowIso() : v.updatedAt,
          syncStatus: 'pending',
        );
        final payload = jsonEncode(record.toJson());
        await _db.transaction((tx) async {
          await tx.insert(
            'visits',
            _visitMap(record),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _enqueue(tx, 'visits', record.id, 'upsert', payload);
        });
      });

  @override
  Future<List<Treatment>> treatments(String patientId) =>
      _dbAction('load treatments', () async {
        _requireText(patientId, 'patient id');
        final rows = await _db.query(
          'treatments',
          where: 'patientId = ?',
          whereArgs: <Object?>[patientId],
          orderBy: 'updatedAt DESC',
        );
        return rows
            .map((row) => Treatment.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      });

  @override
  Future<void> saveTreatment(Treatment t) =>
      _dbAction('save treatment', () async {
        _validateTreatment(t);
        final record = t.copyWith(
          updatedAt: t.updatedAt.trim().isEmpty ? nowIso() : t.updatedAt,
          syncStatus: 'pending',
        );
        final payload = jsonEncode(record.toJson());
        await _db.transaction((tx) async {
          await tx.insert(
            'treatments',
            _treatmentMap(record),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _enqueue(tx, 'treatments', record.id, 'upsert', payload);
        });
      });

  @override
  Future<List<SessionRecord>> sessions(String patientId) =>
      _dbAction('load sessions', () async {
        _requireText(patientId, 'patient id');
        final rows = await _db.query(
          'sessions',
          where: 'patientId = ?',
          whereArgs: <Object?>[patientId],
          orderBy: 'dateKey DESC',
        );
        return rows
            .map((row) => SessionRecord.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      });

  @override
  Future<bool> hasSession(String patientId, String dateKey) =>
      _dbAction('check session', () async {
        _requireText(patientId, 'patient id');
        _requireText(dateKey, 'date key');
        final rows = await _db.query(
          'sessions',
          columns: <String>['id'],
          where: 'patientId = ? AND dateKey = ?',
          whereArgs: <Object?>[patientId, dateKey],
          limit: 1,
        );
        return rows.isNotEmpty;
      });

  @override
  Future<void> saveSession(SessionRecord s) =>
      _dbAction('save session', () async {
        _validateSession(s);
        final record = s.copyWith(
          updatedAt: s.updatedAt.trim().isEmpty ? nowIso() : s.updatedAt,
          syncStatus: 'pending',
        );
        final payload = jsonEncode(record.toJson());
        await _db.transaction((tx) async {
          await tx.insert(
            'sessions',
            _sessionMap(record),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _enqueue(tx, 'sessions', record.id, 'upsert', payload);
        });
      });

  @override
  Future<List<LedgerEntry>> ledger({String? patientId, String? type}) =>
      _dbAction('load ledger', () async {
        final clauses = <String>[];
        final args = <Object?>[];
        if (patientId != null && patientId.trim().isNotEmpty) {
          clauses.add('patientId = ?');
          args.add(patientId);
        }
        if (type != null && type.trim().isNotEmpty) {
          clauses.add('type = ?');
          args.add(type);
        }
        final where = clauses.isEmpty ? null : clauses.join(' AND ');
        final rows = await _db.query(
          'ledger',
          where: where,
          whereArgs: where == null ? null : args,
          orderBy: 'occurredAt DESC, createdAt DESC',
        );
        return rows
            .map((row) => LedgerEntry.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      });

  @override
  Future<void> saveLedger(LedgerEntry e) =>
      _dbAction('save ledger entry', () async {
        _validateLedger(e);
        final record = e.copyWith(
          updatedAt: e.updatedAt.trim().isEmpty ? nowIso() : e.updatedAt,
          syncStatus: 'pending',
        );
        final payload = jsonEncode(record.toJson());
        await _db.transaction((tx) async {
          await tx.insert(
            'ledger',
            record.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _enqueue(tx, 'ledger', record.id, 'upsert', payload);
        });
      });

  @override
  Future<void> deleteLedger(String id) =>
      _dbAction('delete ledger entry', () async {
        _requireText(id, 'ledger id');
        await _db.transaction((tx) async {
          await tx.delete('ledger', where: 'id = ?', whereArgs: <Object?>[id]);
          await _enqueue(tx, 'ledger', id, 'delete', jsonEncode(<String, dynamic>{'id': id}));
        });
      });

  @override
  Future<int> pendingSyncCount() => _dbAction('count pending sync', () async {
        final rows = await _db.rawQuery(
          'SELECT COUNT(*) AS count FROM sync_queue WHERE synced = 0',
        );
        return (rows.first['count'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<List<SyncQueueItem>> pendingSync() =>
      _dbAction('load pending sync', () async {
        final rows = await _db.query(
          'sync_queue',
          where: 'synced = 0',
          orderBy: 'createdAt ASC',
        );
        return rows
            .map((row) => SyncQueueItem.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      });

  @override
  Future<void> markSynced(String id) => _dbAction('mark synced', () async {
        _requireText(id, 'sync queue id');
        await _db.update(
          'sync_queue',
          <String, Object?>{'synced': 1},
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
      });

  @override
  Future<Map<String, dynamic>> dashboardSummary() =>
      _dbAction('load dashboard', () async {
        final today = dateKey();
        final patientCount = await _count('patients');
        final documentCount = await _count('documents');
        final visitCount = await _count('visits');
        final treatmentCount = await _count('treatments');
        final sessionCount = await _count('sessions');
        final completedSessions = await _count(
          'sessions',
          where: 'completed = 1',
        );
        final ledgerCount = await _count('ledger');
        final income = await _sum('ledger', where: "type = 'income'");
        final expenses = await _sum('ledger', where: "type = 'expense'");
        final todayVisits = await _count(
          'visits',
          where: 'substr(sessionAt, 1, 10) = ?',
          args: <Object?>[today],
        );
        final todaySessions = await _count(
          'sessions',
          where: 'dateKey = ?',
          args: <Object?>[today],
        );
        final pending = await pendingSyncCount();
        return <String, dynamic>{
          'patients': patientCount,
          'totalPatients': patientCount,
          'documents': documentCount,
          'visits': visitCount,
          'treatments': treatmentCount,
          'sessions': sessionCount,
          'completedSessions': completedSessions,
          'ledgerEntries': ledgerCount,
          'income': income,
          'expenses': expenses,
          'balance': income - expenses,
          'todayVisits': todayVisits,
          'todaySessions': todaySessions,
          'pendingSync': pending,
        };
      });

  @override
  Future<List<Map<String, dynamic>>> exportAll() =>
      _dbAction('export data', () async {
        final result = <Map<String, dynamic>>[];
        for (final table in alsefaTables) {
          final rows = await _db.query(table);
          result.add(<String, dynamic>{
            'table': table,
            'rows': rows
                .map((row) => Map<String, dynamic>.from(row))
                .toList(growable: false),
            'exportedAt': nowIso(),
            'version': alsefaSchemaVersion,
          });
        }
        return result;
      });

  @override
  Future<void> importAll(List<Map<String, dynamic>> data) =>
      _dbAction('import data', () async {
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final entry in data) {
          final table = _text(entry['table']);
          if (!alsefaTables.contains(table)) {
            throw FormatException('Unknown table in backup: $table');
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
          grouped.putIfAbsent(table, () => <Map<String, dynamic>>[]).addAll(rows);
        }
        await _db.transaction((tx) async {
          for (final table in alsefaTables.reversed) {
            await tx.delete(table);
          }
          for (final table in alsefaTables) {
            final rows = grouped[table] ?? const <Map<String, dynamic>>[];
            for (final row in rows) {
              await tx.insert(
                table,
                _normalizeRow(table, row),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
          final total = grouped.values.fold<int>(
            0,
            (sum, rows) => sum + rows.length,
          );
          await _enqueue(
            tx,
            'backup',
            'all',
            'import',
            jsonEncode(<String, dynamic>{
              'tables': grouped.keys.toList(growable: false),
              'rows': total,
            }),
          );
        });
      });

  @override
  Future<void> clearAll() => _dbAction('clear data', () async {
        await _db.transaction((tx) async {
          for (final table in alsefaTables) {
            await tx.delete(table);
          }
          await _enqueue(tx, 'backup', 'all', 'clear', '{}');
        });
      });

  @override
  Future<void> migrateLegacyPatients(List<Map<String, dynamic>> legacy) =>
      _dbAction('migrate legacy patients', () async {
        await _db.transaction((tx) async {
          for (final item in legacy) {
            final name = _text(item['name'] ?? item['patientName']);
            if (name.trim().isEmpty) continue;
            final id = _required(item['id'], newId());
            final existing = await tx.query(
              'patients',
              columns: <String>['id'],
              where: 'id = ?',
              whereArgs: <Object?>[id],
              limit: 1,
            );
            if (existing.isNotEmpty) continue;
            final created = _required(
              item['createdAt'] ?? item['recordedAt'],
              nowIso(),
            );
            final map = <String, Object?>{
              'id': id,
              'name': name,
              'age': _int(item['age']),
              'gender': _required(item['gender'] ?? item['sex'], 'unknown'),
              'bp': _text(item['bp'] ?? item['bloodPressure']),
              'address': _text(item['address']),
              'phone': _text(item['phone']),
              'weightKg': _double(item['weightKg'] ?? item['weight']),
              'diagnosis': _text(item['diagnosis']),
              'regularFee': _double(item['regularFee']),
              'firstFee': _double(item['firstFee'], fallback: 300),
              'initialPayment': _double(item['initialPayment']),
              'preferredTime': _text(item['preferredTime']),
              'createdAt': created,
              'updatedAt': _required(item['updatedAt'], created),
              'syncStatus': 'pending',
            };
            await tx.insert(
              'patients',
              map,
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
            await _enqueue(tx, 'patients', id, 'insert', jsonEncode(map));
          }
        });
      });

  Future<T> _dbAction<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } on ArgumentError {
      rethrow;
    } on FormatException {
      rethrow;
    } on AlsefaDataException {
      rethrow;
    } catch (error) {
      throw AlsefaDataException('$action failed: $error');
    }
  }

  Future<void> _enqueue(
    DatabaseExecutor executor,
    String entity,
    String entityId,
    String operation,
    String payload,
  ) async {
    final item = SyncQueueItem(
      entity: entity,
      entityId: entityId,
      operation: operation,
      payload: payload,
    );
    await executor.insert(
      'sync_queue',
      _queueMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> _count(
    String table, {
    String? where,
    List<Object?>? args,
  }) async {
    _assertTable(table);
    final query = 'SELECT COUNT(*) AS count FROM $table'
        '${where == null ? '' : ' WHERE $where'}';
    final rows = await _db.rawQuery(query, args ?? const <Object?>[]);
    return (rows.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<double> _sum(
    String table, {
    String? where,
    List<Object?>? args,
  }) async {
    _assertTable(table);
    final query = 'SELECT COALESCE(SUM(amount), 0) AS total FROM $table'
        '${where == null ? '' : ' WHERE $where'}';
    final rows = await _db.rawQuery(query, args ?? const <Object?>[]);
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }
}

void _assertTable(String table) {
  if (!alsefaTables.contains(table)) {
    throw ArgumentError.value(table, 'table', 'Unsupported table');
  }
}

String _requireText(String value, String label) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, label, '$label is required');
  }
  return value;
}

String _text(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String _required(Object? value, String fallback) {
  final text = _text(value);
  return text.trim().isEmpty ? fallback : text;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

double _double(Object? value, {double fallback = 0}) {
  if (value is num) {
    final result = value.toDouble();
    return result.isFinite ? result : fallback;
  }
  if (value is String) {
    final result = double.tryParse(value.trim());
    if (result != null && result.isFinite) return result;
  }
  return fallback;
}

String _escapeLike(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll('%', '\\%')
    .replaceAll('_', '\\_');

Map<String, Object?> _visitMap(Visit visit) => <String, Object?>{
      ...visit.toJson(),
      'isRushHour': visit.isRushHour ? 1 : 0,
    };

Map<String, Object?> _treatmentMap(Treatment treatment) =>
    <String, Object?>{
      ...treatment.toJson(),
      'checklist': jsonEncode(treatment.checklist),
    };

Map<String, Object?> _sessionMap(SessionRecord session) =>
    <String, Object?>{
      ...session.toJson(),
      'completed': session.completed ? 1 : 0,
    };

Map<String, Object?> _queueMap(SyncQueueItem item) => <String, Object?>{
      'id': item.id,
      'entity': item.entity,
      'entityId': item.entityId,
      'operation': item.operation,
      'payload': item.payload,
      'createdAt': item.createdAt,
      'synced': item.synced ? 1 : 0,
    };

Map<String, Object?> _settingsMap(Map<String, dynamic> row) {
  final created = _required(row['createdAt'], nowIso());
  return <String, Object?>{
    'id': _required(row['id'], newId()),
    'key': _required(row['key'] ?? row['settingKey'], 'setting_${newId()}'),
    'value': _text(row['value']),
    'createdAt': created,
    'updatedAt': _required(row['updatedAt'], created),
    'syncStatus': 'pending',
  };
}

Map<String, Object?> _normalizeRow(
  String table,
  Map<String, dynamic> row,
) {
  switch (table) {
    case 'patients':
      return <String, Object?>{
        ...Patient.fromJson(row).toJson(),
        'syncStatus': 'pending',
      };
    case 'documents':
      return <String, Object?>{
        ...DocumentRecord.fromJson(row).toJson(),
        'syncStatus': 'pending',
      };
    case 'visits':
      return _visitMap(Visit.fromJson(row).copyWith(syncStatus: 'pending'));
    case 'treatments':
      return _treatmentMap(
        Treatment.fromJson(row).copyWith(syncStatus: 'pending'),
      );
    case 'sessions':
      return _sessionMap(
        SessionRecord.fromJson(row).copyWith(syncStatus: 'pending'),
      );
    case 'ledger':
      return <String, Object?>{
        ...LedgerEntry.fromJson(row).toJson(),
        'syncStatus': 'pending',
      };
    case 'sync_queue':
      return _queueMap(SyncQueueItem.fromJson(row));
    case 'app_users':
      return <String, Object?>{
        ...AppUser.fromJson(row).toJson(),
        'syncStatus': 'pending',
      };
    case 'settings':
      return _settingsMap(row);
    default:
      throw FormatException('Unsupported backup table: $table');
  }
}

void _validatePatient(Patient patient) {
  _requireText(patient.id, 'patient id');
  _requireText(patient.name, 'patient name');
  if (patient.age < 1 || patient.age > 120) {
    throw ArgumentError.value(patient.age, 'age', 'Age must be between 1 and 120');
  }
  if (!patient.weightKg.isFinite || patient.weightKg <= 0) {
    throw ArgumentError.value(patient.weightKg, 'weightKg', 'Weight must be positive');
  }
  if (!patient.regularFee.isFinite || patient.regularFee < 0) {
    throw ArgumentError.value(patient.regularFee, 'regularFee', 'Fee cannot be negative');
  }
  if (!patient.firstFee.isFinite || patient.firstFee < 0) {
    throw ArgumentError.value(patient.firstFee, 'firstFee', 'Fee cannot be negative');
  }
  if (!patient.initialPayment.isFinite || patient.initialPayment < 0) {
    throw ArgumentError.value(
      patient.initialPayment,
      'initialPayment',
      'Payment cannot be negative',
    );
  }
}

void _validateDocument(DocumentRecord document) {
  _requireText(document.id, 'document id');
  _requireText(document.patientId, 'patient id');
  _requireText(document.name, 'document name');
  _requireText(document.path, 'document path');
}

void _validateVisit(Visit visit) {
  _requireText(visit.id, 'visit id');
  _requireText(visit.patientId, 'patient id');
}

void _validateTreatment(Treatment treatment) {
  _requireText(treatment.id, 'treatment id');
  _requireText(treatment.patientId, 'patient id');
}

void _validateSession(SessionRecord session) {
  _requireText(session.id, 'session id');
  _requireText(session.patientId, 'patient id');
  _requireText(session.dateKey, 'date key');
}

void _validateLedger(LedgerEntry entry) {
  _requireText(entry.id, 'ledger id');
  _requireText(entry.type, 'ledger type');
  _requireText(entry.category, 'ledger category');
  _requireText(entry.description, 'ledger description');
  _requireText(entry.occurredAt, 'occurredAt');
  if (!entry.amount.isFinite || entry.amount < 0) {
    throw ArgumentError.value(entry.amount, 'amount', 'Amount cannot be negative');
  }
}
